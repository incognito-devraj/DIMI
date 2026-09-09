import 'package:drift/drift.dart';

/// A money transaction — expense, income, or loan.
/// Named MoneyTransactions to avoid conflict with drift's internal
/// Transaction concept.
class MoneyTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// "expense" | "income" | "loan"
  TextColumn get type => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
}
