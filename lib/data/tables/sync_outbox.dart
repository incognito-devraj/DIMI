import 'package:drift/drift.dart';

import 'local_accounts.dart';

/// Durable local queue for future Supabase synchronization.
///
/// This table is local-only. It stores mutation intent; the future sync worker
/// reads the current row from its owning Drift table when processing an entry.
@TableIndex(name: 'idx_sync_outbox_ready', columns: {#localAccountId, #state, #nextAttemptAt, #dependencyRank})
@TableIndex(name: 'idx_sync_outbox_server_id', columns: {#serverId})
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get localAccountId => integer().references(LocalAccounts, #id)();
  TextColumn get authUserId => text().nullable()();
  TextColumn get entityType => text()();
  IntColumn get localRowId => integer()();
  TextColumn get serverId => text().nullable()();
  TextColumn get operation => text()(); // create | update | delete
  TextColumn get state => text().withDefault(const Constant('pending'))();
  IntColumn get dependencyRank => integer().withDefault(const Constant(0))();
  DateTimeColumn get queuedAt => dateTime()();
  /// Local mutation/version timestamp for the queued row. Queue chronology is
  /// represented by [queuedAt]; this value must not be replaced by retry
  /// bookkeeping timestamps.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get baseRemoteUpdatedAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {localAccountId, entityType, localRowId},
      ];
}
