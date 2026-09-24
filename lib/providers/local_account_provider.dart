import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../data/daos/local_account_dao.dart';
import 'database_provider.dart';

final localAccountDaoProvider = Provider<LocalAccountDao>((ref) => ref.watch(databaseProvider).localAccountDao);
final activeAccountIdProvider = StreamProvider<int>((ref) {
  return ref.watch(databaseProvider).watchActiveAccountId();
});

final activeLocalAccountProvider = FutureProvider<LocalAccount?>((ref) {
  ref.watch(activeAccountIdProvider);
  return ref.watch(localAccountDaoProvider).getActive();
});
