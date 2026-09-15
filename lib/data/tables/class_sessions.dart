import 'package:drift/drift.dart';

class ClassSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get courseName => text()();
  IntColumn get dayOfWeek => integer()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get room => text().nullable()();
  TextColumn get semester => text()();
  TextColumn get colorTag => text()();
}
