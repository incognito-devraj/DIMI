import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/reminders.dart';
import 'sync_outbox_dao.dart';

part 'reminder_dao.g.dart';

@DriftAccessor(tables: [Reminders])
class ReminderDao extends DatabaseAccessor<AppDatabase>
    with _$ReminderDaoMixin {
  ReminderDao(super.db);

  // ── Streams ────────────────────────────────────────────────────────────────

  Stream<List<Reminder>> watchAllReminders() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return (select(reminders)
          ..where((r) => r.localAccountId.equals(db.activeAccountId) & r.deletedAt.isNull() & r.dueAt.isBiggerOrEqualValue(today))
          ..orderBy([(r) => OrderingTerm.asc(r.dueAt)]))
        .watch();
  }

  Stream<List<Reminder>> watchTodaysReminders() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (select(reminders)
          ..where((r) => r.localAccountId.equals(db.activeAccountId) & r.deletedAt.isNull() & r.dueAt.isBetweenValues(start, end))
          ..orderBy([(r) => OrderingTerm.asc(r.dueAt)]))
        .watch();
  }

  Stream<List<Reminder>> watchUpcomingReminders() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return (select(reminders)
          ..where((r) => r.localAccountId.equals(db.activeAccountId) & r.deletedAt.isNull() & r.dueAt.isBiggerOrEqualValue(today))
          ..orderBy([(r) => OrderingTerm.asc(r.dueAt)]))
        .watch();
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<int> insertReminder(RemindersCompanion entry) async {
    final id = await into(reminders).insert(entry.copyWith(localAccountId: Value(db.activeAccountId), notificationId: entry.notificationId.present ? entry.notificationId : Value(DateTime.now().millisecondsSinceEpoch)));
    final row = await (select(reminders)..where((r) => r.id.equals(id))).getSingle();
    await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.reminder, localRowId: id, operation: OutboxOperation.create, serverId: row.serverId, dependencyRank: OutboxDependencyRank.reminder);
    return id;
  }

  Future<Reminder?> getById(int id) =>
      (select(reminders)..where((r) => r.id.equals(id) & r.localAccountId.equals(db.activeAccountId) & r.deletedAt.isNull())).getSingleOrNull();

  Future<Reminder?> getByTaskId(int taskId) =>
      (select(reminders)..where((r) => r.taskId.equals(taskId) & r.localAccountId.equals(db.activeAccountId) & r.deletedAt.isNull())).getSingleOrNull();

  Future<Reminder?> updateByTaskId(int taskId, {required String title, required DateTime dueAt}) async {
    final reminder = await getByTaskId(taskId);
    if (reminder == null) return null;
    await (update(reminders)..where((r) => r.id.equals(reminder.id) & r.localAccountId.equals(db.activeAccountId))).write(
      RemindersCompanion(title: Value(title), dueAt: Value(dueAt), updatedAt: Value(DateTime.now())),
    );
    final updated = await getById(reminder.id);
    if (updated != null) await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.reminder, localRowId: updated.id, operation: OutboxOperation.update, serverId: updated.serverId, baseRemoteUpdatedAt: reminder.updatedAt, localMutationAt: updated.updatedAt, dependencyRank: OutboxDependencyRank.reminder);
    return updated;
  }

  Future<Reminder?> deleteByTaskId(int taskId) async {
    final reminder = await getByTaskId(taskId);
    if (reminder == null) return null;
    final now = DateTime.now();
    await (update(reminders)..where((r) => r.id.equals(reminder.id) & r.localAccountId.equals(db.activeAccountId) & r.deletedAt.isNull()))
        .write(RemindersCompanion(deletedAt: Value(now), updatedAt: Value(now)));
    await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.reminder, localRowId: reminder.id, operation: OutboxOperation.delete, serverId: reminder.serverId, baseRemoteUpdatedAt: reminder.updatedAt, localMutationAt: now, dependencyRank: OutboxDependencyRank.reminder);
    return reminder;
  }

  Future<bool> updateReminder(RemindersCompanion entry) async {
    final before = await (select(reminders)..where((r) => r.id.equals(entry.id.value) & r.localAccountId.equals(db.activeAccountId) & r.deletedAt.isNull())).getSingleOrNull();
    if (before == null) return false;
    final changed = await update(reminders).replace(entry.copyWith(localAccountId: Value(db.activeAccountId), updatedAt: Value(DateTime.now())));
    if (changed) {
      final row = await (select(reminders)..where((r) => r.id.equals(entry.id.value))).getSingle();
      await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.reminder, localRowId: row.id, operation: OutboxOperation.update, serverId: row.serverId, baseRemoteUpdatedAt: before.updatedAt, localMutationAt: row.updatedAt, dependencyRank: OutboxDependencyRank.reminder);
    }
    return changed;
  }

  Future<void> toggleEnabled(int id, bool value) async {
    final before = await (select(reminders)..where((r) => r.id.equals(id) & r.localAccountId.equals(db.activeAccountId) & r.deletedAt.isNull())).getSingleOrNull();
    if (before == null) return;
    final changed = await (update(reminders)..where((r) => r.id.equals(id) & r.localAccountId.equals(db.activeAccountId) & r.deletedAt.isNull())).write(
      RemindersCompanion(isEnabled: Value(value), updatedAt: Value(DateTime.now())),
    );
    if (changed > 0) {
      final row = await (select(reminders)..where((r) => r.id.equals(id))).getSingle();
      await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.reminder, localRowId: id, operation: OutboxOperation.update, serverId: row.serverId, baseRemoteUpdatedAt: before.updatedAt, localMutationAt: row.updatedAt, dependencyRank: OutboxDependencyRank.reminder);
    }
  }

  Future<int> deleteReminder(int id) async {
    final row = await getById(id);
    if (row == null) return 0;
    final changed = await (update(reminders)..where((r) => r.id.equals(id) & r.localAccountId.equals(db.activeAccountId) & r.deletedAt.isNull()))
        .write(RemindersCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));
    if (changed > 0) await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.reminder, localRowId: id, operation: OutboxOperation.delete, serverId: row.serverId, baseRemoteUpdatedAt: row.updatedAt, localMutationAt: DateTime.now(), dependencyRank: OutboxDependencyRank.reminder);
    return changed;
  }

  /// Tombstones ordinary and event reminders after their calendar day ends.
  /// Playlist reminders use the existing Watch:/Tick off: titles and remain
  /// active until the playlist/course is finished.
  Future<List<int>> expirePastStandardReminders() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rows = await (select(reminders)
          ..where((r) =>
              r.localAccountId.equals(db.activeAccountId) &
              r.deletedAt.isNull() &
              r.dueAt.isSmallerThanValue(today)))
        .get();
    final expired = rows.where((row) =>
        !row.title.startsWith('Watch: ') &&
        !row.title.startsWith('Tick off: '));
    final notificationIds = <int>[];
    for (final row in expired) {
      await deleteReminder(row.id);
      if (row.notificationId != 0) notificationIds.add(row.notificationId);
    }
    return notificationIds;
  }

  /// One-shot query — all enabled reminders with future due dates.
  /// Used at app startup to reschedule notifications.
  Future<List<Reminder>> getAllEnabled() {
    final now = DateTime.now();
    return (select(reminders)
          ..where(
            (r) => r.localAccountId.equals(db.activeAccountId) & r.deletedAt.isNull() & r.isEnabled.equals(true) & r.dueAt.isBiggerThanValue(now),
          )
          ..orderBy([(r) => OrderingTerm.asc(r.dueAt)]))
        .get();
  }
}
