import 'package:drift/drift.dart';

/// A single timed study session logged by the user.
class StudySessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Matches Course.name (soft reference, not FK).
  TextColumn get courseName => text()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get durationMinutes => integer()();
}
