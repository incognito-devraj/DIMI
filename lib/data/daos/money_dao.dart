import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/transactions.dart';
import 'sync_outbox_dao.dart';

part 'money_dao.g.dart';

@DriftAccessor(tables: [MoneyTransactions])
class MoneyDao extends DatabaseAccessor<AppDatabase> with _$MoneyDaoMixin {
  MoneyDao(super.db);

  // ── Streams ────────────────────────────────────────────────────────────────

  /// All transactions, most recent first.
  Stream<List<MoneyTransaction>> watchAllTransactions() => (select(
    moneyTransactions,
  )..where((t) => t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  /// Transactions for the current ISO week.
  Stream<List<MoneyTransaction>> watchThisWeeksTransactions() {
    final now = DateTime.now();
    final mon = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(mon.year, mon.month, mon.day);
    final weekEnd = weekStart.add(const Duration(days: 7));
    return (select(moneyTransactions)
          ..where((t) => t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull() & t.date.isBetweenValues(weekStart, weekEnd))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Transactions filtered by type ("expense" | "income" | "lent" | "borrowed").
  Stream<List<MoneyTransaction>> watchByType(String type) =>
      (select(moneyTransactions)
            ..where((t) => t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull() & t.type.equals(type))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<int> insertTransaction(MoneyTransactionsCompanion entry) async {
    final id = await into(moneyTransactions).insert(entry.copyWith(localAccountId: Value(db.activeAccountId)));
    final row = await (select(moneyTransactions)..where((t) => t.id.equals(id))).getSingle();
    await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.moneyTransaction, localRowId: id, operation: OutboxOperation.create, serverId: row.serverId, dependencyRank: OutboxDependencyRank.moneyTransaction);
    return id;
  }

  Future<bool> updateTransaction(MoneyTransactionsCompanion entry) async {
    final before = await (select(moneyTransactions)..where((t) => t.id.equals(entry.id.value) & t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull())).getSingleOrNull();
    if (before == null) return false;
    final changed = await (update(moneyTransactions)..where((t) => t.id.equals(entry.id.value) & t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull()))
        .write(entry.copyWith(localAccountId: Value(db.activeAccountId), updatedAt: Value(DateTime.now()))) > 0;
    if (changed) {
      final row = await (select(moneyTransactions)..where((t) => t.id.equals(entry.id.value))).getSingle();
      await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.moneyTransaction, localRowId: row.id, operation: OutboxOperation.update, serverId: row.serverId, baseRemoteUpdatedAt: before.updatedAt, localMutationAt: row.updatedAt, dependencyRank: OutboxDependencyRank.moneyTransaction);
    }
    return changed;
  }

  Future<int> deleteTransaction(int id) async {
    final row = await (select(moneyTransactions)..where((t) => t.id.equals(id) & t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull())).getSingleOrNull();
    if (row == null) return 0;
    final changed = await (update(moneyTransactions)..where((t) => t.id.equals(id) & t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull()))
        .write(MoneyTransactionsCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));
    if (changed > 0) await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.moneyTransaction, localRowId: id, operation: OutboxOperation.delete, serverId: row.serverId, baseRemoteUpdatedAt: row.updatedAt, localMutationAt: (await (select(moneyTransactions)..where((t) => t.id.equals(id))).getSingle()).updatedAt, dependencyRank: OutboxDependencyRank.moneyTransaction);
    return changed;
  }

  /// Returns only obviously malformed automatic records. Manual entries and
  /// automatic records with a meaningful merchant/category are untouched.
  Future<List<MoneyTransaction>> suspiciousDetectedTransactions() =>
      (select(moneyTransactions)..where((t) =>
          t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull() &
          t.type.isIn(['expense', 'income']) &
          t.note.like('%Detected automatically%') &
          t.note.like('%Unknown%') &
          t.category.equals('Other'))).get();

  Future<int> deleteSuspiciousDetectedTransactions() async {
    final rows = await suspiciousDetectedTransactions();
    var deleted = 0;
    for (final row in rows) { deleted += await deleteTransaction(row.id); }
    return deleted;
  }

  /// SQL-side aggregate scoped to the active local account.
  Future<int> totalForType(String type, {DateTime? from, DateTime? to}) async {
    final clauses = ['local_account_id = ?', 'type = ?'];
    final variables = <Variable<Object>>[
      Variable.withInt(db.activeAccountId),
      Variable.withString(type),
    ];
    if (from != null) {
      clauses.add('occurred_on >= ?');
      variables.add(Variable.withDateTime(from));
    }
    if (to != null) {
      clauses.add('occurred_on < ?');
      variables.add(Variable.withDateTime(to));
    }
    final row = await db.customSelect(
      'SELECT COALESCE(SUM(amount_minor), 0) AS total FROM money_transactions WHERE deleted_at IS NULL AND ${clauses.join(' AND ')}',
      variables: variables,
    ).getSingle();
    return row.read<int>('total');
  }
}
