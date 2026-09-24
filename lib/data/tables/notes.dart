import 'package:drift/drift.dart';
import 'local_accounts.dart';

@TableIndex(name: 'idx_notes_account_updated', columns: {#localAccountId, #updatedAt})
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable().unique()();
  IntColumn get localAccountId => integer().withDefault(const Constant(1)).references(LocalAccounts, #id)();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

}
