import 'package:drift/drift.dart';

/// A user-created reminder with an enable/disable toggle.
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get dueAt => dateTime()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
}
