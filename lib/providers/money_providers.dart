import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/daos/money_dao.dart';
import 'database_provider.dart';

final moneyDaoProvider = Provider<MoneyDao>((ref) {
  return ref.watch(databaseProvider).moneyDao;
});

final allTransactionsProvider = StreamProvider<List<MoneyTransaction>>((ref) {
  return ref.watch(moneyDaoProvider).watchAllTransactions();
});

final thisWeeksTransactionsProvider = StreamProvider<List<MoneyTransaction>>((
  ref,
) {
  return ref.watch(moneyDaoProvider).watchThisWeeksTransactions();
});

/// Transactions filtered by type ("expense" | "income" | "loan").
final transactionsByTypeProvider =
    StreamProvider.family<List<MoneyTransaction>, String>((ref, type) {
      return ref.watch(moneyDaoProvider).watchByType(type);
    });
