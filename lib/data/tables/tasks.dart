import 'package:drift/drift.dart';

/// Drift table definition for user tasks.
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text()();

  /// Separates planner entries from independent task items.
  BoolColumn get isPlannerEntry =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime()();
  // Stored as "HH:mm" string so we don't force a full DateTime for time-only.
  TextColumn get dueTime => text().nullable()();
  IntColumn get plannedMinutes => integer().withDefault(const Constant(60))();
  IntColumn get completedMinutes => integer().withDefault(const Constant(0))();
  IntColumn get reminderMinutesBefore => integer().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Completion timestamp for the task-rhythm heatmap.
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
