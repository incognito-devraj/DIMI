import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/local_accounts.dart';
import '../tables/profile_data.dart';
import 'sync_outbox_dao.dart';

part 'profile_dao.g.dart';

@DriftAccessor(tables: [LocalAccounts, ProfileData])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.db);

  // ── Streams ────────────────────────────────────────────────────────────────

  /// Reactive stream of the single profile row.
  Stream<ProfileTableData?> watchProfile() async* {
    while (true) {
      yield await getProfile();
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<ProfileTableData?> getProfile() async {
    final activeId = db.activeAccountId;
    final account = activeId > 0
        ? await (select(localAccounts)
              ..where((a) => a.id.equals(activeId) & a.deletedAt.isNull()))
            .getSingleOrNull()
        : await (select(localAccounts)
              ..where((a) => a.isActive.equals(true) & a.deletedAt.isNull()))
            .getSingleOrNull();
    if (account == null) return null;
    final data = await (select(
      profileData,
    )..where((p) => p.localAccountId.equals(account.id) & p.deletedAt.isNull())).getSingleOrNull();
    return ProfileTableData(
      id: account.id,
      name: account.displayName,
      role: data?.role ?? '',
      email: account.email ?? '',
      phone: data?.phone ?? '',
      college: data?.college ?? '',
      semester: data?.semester ?? '',
      photoPath: account.avatarUrl,
      points: data?.points ?? 0,
    );
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Inserts or replaces the profile row for the currently active account.
  Future<void> upsertProfile(ProfileTableCompanion entry) async {
    await transaction(() async {
    final now = DateTime.now();
    final id = db.activeAccountId;
    if (id <= 0) {
      throw StateError('Cannot save a profile without an active account');
    }
    final existingAccount = await (select(localAccounts)..where((a) => a.id.equals(id))).getSingleOrNull();
    final existingProfile = await (select(profileData)..where((p) => p.localAccountId.equals(id))).getSingleOrNull();
    if (existingAccount == null) {
      throw StateError('Cannot save a profile for missing account $id');
    }
    // Profile writes must not create a second active account. This also
    // repairs legacy state left by the old profile editor, which activated
    // account 1 without deactivating the previously active account.
    await update(localAccounts).write(const LocalAccountsCompanion(isActive: Value(false)));
    await into(localAccounts).insertOnConflictUpdate(
      LocalAccountsCompanion(
        id: Value(id),
        authProvider: Value(existingAccount.authProvider),
        authUserId: Value(existingAccount.authUserId),
        email: entry.email,
        displayName: entry.name,
        avatarUrl: entry.photoPath,
        isActive: const Value(true),
        createdAt: Value(now),
        lastLoginAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await into(profileData).insertOnConflictUpdate(
      ProfileDataCompanion(
        localAccountId: Value(id),
        role: entry.role,
        phone: entry.phone,
        college: entry.college,
        semester: entry.semester,
        points: entry.points,
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    final account = await (select(localAccounts)..where((a) => a.id.equals(id))).getSingle();
    if (account.authProvider == 'supabase') {
      await db.syncOutboxDao.enqueue(
        localAccountId: id,
        entityType: OutboxEntity.account,
        localRowId: id,
        operation: OutboxOperation.update,
        serverId: account.serverId,
        authUserId: account.authUserId,
        baseRemoteUpdatedAt: existingAccount.updatedAt,
        localMutationAt: account.updatedAt,
        dependencyRank: OutboxDependencyRank.account,
      );
      final profile = await (select(profileData)..where((p) => p.localAccountId.equals(id))).getSingle();
      await db.syncOutboxDao.enqueue(
        localAccountId: id,
        entityType: OutboxEntity.profile,
        localRowId: id,
        operation: OutboxOperation.update,
        serverId: profile.serverId,
        authUserId: account.authUserId,
        baseRemoteUpdatedAt: existingProfile?.updatedAt,
        localMutationAt: profile.updatedAt,
        dependencyRank: OutboxDependencyRank.profile,
      );
    }
    });
  }
}
