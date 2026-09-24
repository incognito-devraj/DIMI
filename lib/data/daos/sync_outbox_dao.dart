import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/sync_outbox.dart';

part 'sync_outbox_dao.g.dart';

class OutboxState {
  static const pending = 'pending';
  static const processing = 'processing';
  static const retryableError = 'retryable_error';
  static const permanentError = 'permanent_error';
  static const completed = 'completed';
}

class OutboxOperation {
  static const create = 'create';
  static const update = 'update';
  static const delete = 'delete';
}

class OutboxEntity {
  static const account = 'local_accounts';
  static const profile = 'profile_data';
  static const task = 'tasks';
  static const reminder = 'reminders';
  static const note = 'notes';
  static const moneyTransaction = 'money_transactions';
  static const merchantRule = 'merchant_category_rules';
  static const playlist = 'youtube_playlists';
  static const video = 'youtube_videos';
}

class OutboxDependencyRank {
  static const account = 10;
  static const profile = 20;
  static const task = 30;
  static const reminder = 40;
  static const note = 50;
  static const moneyTransaction = 60;
  static const merchantRule = 70;
  static const playlist = 80;
  static const video = 90;
}

@DriftAccessor(tables: [SyncOutbox])
class SyncOutboxDao extends DatabaseAccessor<AppDatabase>
    with _$SyncOutboxDaoMixin {
  SyncOutboxDao(super.db);

  Future<void> enqueue({
    required int localAccountId,
    required String entityType,
    required int localRowId,
    required String operation,
    String? serverId,
    String? authUserId,
    DateTime? baseRemoteUpdatedAt,
    DateTime? localMutationAt,
    required int dependencyRank,
  }) async {
    final now = DateTime.now().toUtc();
    final effectiveLocalMutationAt = (localMutationAt ?? now).toUtc();
    final existing = await (select(syncOutbox)
          ..where((o) =>
              o.localAccountId.equals(localAccountId) &
              o.entityType.equals(entityType) &
              o.localRowId.equals(localRowId)))
        .getSingleOrNull();

    final effectiveOperation = existing?.operation == OutboxOperation.create &&
            operation != OutboxOperation.delete
        ? OutboxOperation.create
        : operation;

    if (existing == null) {
      await into(syncOutbox).insert(SyncOutboxCompanion.insert(
            localAccountId: localAccountId,
            authUserId: Value(authUserId),
            entityType: entityType,
            localRowId: localRowId,
            serverId: Value(serverId),
            operation: effectiveOperation,
            dependencyRank: Value(dependencyRank),
            queuedAt: now,
            nextAttemptAt: Value(now),
            baseRemoteUpdatedAt: Value(baseRemoteUpdatedAt?.toUtc()),
            updatedAt: Value(effectiveLocalMutationAt),
          ));
      return;
    }

    await (update(syncOutbox)..where((o) => o.id.equals(existing.id))).write(
      SyncOutboxCompanion(
        authUserId: Value(authUserId ?? existing.authUserId),
        serverId: Value(serverId ?? existing.serverId),
        operation: Value(effectiveOperation),
        state: const Value(OutboxState.pending),
        dependencyRank: Value(dependencyRank),
        nextAttemptAt: Value(now),
        // The first pending mutation's base is retained across coalescing.
        baseRemoteUpdatedAt: Value(
          existing.operation == OutboxOperation.create
              ? existing.baseRemoteUpdatedAt?.toUtc()
              : (existing.baseRemoteUpdatedAt?.toUtc() ?? baseRemoteUpdatedAt?.toUtc()),
        ),
        updatedAt: Value(effectiveLocalMutationAt),
        lastError: const Value(null),
      ),
    );
  }

  Stream<List<SyncOutboxData>> watchReady({int? localAccountId}) {
    final query = select(syncOutbox)
      ..where((o) =>
          (localAccountId == null
                  ? const Constant(true)
                  : o.localAccountId.equals(localAccountId)) &
              o.state.isIn([
                OutboxState.pending,
                OutboxState.retryableError,
              ]) &
              (o.nextAttemptAt.isNull() |
                  o.nextAttemptAt.isSmallerOrEqualValue(DateTime.now())))
      ..orderBy([
        (o) => OrderingTerm.asc(o.dependencyRank),
        (o) => OrderingTerm.asc(o.queuedAt),
        (o) => OrderingTerm.asc(o.id),
      ]);
    return query.watch();
  }

  Future<int> pendingCount(int localAccountId) => (select(syncOutbox)
        ..where((o) =>
            o.localAccountId.equals(localAccountId) &
            o.state.isIn([
              OutboxState.pending,
              OutboxState.processing,
              OutboxState.retryableError,
            ])))
      .get()
      .then((rows) => rows.length);

  Future<SyncOutboxData?> findByServerId(
    int localAccountId,
    String entityType,
    String serverId,
  ) => (select(syncOutbox)..where((o) =>
          o.localAccountId.equals(localAccountId) &
          o.entityType.equals(entityType) &
          o.serverId.equals(serverId)))
      .getSingleOrNull();

  Future<void> markProcessing(int id) =>
      (update(syncOutbox)..where((o) => o.id.equals(id))).write(
        const SyncOutboxCompanion(state: Value(OutboxState.processing)),
      );

  /// Once a create entry points at an existing remote row, it must be sent
  /// as an update on subsequent attempts.
  Future<bool> promoteCreateToUpdate(int id) async {
    final changed = await (update(syncOutbox)
          ..where((o) =>
              o.id.equals(id) & o.operation.equals(OutboxOperation.create)))
        .write(
      const SyncOutboxCompanion(
        operation: Value(OutboxOperation.update),
        state: Value(OutboxState.processing),
      ),
    );
    return changed > 0;
  }

  Future<void> markRetryable(int id, String error, {Duration? delay}) async {
    final row = await (select(syncOutbox)..where((o) => o.id.equals(id))).getSingle();
    await (update(syncOutbox)..where((o) => o.id.equals(id))).write(
      SyncOutboxCompanion(
        state: const Value(OutboxState.retryableError),
        attemptCount: Value(row.attemptCount + 1),
        nextAttemptAt: Value(DateTime.now().add(delay ?? const Duration(minutes: 1))),
        lastError: Value(error),
        // Keep updatedAt as the local mutation version; retry time is already
        // represented by nextAttemptAt.
      ),
    );
  }

  Future<void> markCompleted(int id) =>
      (update(syncOutbox)..where((o) => o.id.equals(id))).write(
        SyncOutboxCompanion(
          state: const Value(OutboxState.completed),
          lastError: const Value(null),
        ),
      );

  /// Completes an item only when it is still the mutation that was sent.
  /// A local edit can coalesce into the same outbox row while the network
  /// request is in flight; that edit must remain pending.
  Future<bool> markCompletedIfCurrent(
    int id,
    DateTime expectedLocalMutationAt,
  ) async {
    final changed = await (update(syncOutbox)
          ..where((o) =>
              o.id.equals(id) &
              o.updatedAt.equals(expectedLocalMutationAt)))
        .write(
      SyncOutboxCompanion(
        state: const Value(OutboxState.completed),
        lastError: const Value(null),
      ),
    );
    return changed > 0;
  }

  Future<bool> rebaseIfCurrent(
    int id,
    DateTime expectedLocalMutationAt,
    DateTime remoteUpdatedAt,
  ) async {
    final changed = await (update(syncOutbox)
          ..where((o) =>
              o.id.equals(id) & o.updatedAt.equals(expectedLocalMutationAt)))
        .write(
      SyncOutboxCompanion(
        state: const Value(OutboxState.pending),
        baseRemoteUpdatedAt: Value(remoteUpdatedAt.toUtc()),
        nextAttemptAt: Value(DateTime.now().toUtc()),
      ),
    );
    return changed > 0;
  }

  Future<void> markPermanent(int id, String error) =>
      (update(syncOutbox)..where((o) => o.id.equals(id))).write(
        SyncOutboxCompanion(
          state: const Value(OutboxState.permanentError),
          lastError: Value(error),
        ),
      );

  Future<int> removeCompleted({int? localAccountId}) => (delete(syncOutbox)
        ..where((o) =>
            o.state.equals(OutboxState.completed) &
            (localAccountId == null
                ? const Constant(true)
                : o.localAccountId.equals(localAccountId))))
      .go();
}
