import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/transaction_detection/transaction_detection_service.dart';
import '../data/database.dart';
import 'database_provider.dart';

final transactionDetectionServiceProvider = Provider<TransactionDetectionService>((ref) => TransactionDetectionService(ref.watch(databaseProvider)));
final pendingTransactionCandidatesProvider = StreamProvider<List<TransactionCandidate>>((ref) => ref.watch(databaseProvider).transactionDetectionDao.watchPending());
