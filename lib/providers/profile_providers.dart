import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/daos/profile_dao.dart';
import 'database_provider.dart';
import 'local_account_provider.dart';

final profileDaoProvider = Provider<ProfileDao>((ref) {
  ref.watch(activeAccountIdProvider);
  return ref.watch(databaseProvider).profileDao;
});

/// Reactive stream of the single profile row (null if not yet created).
final profileProvider = StreamProvider<ProfileTableData?>((ref) {
  return ref.watch(profileDaoProvider).watchProfile();
});
