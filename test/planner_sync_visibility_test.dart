import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dimi_app/data/database.dart';
import 'package:dimi_app/data/sync/sync_remote_api.dart';
import 'package:dimi_app/services/sync_service.dart';

class _Remote implements SyncRemoteApi {
  final rows = <String, Map<String, dynamic>>{};

  String key(String table, String id) => '$table:$id';

  @override
  Future<Map<String, dynamic>?> getRow(String table, String serverId) async =>
      rows[key(table, serverId)];

  @override
  Future<Map<String, dynamic>> insertRow(
    String table,
    Map<String, dynamic> payload,
  ) async {
    final row = {...payload, 'updated_at': '2026-09-20T10:00:00.000Z'};
    rows[key(table, payload['id'] as String)] = row;
    return row;
  }

  @override
  Future<Map<String, dynamic>?> updateRow(
    String table,
    String serverId,
    DateTime expectedUpdatedAt,
    Map<String, dynamic> payload,
  ) async {
    final existing = rows[key(table, serverId)];
    if (existing == null ||
        DateTime.parse(existing['updated_at'] as String).toUtc() !=
            expectedUpdatedAt.toUtc()) {
      return null;
    }
    final row = {
      ...existing,
      ...payload,
      'updated_at': '2026-09-20T10:01:00.000Z',
    };
    rows[key(table, serverId)] = row;
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
      userId: 'planner-sync-user',
      email: 'planner@dimi.test',
      displayName: 'Planner User',
      avatarUrl: null,
    );
    remote = _Remote();
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  tearDown(() => db.close());

  test('planner flag is serialized as boolean and survives sync refresh', () async {
    final id = await db.taskDao.insertTask(TasksCompanion.insert(
      title: 'Persistent planner event',
      category: 'Study',
      dueDate: DateTime(2026, 9, 21),
      dueTime: const Value('10:00'),
      isPlannerEntry: const Value(true),
      createdAt: DateTime(2026, 9, 20, 9),
    ));

    final service = SyncService(
      db,
      remote: remote,
      preferences: preferences,
      testContext: (
        localAccountId: db.activeAccountId,
        authUserId: 'planner-sync-user',
        generation: 0,
      ),
    );
    await service.syncNow();

    final remoteTask = remote.rows.values.firstWhere(
      (row) => row['title'] == 'Persistent planner event',
    );
    expect(remoteTask['is_planner_entry'], isTrue);

    // A stale/legacy remote payload must not hide an existing local planner
    // event during a later pull.
    remoteTask['is_planner_entry'] = false;
    remoteTask['updated_at'] = '2026-09-20T10:02:00.000Z';
    await preferences.remove('dimi_sync_cursor_1_dim_tasks');
    await service.syncNow();

    final local = await (db.select(db.tasks)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(local.isPlannerEntry, isTrue);
  });

  test('multiple planner events remain visible after sync and provider rebuild', () async {
    final eventDate = DateTime(2026, 9, 21);
    final ids = <int>[];
    for (var index = 1; index <= 3; index++) {
      ids.add(await db.taskDao.insertTask(TasksCompanion.insert(
        title: 'Planner event $index',
        category: 'Study',
        dueDate: eventDate,
        dueTime: Value('0${index}:00'),
        isPlannerEntry: const Value(true),
        createdAt: DateTime(2026, 9, 20, 9 + index),
      )));
    }

    final service = SyncService(
      db,
      remote: remote,
      preferences: preferences,
      testContext: (
        localAccountId: db.activeAccountId,
        authUserId: 'planner-sync-user',
        generation: 0,
      ),
    );
    await service.syncNow();
    await preferences.remove('dimi_sync_cursor_1_dim_tasks');
    await service.syncNow();

    final rebuiltProviderRows =
        await db.taskDao.watchTasksForDate(eventDate).first;
    expect(rebuiltProviderRows.map((task) => task.id), containsAll(ids));
    expect(rebuiltProviderRows, hasLength(3));
    for (final task in rebuiltProviderRows) {
      expect(task.localAccountId, db.activeAccountId);
      expect(task.isPlannerEntry, isTrue);
      expect(task.deletedAt, isNull);
      expect(task.dueDate.year, eventDate.year);
      expect(task.dueDate.month, eventDate.month);
      expect(task.dueDate.day, eventDate.day);
      expect(task.dueTime, isNotNull);
      expect(task.serverId, isNotNull);
    }
  });
}
