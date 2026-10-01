import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/local_accounts.dart';
import 'sync_outbox_dao.dart';

part 'local_account_dao.g.dart';

@DriftAccessor(tables: [LocalAccounts])
class LocalAccountDao extends DatabaseAccessor<AppDatabase>
    with _$LocalAccountDaoMixin {
  LocalAccountDao(super.db);

  Future<LocalAccount?> getActive() {
    final activeId = db.activeAccountId;
    if (activeId > 0) {
      return (select(localAccounts)
            ..where((a) => a.id.equals(activeId) & a.deletedAt.isNull()))
          .getSingleOrNull();
    }
    return (select(localAccounts)
          ..where((a) => a.isActive.equals(true) & a.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<int> ensureOfflineAccount() async {
    final offline = await (select(localAccounts)
          ..where((a) => a.authProvider.equals('offline') & a.deletedAt.isNull()))
        .getSingleOrNull();
    if (offline != null) {
      await activate(offline.id);
      return offline.id;
    }
    final now = DateTime.now();
    final id = await into(localAccounts).insert(LocalAccountsCompanion.insert(
      authProvider: 'offline',
      displayName: const Value('Student'),
      isActive: const Value(true),
      createdAt: now,
    ));
    db.setActiveAccountId(id);
    return id;
  }

  Future<int> ensureAuthenticatedAccount({
    required String userId,
    required String? email,
    required String displayName,
    required String? avatarUrl,
  }) async {
    final existing = await (select(localAccounts)..where(
      (a) =>
          a.authProvider.equals('supabase') &
          a.authUserId.equals(userId) &
          a.deletedAt.isNull(),
    )).getSingleOrNull();
    final id = existing?.id ?? await into(localAccounts).insert(
      LocalAccountsCompanion.insert(
        authProvider: 'supabase',
        authUserId: Value(userId),
        email: Value(email),
        displayName: Value(displayName),
        avatarUrl: Value(avatarUrl),
        createdAt: DateTime.now(),
      ),
    );
    if (existing != null) {
      await (update(localAccounts)..where((a) => a.id.equals(id))).write(
        LocalAccountsCompanion(
          email: Value(email),
          displayName: Value(displayName),
          avatarUrl: Value(avatarUrl),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
    await claimOfflineData(id);
    await db.syncOutboxDao.enqueue(
      localAccountId: id,
      entityType: OutboxEntity.account,
      localRowId: id,
      operation: existing == null ? OutboxOperation.create : OutboxOperation.update,
      serverId: existing?.serverId,
      authUserId: userId,
      baseRemoteUpdatedAt: existing?.updatedAt,
      localMutationAt: (await (select(localAccounts)..where((a) => a.id.equals(id))).getSingle()).updatedAt,
      dependencyRank: OutboxDependencyRank.account,
    );
    await activate(id);
    return id;
  }

  /// Claims rows created while DIMI was in offline mode for [accountId].
  ///
  /// The claim is deliberately performed in one transaction and uses the
  /// existing local row/server identities. Rows are moved, not copied, so a
  /// repeated auth callback cannot create duplicates. Existing authenticated
  /// cloud-backed rows are left intact; the normal sync conflict protocol
  /// reconciles them after the claim.
  Future<void> claimOfflineData(int accountId) async {
    final offline = await (select(localAccounts)..where(
      (a) => a.authProvider.equals('offline') & a.deletedAt.isNull(),
    )).getSingleOrNull();
    if (offline == null || offline.id == accountId) return;

    await transaction(() async {
      // Profile data has a one-row-per-account primary key. Preserve an
      // already existing authenticated profile, otherwise move the offline
      // profile into the authenticated account.
      await customStatement(
        'INSERT OR IGNORE INTO profile_data '
        '(local_account_id, server_id, role, phone, college, semester, points, created_at, updated_at, deleted_at) '
        'SELECT ?, server_id, role, phone, college, semester, points, created_at, updated_at, deleted_at '
        'FROM profile_data WHERE local_account_id = ?',
        [accountId, offline.id],
      );
      await customStatement(
        'DELETE FROM profile_data WHERE local_account_id = ?',
        [offline.id],
      );

      for (final table in [
        'tasks',
        'reminders',
        'notes',
        'money_transactions',
        'youtube_playlists',
      ]) {
        await customStatement(
          'UPDATE $table SET local_account_id = ? WHERE local_account_id = ?',
          [accountId, offline.id],
        );
      }

      // The moved rows keep their existing outbox identity and pending state,
      // but now belong to the authenticated sync context.
      final authenticated = await (select(localAccounts)
            ..where((a) => a.id.equals(accountId)))
          .getSingle();
      await customStatement(
        'UPDATE sync_outbox SET local_account_id = ?, auth_user_id = ? '
        'WHERE local_account_id = ?',
        [accountId, authenticated.authUserId, offline.id],
      );
      await (update(localAccounts)..where((a) => a.id.equals(offline.id)))
          .write(const LocalAccountsCompanion(isActive: Value(false)));
      await (delete(localAccounts)..where((a) => a.id.equals(offline.id))).go();
    });
  }

  Future<void> deactivateAll() async {
    await update(localAccounts)
        .write(const LocalAccountsCompanion(isActive: Value(false)));
    db.setActiveAccountId(0);
  }

  Future<void> activate(int id) async {
    await transaction(() async {
      await update(localAccounts).write(const LocalAccountsCompanion(isActive: Value(false)));
      await (update(localAccounts)..where((a) => a.id.equals(id))).write(
        LocalAccountsCompanion(
          isActive: const Value(true),
          lastLoginAt: Value(DateTime.now()),
        ),
      );
      db.setActiveAccountId(id);
    });
  }
}
