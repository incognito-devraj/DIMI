import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/local_accounts.dart';
import 'sync_outbox_dao.dart';

part 'local_account_dao.g.dart';

@DriftAccessor(tables: [LocalAccounts])
class LocalAccountDao extends DatabaseAccessor<AppDatabase> with _$LocalAccountDaoMixin {
  LocalAccountDao(super.db);

  Future<LocalAccount?> getActive() =>
      (select(localAccounts)..where((a) => a.isActive.equals(true) & a.deletedAt.isNull())).getSingleOrNull();

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
      (a) => a.authProvider.equals('supabase') & a.authUserId.equals(userId) & a.deletedAt.isNull(),
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

  Future<void> deactivateAll() async {
    await update(localAccounts).write(const LocalAccountsCompanion(isActive: Value(false)));
    db.setActiveAccountId(0);
  }

  Future<void> activate(int id) async {
    await transaction(() async {
      await update(localAccounts).write(const LocalAccountsCompanion(isActive: Value(false)));
      await (update(localAccounts)..where((a) => a.id.equals(id))).write(
        LocalAccountsCompanion(isActive: const Value(true), lastLoginAt: Value(DateTime.now())),
      );
      db.setActiveAccountId(id);
    });
  }
}
