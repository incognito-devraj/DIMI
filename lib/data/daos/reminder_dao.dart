import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/reminders.dart';

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
          ..where((r) => r.dueAt.isBiggerOrEqualValue(today))
          ..orderBy([(r) => OrderingTerm.asc(r.dueAt)]))
        .watch();
  }

  Stream<List<Reminder>> watchTodaysReminders() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (select(reminders)
          ..where((r) => r.dueAt.isBetweenValues(start, end))
          ..orderBy([(r) => OrderingTerm.asc(r.dueAt)]))
        .watch();
  }

  Stream<List<Reminder>> watchUpcomingReminders() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return (select(reminders)
          ..where((r) => r.dueAt.isBiggerOrEqualValue(today))
          ..orderBy([(r) => OrderingTerm.asc(r.dueAt)]))
        .watch();
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<int> insertReminder(RemindersCompanion entry) =>
      into(reminders).insert(entry);

  Future<Reminder?> getById(int id) =>
      (select(reminders)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<bool> updateReminder(RemindersCompanion entry) =>
      update(reminders).replace(entry);

  Future<void> toggleEnabled(int id, bool value) =>
      (update(reminders)..where((r) => r.id.equals(id))).write(
        RemindersCompanion(isEnabled: Value(value)),
      );

  Future<int> deleteReminder(int id) =>
      (delete(reminders)..where((r) => r.id.equals(id))).go();

  /// One-shot query — all enabled reminders with future due dates.
  /// Used at app startup to reschedule notifications.
  Future<List<Reminder>> getAllEnabled() {
    final now = DateTime.now();
    return (select(reminders)
          ..where(
            (r) => r.isEnabled.equals(true) & r.dueAt.isBiggerThanValue(now),
          )
          ..orderBy([(r) => OrderingTerm.asc(r.dueAt)]))
        .get();
  }
}
