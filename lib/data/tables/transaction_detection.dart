import 'package:drift/drift.dart';

class TransactionDetectionEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventKey => text().unique()();
  TextColumn get sourcePackage => text()();
  TextColumn get sourceType => text()();
  TextColumn get title => text().nullable()();
  TextColumn get body => text().nullable()();
  TextColumn get bigText => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get receivedAt => dateTime()();
}

class TransactionCandidates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get candidateId => text().unique()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get merchantName => text().withDefault(const Constant('Unknown'))();
  TextColumn get merchantIdentity => text().withDefault(const Constant('unknown'))();
  TextColumn get direction => text()();
  TextColumn get transactionType => text()();
  TextColumn get source => text()();
  TextColumn get bankConfirmationStatus => text().withDefault(const Constant('NOT_RECEIVED'))();
  TextColumn get sourcePackage => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get accountHint => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  IntColumn get balanceAfterMinor => integer().nullable()();
  TextColumn get rawEventId => text().nullable()();
  RealColumn get confidenceScore => real()();
  TextColumn get status => text()();
  TextColumn get duplicateStatus => text()();
  TextColumn get category => text().withDefault(const Constant('Other'))();
  DateTimeColumn get createdAt => dateTime()();
}

class MerchantCategoryRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get merchantIdentity => text().unique()();
  TextColumn get category => text()();
  DateTimeColumn get updatedAt => dateTime()();
}
