import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dimi_app/data/database.dart';
import 'package:dimi_app/data/daos/sync_outbox_dao.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.localAccountDao.ensureOfflineAccount();
  });

  tearDown(() => db.close());

  test('same-day planner events can be completed', () async {
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: 'Same-day planner event',
      category: 'Study',
      dueDate: DateTime.now(),
      isPlannerEntry: const Value(true),
      createdAt: DateTime.now(),
    ));

    await db.taskDao.toggleCompleted(id, true);

    final task = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();
    final outbox = await (db.select(db.syncOutbox)
          ..where((o) => o.localRowId.equals(id) & o.entityType.equals(OutboxEntity.task)))
        .getSingle();
    expect(task.isCompleted, isTrue);
    expect(task.completedAt, isNotNull);
    // A create followed by an offline completion remains coalesced as create.
    expect(outbox.operation, OutboxOperation.create);
    expect(outbox.state, OutboxState.pending);
  });

  test('past planner events cannot be completed or deleted', () async {
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: 'Past planner event',
      category: 'Study',
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      isPlannerEntry: const Value(true),
      createdAt: DateTime.now(),
    ));

    await db.taskDao.toggleCompleted(id, true);
    expect(await db.taskDao.deleteTask(id), 0);

    final task = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(task.isCompleted, isFalse);
    expect(task.deletedAt, isNull);
  });

  test('planner completion remains available to the local heatmap query', () async {
    final date = DateTime.now();
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: 'Heatmap event',
      category: 'Study',
      dueDate: date,
      isPlannerEntry: const Value(true),
      createdAt: DateTime.now(),
    ));
    await db.taskDao.toggleCompleted(id, true);
    final rows = await db.taskDao.watchPlannerEntriesInRange(
      date.subtract(const Duration(days: 1)),
      date.add(const Duration(days: 1)),
    ).first;
    final row = rows.singleWhere((task) => task.id == id);
    expect(row.isCompleted, isTrue);
    expect(row.completedAt, isNotNull);
  });

  test('future planner events remain visible in the planner week range', () async {
    final future = DateTime.now().add(const Duration(days: 3));
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: 'Future planner event',
      category: 'Study',
      dueDate: future,
      isPlannerEntry: const Value(true),
      createdAt: DateTime.now(),
    ));
    final monday = future.subtract(Duration(days: future.weekday - 1));

    final rows = await db.taskDao.watchTasksForWeek(monday).first;
    expect(rows.any((task) => task.id == id), isTrue);
  });

  test('same-day planner delete remains a tombstone and queues a delete', () async {
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: 'Delete planner event',
      category: 'Study',
      dueDate: DateTime.now(),
      isPlannerEntry: const Value(true),
      createdAt: DateTime.now(),
    ));

    expect(await db.taskDao.deleteTask(id), 1);

    final task = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();
    final outbox = await (db.select(db.syncOutbox)
          ..where((o) => o.localRowId.equals(id) & o.entityType.equals(OutboxEntity.task)))
        .getSingle();
    expect(task.deletedAt, isNotNull);
    expect(outbox.operation, OutboxOperation.delete);
    expect(outbox.state, OutboxState.pending);
  });

  test('past standard and event reminders expire, playlist reminders remain', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final standardId = await db.reminderDao.insertReminder(
      RemindersCompanion.insert(
        title: 'Call someone',
        dueAt: yesterday,
        notificationId: const Value(101),
        createdAt: Value(yesterday),
        updatedAt: Value(yesterday),
      ),
    );
    final eventId = await db.reminderDao.insertReminder(
      RemindersCompanion.insert(
        title: 'Event reminder',
        dueAt: yesterday,
        notificationId: const Value(102),
        createdAt: Value(yesterday),
        updatedAt: Value(yesterday),
      ),
    );
    final playlistId = await db.reminderDao.insertReminder(
      RemindersCompanion.insert(
        title: 'Watch: Algorithms',
        dueAt: yesterday,
        notificationId: const Value(103),
        createdAt: Value(yesterday),
        updatedAt: Value(yesterday),
      ),
    );

    final expired = await db.reminderDao.expirePastStandardReminders();
    expect(expired, containsAll(<int>[101, 102]));

    final standard = await (db.select(db.reminders)..where((r) => r.id.equals(standardId))).getSingle();
    final event = await (db.select(db.reminders)..where((r) => r.id.equals(eventId))).getSingle();
    final playlist = await (db.select(db.reminders)..where((r) => r.id.equals(playlistId))).getSingle();
    expect(standard.deletedAt, isNotNull);
    expect(event.deletedAt, isNotNull);
    expect(playlist.deletedAt, isNull);
  });
}
