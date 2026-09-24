import 'package:drift/drift.dart';
import 'local_accounts.dart';

/// Drift table definition for user tasks.
@TableIndex(name: 'idx_tasks_account_planner_date', columns: {#localAccountId, #isPlannerEntry, #dueDate})
@TableIndex(name: 'idx_tasks_account_todo_completed', columns: {#localAccountId, #isPlannerEntry, #isCompleted, #completedAt})
@TableIndex(name: 'idx_tasks_created_at', columns: {#localAccountId, #isPlannerEntry, #createdAt})
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable().unique()();
  /// Exact Supabase version for CAS; local Drift DateTime values are second precision.
  TextColumn get remoteUpdatedAt =>
      text().nullable().named('remote_updated_at')();
  IntColumn get localAccountId => integer().withDefault(const Constant(1)).references(LocalAccounts, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text()();

  /// Separates planner entries from independent task items.
  BoolColumn get isPlannerEntry =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime().named('local_date')();
  // Stored as "HH:mm" string so we don't force a full DateTime for time-only.
  TextColumn get dueTime => text().nullable().named('due_time_hhmm')();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Completion timestamp for the task-rhythm heatmap.
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

}
