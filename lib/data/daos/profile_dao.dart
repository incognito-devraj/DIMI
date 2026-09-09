import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/profile.dart';

part 'profile_dao.g.dart';

@DriftAccessor(tables: [ProfileTable])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.db);

  // ── Streams ────────────────────────────────────────────────────────────────

  /// Reactive stream of the single profile row.
  Stream<ProfileTableData?> watchProfile() =>
      (select(profileTable)..where((p) => p.id.equals(1))).watchSingleOrNull();

  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<ProfileTableData?> getProfile() =>
      (select(profileTable)..where((p) => p.id.equals(1))).getSingleOrNull();

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Inserts or replaces the profile row (id always = 1).
  Future<void> upsertProfile(ProfileTableCompanion entry) =>
      into(profileTable).insertOnConflictUpdate(entry);
}
