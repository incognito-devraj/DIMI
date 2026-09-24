// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_dao.dart';

// ignore_for_file: type=lint
mixin _$ReminderDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalAccountsTable get localAccounts => attachedDatabase.localAccounts;
  $TasksTable get tasks => attachedDatabase.tasks;
  $RemindersTable get reminders => attachedDatabase.reminders;
  ReminderDaoManager get managers => ReminderDaoManager(this);
}

class ReminderDaoManager {
  final _$ReminderDaoMixin _db;
  ReminderDaoManager(this._db);
  $$LocalAccountsTableTableManager get localAccounts =>
      $$LocalAccountsTableTableManager(_db.attachedDatabase, _db.localAccounts);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db.attachedDatabase, _db.reminders);
}
