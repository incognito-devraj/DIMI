import 'package:drift/drift.dart';
import 'tasks.dart';
import 'local_accounts.dart';

/// A user-created reminder with an enable/disable toggle.
@TableIndex(name: 'idx_reminders_account_enabled_due', columns: {#localAccountId, #isEnabled, #dueAt})
@TableIndex(name: 'idx_reminders_task_id', columns: {#taskId})
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable().unique()();
  IntColumn get localAccountId => integer().withDefault(const Constant(1)).references(LocalAccounts, #id)();
  IntColumn get taskId => integer().nullable().references(Tasks, #id, onDelete: KeyAction.setNull)();
  IntColumn get notificationId => integer().withDefault(const Constant(0)).unique()();
  TextColumn get title => text()();
  DateTimeColumn get dueAt => dateTime()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

}
