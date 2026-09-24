import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dimi_app/data/database.dart';
import 'package:dimi_app/data/sync/sync_remote_api.dart';
import 'package:dimi_app/services/sync_service.dart';

class _Remote implements SyncRemoteApi {
  final rows = <String, Map<String, dynamic>>{};

  String _key(String table, String id) => '$table:$id';

  @override
  Future<Map<String, dynamic>?> getRow(String table, String serverId) async =>
      rows[_key(table, serverId)];

  @override
  Future<Map<String, dynamic>> insertRow(
    String table,
    Map<String, dynamic> payload,
  ) async {
    final row = {
      ...payload,
      'updated_at': '2026-09-23T10:00:00.123456Z',
    };
    rows[_key(table, payload['id'] as String)] = row;
    return row;
  }

  @override
  Future<Map<String, dynamic>?> updateRow(
    String table,
    String serverId,
    DateTime expectedUpdatedAt,
    Map<String, dynamic> payload,
  ) async {
    final current = rows[_key(table, serverId)];
    if (current == null ||
        DateTime.parse(current['updated_at'] as String).toUtc() !=
            expectedUpdatedAt.toUtc()) {
      return null;
    }
    final row = {
      ...current,
      ...payload,
      'updated_at': '2026-09-23T10:01:00.654321Z',
    };
    rows[_key(table, serverId)] = row;
    return row;
  }

  @override
  Future<List<Map<String, dynamic>>> pullRows(
    String table,
    String userId,
    DateTime? after,
  ) async => rows.entries
      .where((entry) => entry.key.startsWith('$table:'))
      .map((entry) => entry.value)
      .where((row) => row['user_id'] == userId)
      .toList();
}

void main() {
  late AppDatabase db;
  late _Remote remote;
  late SharedPreferences preferences;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.localAccountDao.ensureAuthenticatedAccount(
      userId: 'completion-user',
      email: 'completion@dimi.test',
      displayName: 'Completion User',
      avatarUrl: null,
    );
    remote = _Remote();
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  tearDown(() => db.close());

  SyncService service() => SyncService(
        db,
        remote: remote,
        preferences: preferences,
        testContext: (
          localAccountId: db.activeAccountId,
          authUserId: 'completion-user',
          generation: 0,
        ),
      );

  test('completing a To-Do retains it, even with an old completion date',
      () async {
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: 'Retained To-Do',
      category: 'Study',
      dueDate: DateTime(2026, 9, 23),
      createdAt: DateTime(2026, 9, 1),
    ));

    await db.taskDao.toggleCompleted(id, true);
    await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(completedAt: Value(DateTime(2020, 1, 1))),
    );

    final rows = await db.taskDao.watchAllTodos().first;
    final task = rows.singleWhere((row) => row.id == id);
    expect(task.isCompleted, isTrue);
    expect(task.deletedAt, isNull);
  });

  test('completing a Planner event retains it in its historical range',
      () async {
    final date = DateTime(2026, 9, 23);
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: 'Retained Planner Event',
      category: 'Study',
      dueDate: date,
      isPlannerEntry: const Value(true),
      createdAt: date,
    ));

    await db.taskDao.toggleCompleted(id, true);
    final rows = await db.taskDao.watchPlannerEntriesInRange(
      date.subtract(const Duration(days: 1)),
      date.add(const Duration(days: 2)),
    ).first;
    final task = rows.singleWhere((row) => row.id == id);
    expect(task.isCompleted, isTrue);
    expect(task.deletedAt, isNull);
  });

  test('completion is pushed and remains after pull without becoming a tombstone',
      () async {
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: 'Synced Completion',
      category: 'Study',
      dueDate: DateTime(2026, 9, 23),
      createdAt: DateTime(2026, 9, 23),
    ));
    await service().syncNow();
    final localBefore = await (db.select(db.tasks)..where((t) => t.id.equals(id)))
        .getSingle();
    final serverId = localBefore.serverId!;

    await db.taskDao.toggleCompleted(id, true);
    await service().syncNow();

    final remoteRow = remote.rows['dim_tasks:$serverId']!;
    expect(remoteRow['is_completed'], isTrue);
    expect(remoteRow['completed_at'], isNotNull);
    expect(remoteRow['deleted_at'], isNull);

    await preferences.remove('dimi_sync_cursor_1_dim_tasks');
    await service().syncNow();
    final localAfter = await (db.select(db.tasks)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(localAfter.isCompleted, isTrue);
    expect(localAfter.completedAt, isNotNull);
    expect(localAfter.deletedAt, isNull);

    await db.taskDao.toggleCompleted(id, false);
    await service().syncNow();
    final remoteUncompleted = remote.rows['dim_tasks:$serverId']!;
    expect(remoteUncompleted['is_completed'], isFalse);
    expect(remoteUncompleted['completed_at'], isNull);
    expect(remoteUncompleted['deleted_at'], isNull);
  });

  test('only explicit delete creates a task tombstone', () async {
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: 'Explicit Delete Only',
      category: 'Study',
      dueDate: DateTime(2026, 9, 24),
      createdAt: DateTime(2026, 9, 23),
    ));
    await db.taskDao.toggleCompleted(id, true);
    final completed = await (db.select(db.tasks)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(completed.deletedAt, isNull);

    await db.taskDao.deleteTask(id);
    final deleted = await (db.select(db.tasks)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(deleted.isCompleted, isTrue);
    expect(deleted.deletedAt, isNotNull);
  });
}
