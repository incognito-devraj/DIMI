import 'package:drift/drift.dart';

import 'local_accounts.dart';

/// A permanent money transaction: expense, income, lent, borrowed, or
/// or borrowed transaction. Named MoneyTransactions to avoid conflict with
/// Drift's internal Transaction concept.
@TableIndex(
  name: 'idx_money_account_type_date',
  columns: {#localAccountId, #type, #date},
)
@TableIndex(name: 'idx_money_account_date', columns: {#localAccountId, #date})
class MoneyTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable().unique()();
  IntColumn get localAccountId =>
      integer().withDefault(const Constant(1)).references(LocalAccounts, #id)();

  /// "expense" | "income" | "lent" | "borrowed".
  TextColumn get type => text()();

  /// Amount in minor currency units (paise for INR). Never floating-point.
  IntColumn get amount => integer().named('amount_minor')();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get category => text()();
  TextColumn get note => text().nullable()();
  TextColumn get counterparty => text().nullable()();
  DateTimeColumn get date => dateTime().named('occurred_on')();
  TextColumn get source => text().withDefault(const Constant('manual'))();

  /// Local detection provenance only; detection data remains local-only and
  /// this field is never uploaded as a cloud relationship.
  TextColumn get detectionCandidateId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
