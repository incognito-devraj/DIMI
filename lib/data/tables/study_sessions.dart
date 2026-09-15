import 'package:drift/drift.dart';

class StudySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get courseName => text()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get durationMinutes => integer()();
}
