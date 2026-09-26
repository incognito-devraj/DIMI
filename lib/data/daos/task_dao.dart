import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/tasks.dart';
import '../tables/reminders.dart';
import 'sync_outbox_dao.dart';
import '../sync/sync_timestamp.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks, Reminders])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  Future<Task?> getById(int id) {
    return (select(tasks)
          ..where((task) =>
              task.id.equals(id) &
              task.localAccountId.equals(db.activeAccountId) &
              task.deletedAt.isNull()))
        .getSingleOrNull();
  }

  // ── Streams ────────────────────────────────────────────────────────────────

  /// All tasks, newest first.
  Stream<List<Task>> watchAllTasks() =>
      (select(tasks)
            ..where((t) => t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull() & t.isPlannerEntry.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Long-term To-Do items. Completed items intentionally remain visible.
  Stream<List<Task>> watchAllTodos() =>
      (select(tasks)
            ..where((t) =>
                t.localAccountId.equals(db.activeAccountId) &
                t.deletedAt.isNull() &
                t.isPlannerEntry.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<List<Task>> watchHomeTodos() =>
      (select(tasks)
            ..where((t) =>
                t.localAccountId.equals(db.activeAccountId) &
                t.deletedAt.isNull() &
                t.isPlannerEntry.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<List<Task>> watchAllPlannerEntries() =>
      (select(tasks)
            ..where((t) => t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull() & t.isPlannerEntry.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
          .watch();

  Stream<List<Task>> watchPlannerEntriesInRange(DateTime from, DateTime to) =>
      (select(tasks)
            ..where((t) => t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull() &
                t.isPlannerEntry.equals(true) &
                t.dueDate.isBiggerOrEqualValue(from) &
                t.dueDate.isSmallerThanValue(to))
            ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
          .watch();

  /// Tasks whose dueDate falls on [date].
  Stream<List<Task>> watchTasksForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(tasks)
          ..where(
            (t) =>
                t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull() & t.dueDate.isBiggerOrEqualValue(start) &
                t.dueDate.isSmallerThanValue(end) &
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
              t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull() & t.dueDate.isBetweenValues(
                    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).add(const Duration(days: 1)),
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
                t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull() & t.isCompleted.equals(true) & t.isPlannerEntry.equals(false),
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
                t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull() & t.isCompleted.equals(false) &
                t.isPlannerEntry.equals(false) &
                t.dueDate.isBiggerOrEqualValue(start),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .watch();
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<int> insertTask(TasksCompanion entry) async {
    final id = await into(tasks).insert(entry.copyWith(localAccountId: Value(db.activeAccountId)));
    final row = await (select(tasks)..where((t) => t.id.equals(id))).getSingle();
    await db.syncOutboxDao.enqueue(
      localAccountId: db.activeAccountId,
      entityType: OutboxEntity.task,
      localRowId: id,
      operation: OutboxOperation.create,
      serverId: row.serverId,
      dependencyRank: OutboxDependencyRank.task,
    );
    return id;
  }

  Future<bool> updateTask(TasksCompanion entry) async {
    final before = await (select(tasks)..where((t) => t.id.equals(entry.id.value) & t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull())).getSingleOrNull();
    if (before == null) return false;
    final changed = await (update(tasks)
          ..where((t) =>
              t.id.equals(entry.id.value) &
              t.localAccountId.equals(db.activeAccountId) &
              t.deletedAt.isNull()))
        .write(
          entry.copyWith(
            localAccountId: Value(db.activeAccountId),
            updatedAt: Value(DateTime.now()),
          ),
        ) >
        0;
    if (changed) {
      final row = await (select(tasks)..where((t) => t.id.equals(entry.id.value))).getSingle();
      await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.task, localRowId: row.id, operation: OutboxOperation.update, serverId: row.serverId, baseRemoteUpdatedAt: _remoteVersion(before), localMutationAt: row.updatedAt, dependencyRank: OutboxDependencyRank.task);
    }
    return changed;
  }

  Future<void> toggleCompleted(int id, bool value) async {
    final task = await (select(tasks)..where((t) => t.id.equals(id) & t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull())).getSingleOrNull();
    if (task == null || (task.isPlannerEntry && _isPastPlannerDate(task.dueDate))) return;
    await (update(tasks)..where((t) => t.id.equals(id) & t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull())).write(
        TasksCompanion(
          isCompleted: Value(value),
          completedAt: Value(value ? DateTime.now() : null),
          updatedAt: Value(DateTime.now()),
        ),
      );
    final row = await (select(tasks)..where((t) => t.id.equals(id))).getSingle();
    await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.task, localRowId: id, operation: OutboxOperation.update, serverId: row.serverId, baseRemoteUpdatedAt: _remoteVersion(task), localMutationAt: row.updatedAt, dependencyRank: OutboxDependencyRank.task);
  }

  /// Notification actions complete locally even when a planner date has passed.
  Future<void> completeFromNotification(int id) async {
    final task = await (select(tasks)..where((t) =>
      t.id.equals(id) & t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull()))
      .getSingleOrNull();
    if (task == null || task.isCompleted) return;
    final now = DateTime.now();
    final changed = await (update(tasks)..where((t) =>
      t.id.equals(id) & t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull()))
      .write(TasksCompanion(isCompleted: const Value(true), completedAt: Value(now), updatedAt: Value(now)));
    if (changed > 0) {
      final row = await (select(tasks)..where((t) => t.id.equals(id))).getSingle();
      await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.task,
        localRowId: id, operation: OutboxOperation.update, serverId: row.serverId,
        baseRemoteUpdatedAt: _remoteVersion(task), localMutationAt: row.updatedAt,
        dependencyRank: OutboxDependencyRank.task);
    }
  }

  Future<int> deleteTask(int id) async {
    final task = await (select(tasks)..where((t) => t.id.equals(id) & t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull())).getSingleOrNull();
    if (task == null || (task.isPlannerEntry && _isPastPlannerDate(task.dueDate))) return 0;
    return transaction(() async {
      // Keep the tombstone version strictly after a timestamp captured just
      // before this operation, including stores that round DateTime values.
      final now = DateTime.now().add(const Duration(seconds: 1));
      final linkedReminders = await (select(reminders)..where((r) => r.taskId.equals(id) & r.localAccountId.equals(db.activeAccountId) & r.deletedAt.isNull())).get();
      await (update(reminders)..where((r) => r.taskId.equals(id) & r.localAccountId.equals(db.activeAccountId) & r.deletedAt.isNull()))
          .write(RemindersCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      for (final reminder in linkedReminders) {
        await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.reminder, localRowId: reminder.id, operation: OutboxOperation.delete, serverId: reminder.serverId, baseRemoteUpdatedAt: reminder.updatedAt, localMutationAt: now, dependencyRank: OutboxDependencyRank.reminder);
      }
      final changed = await (update(tasks)..where((t) => t.id.equals(id) & t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull()))
          .write(TasksCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      if (changed > 0) {
        await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.task, localRowId: id, operation: OutboxOperation.delete, serverId: task.serverId, baseRemoteUpdatedAt: _remoteVersion(task), localMutationAt: now, dependencyRank: OutboxDependencyRank.task);
      }
      return changed;
    });
  }

  Future<int?> deleteTaskWithReminder(int id) async {
    return transaction(() async {
      final task = await (select(tasks)..where((t) => t.id.equals(id) & t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull())).getSingleOrNull();
      if (task == null || (task.isPlannerEntry && _isPastPlannerDate(task.dueDate))) return null;
      final reminder = await (select(reminders)..where((r) => r.taskId.equals(id) & r.localAccountId.equals(db.activeAccountId) & r.deletedAt.isNull())).getSingleOrNull();
      final now = DateTime.now().add(const Duration(seconds: 1));
      if (reminder != null) {
        await (update(reminders)..where((r) => r.id.equals(reminder.id) & r.localAccountId.equals(db.activeAccountId) & r.deletedAt.isNull()))
            .write(RemindersCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.reminder, localRowId: reminder.id, operation: OutboxOperation.delete, serverId: reminder.serverId, baseRemoteUpdatedAt: reminder.updatedAt, localMutationAt: now, dependencyRank: OutboxDependencyRank.reminder);
      }
      await (update(tasks)..where((t) => t.id.equals(id) & t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull()))
          .write(TasksCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.task, localRowId: id, operation: OutboxOperation.delete, serverId: task.serverId, baseRemoteUpdatedAt: _remoteVersion(task), localMutationAt: now, dependencyRank: OutboxDependencyRank.task);
      return reminder?.notificationId;
    });
  }

  /// Tasks for a full ISO week: [monday] .. [monday]+7 days.
  Stream<List<Task>> watchTasksForWeek(DateTime monday) {
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 7));
    return (select(tasks)
          ..where(
            (t) =>
                t.localAccountId.equals(db.activeAccountId) & t.deletedAt.isNull() &
                t.dueDate.isBiggerOrEqualValue(start) &
                t.dueDate.isSmallerThanValue(end) &
                t.isPlannerEntry.equals(true),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.dueDate),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }
}

bool _isPastPlannerDate(DateTime date) {
  final today = DateTime.now();
  final dueDay = DateTime(date.year, date.month, date.day);
  final todayDay = DateTime(today.year, today.month, today.day);
  return dueDay.isBefore(todayDay);
}

DateTime? _remoteVersion(Task task) => SyncTimestamp.parse(task.remoteUpdatedAt);
