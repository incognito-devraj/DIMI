import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import 'database_provider.dart';
import 'local_account_provider.dart';

final pendingTransactionCandidatesProvider = StreamProvider<List<TransactionCandidate>>((ref) {
  ref.watch(activeAccountIdProvider);
  return ref.watch(databaseProvider).transactionDetectionDao.watchPending();
});
