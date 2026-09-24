import 'package:drift/drift.dart';
import 'local_accounts.dart';

class ProfileData extends Table {
  IntColumn get localAccountId => integer().references(LocalAccounts, #id)();
  TextColumn get serverId => text().nullable().unique()();
  TextColumn get role => text().withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get college => text().withDefault(const Constant(''))();
  TextColumn get semester => text().withDefault(const Constant(''))();
  IntColumn get points => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {localAccountId};
}
