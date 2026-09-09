import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/transactions.dart';

part 'money_dao.g.dart';

@DriftAccessor(tables: [MoneyTransactions])
class MoneyDao extends DatabaseAccessor<AppDatabase> with _$MoneyDaoMixin {
  MoneyDao(super.db);

  // ── Streams ────────────────────────────────────────────────────────────────

  /// All transactions, most recent first.
  Stream<List<MoneyTransaction>> watchAllTransactions() => (select(
    moneyTransactions,
  )..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  /// Transactions for the current ISO week.
  Stream<List<MoneyTransaction>> watchThisWeeksTransactions() {
    final now = DateTime.now();
    final mon = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(mon.year, mon.month, mon.day);
    final weekEnd = weekStart.add(const Duration(days: 7));
    return (select(moneyTransactions)
          ..where((t) => t.date.isBetweenValues(weekStart, weekEnd))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Transactions filtered by type ("expense" | "income" | "loan").
  Stream<List<MoneyTransaction>> watchByType(String type) =>
      (select(moneyTransactions)
            ..where((t) => t.type.equals(type))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<int> insertTransaction(MoneyTransactionsCompanion entry) =>
      into(moneyTransactions).insert(entry);

  Future<bool> updateTransaction(MoneyTransactionsCompanion entry) =>
      update(moneyTransactions).replace(entry);

  Future<int> deleteTransaction(int id) =>
      (delete(moneyTransactions)..where((t) => t.id.equals(id))).go();
}
