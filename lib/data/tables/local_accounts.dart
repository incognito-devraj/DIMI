import 'package:drift/drift.dart';

@TableIndex(name: 'idx_local_accounts_active', columns: {#isActive})
class LocalAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable().unique()();
  TextColumn get authProvider => text()();
  TextColumn get authUserId => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get avatarUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{authProvider, authUserId}];

}
