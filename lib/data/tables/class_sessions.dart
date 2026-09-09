import 'package:drift/drift.dart';

/// Recurring timetable entries — one row per class per day.
class ClassSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get courseName => text()();

  /// 1 = Monday … 7 = Sunday (ISO weekday convention).
  IntColumn get dayOfWeek => integer()();

  /// "HH:mm" 24-hour format.
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get room => text().nullable()();
  TextColumn get semester => text()();

  /// Hex color string (e.g. "#4A90D9") for the left color bar in UI.
  TextColumn get colorTag => text()();
}
