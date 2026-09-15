import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/tasks.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  // ── Streams ────────────────────────────────────────────────────────────────

  /// All tasks, newest first.
  Stream<List<Task>> watchAllTasks() =>
      (select(tasks)
            ..where((t) => t.isPlannerEntry.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Long-term To-Do items. Completed items intentionally remain visible.
  Stream<List<Task>> watchAllTodos() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return (select(tasks)
          ..where(
            (t) =>
                t.isPlannerEntry.equals(false) &
                (t.isCompleted.equals(false) |
                    t.completedAt.isBiggerOrEqualValue(cutoff)),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<Task>> watchHomeTodos() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return (select(tasks)
          ..where(
            (t) =>
                t.isPlannerEntry.equals(false) &
                (t.isCompleted.equals(false) |
                    t.completedAt.isBiggerOrEqualValue(start)),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<int> purgeExpiredCompletedTodos() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return (delete(tasks)
          ..where(
            (t) =>
                t.isPlannerEntry.equals(false) &
                t.isCompleted.equals(true) &
                t.completedAt.isSmallerThanValue(cutoff),
          ))
        .go();
  }

  Stream<List<Task>> watchAllPlannerEntries() =>
      (select(tasks)
            ..where((t) => t.isPlannerEntry.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
          .watch();

  /// Tasks whose dueDate falls on [date].
  Stream<List<Task>> watchTasksForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(tasks)
          ..where(
            (t) =>
                t.dueDate.isBetweenValues(start, end) &
                t.isPlannerEntry.equals(true),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .watch();
  }

  /// Tasks due today (convenience wrapper).
  Stream<List<Task>> watchTodaysTasks() =>
      (select(tasks)
            ..where(
              (t) =>
                  t.dueDate.isBetweenValues(
                    DateTime.now(),
                    DateTime.now().add(const Duration(days: 1)),
                  ) &
                  t.isPlannerEntry.equals(false),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
          .watch();

  /// Completed tasks only.
  Stream<List<Task>> watchCompletedTasks() =>
      (select(tasks)
            ..where(
              (t) =>
                  t.isCompleted.equals(true) & t.isPlannerEntry.equals(false),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.dueDate)]))
          .watch();

  /// Upcoming uncompleted tasks (due today or later).
  Stream<List<Task>> watchUpcomingTasks() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return (select(tasks)
          ..where(
            (t) =>
                t.isCompleted.equals(false) &
                t.isPlannerEntry.equals(false) &
                t.dueDate.isBiggerOrEqualValue(start),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .watch();
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<int> insertTask(TasksCompanion entry) => into(tasks).insert(entry);

  Future<bool> updateTask(TasksCompanion entry) => update(tasks).replace(entry);

  Future<void> toggleCompleted(int id, bool value) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          isCompleted: Value(value),
          completedAt: Value(value ? DateTime.now() : null),
        ),
      );

  Future<int> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  /// Tasks for a full ISO week: [monday] .. [monday]+7 days.
  Stream<List<Task>> watchTasksForWeek(DateTime monday) {
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 7));
    return (select(tasks)
          ..where(
            (t) =>
                t.dueDate.isBetweenValues(start, end) &
                t.isPlannerEntry.equals(true),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.dueDate),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }
}
