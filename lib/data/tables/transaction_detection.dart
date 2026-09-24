import 'package:drift/drift.dart';
import 'local_accounts.dart';

@TableIndex(name: 'idx_detection_events_account_expires', columns: {#localAccountId, #expiresAt})
class TransactionDetectionEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get localAccountId => integer().withDefault(const Constant(1)).references(LocalAccounts, #id)();
  TextColumn get eventKey => text().unique()();
  TextColumn get sourcePackage => text()();
  TextColumn get sourceType => text()();
  TextColumn get title => text().nullable()();
  TextColumn get body => text().nullable()();
  TextColumn get bigText => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get receivedAt => dateTime()();
  DateTimeColumn get processedAt => dateTime().nullable()();
  DateTimeColumn get expiresAt => dateTime().withDefault(currentDateAndTime)();

}

@TableIndex(name: 'idx_candidates_account_status_date', columns: {#localAccountId, #status, #occurredAt})
@TableIndex(name: 'idx_candidates_expires_at', columns: {#expiresAt})
class TransactionCandidates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get localAccountId => integer().withDefault(const Constant(1)).references(LocalAccounts, #id)();
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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime().withDefault(currentDateAndTime)();

}

@TableIndex(name: 'idx_merchant_rules_account_identity', columns: {#localAccountId, #merchantIdentity})
class MerchantCategoryRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable().unique()();
  IntColumn get localAccountId => integer().withDefault(const Constant(1)).references(LocalAccounts, #id)();
  TextColumn get merchantIdentity => text()();
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{localAccountId, merchantIdentity}];
}
