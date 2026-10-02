import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dimi_app/data/database.dart';
import 'package:dimi_app/data/sync/sync_remote_api.dart';
import 'package:dimi_app/services/sync_service.dart';

void main() {
  test('offline sync with an empty outbox is a safe no-op', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.localAccountDao.ensureOfflineAccount();
    final service = SyncService(db);
    await Future.wait([service.syncNow(), service.syncNow()]);
    expect(await db.syncOutboxDao.pendingCount(db.activeAccountId), 0);
    await db.close();
  });

  test(
    'remote task and finance rows hydrate Drift and notify streams',
    () async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.localAccountDao.ensureOfflineAccount();
      final accountId = db.activeAccountId;
      final changedTask = db.taskDao.watchAllTodos().skip(1).first;
      final changedFinance = db.moneyDao.watchAllTransactions().skip(1).first;

      final now = '2026-01-01T00:00:00.000Z';
      final service = SyncService(
        db,
        remote: _HydrationRemote({
          'dim_tasks': [
            {
              'id': 'remote-task-1',
              'user_id': 'user-1',
              'title': 'Hydrated task',
              'description': null,
              'category': 'Personal',
              'is_planner_entry': false,
              'local_date': '2026-01-02',
              'due_time_hhmm': null,
              'is_completed': false,
              'completed_at': null,
              'created_at': now,
              'updated_at': now,
              'deleted_at': null,
            },
          ],
          'dim_money_transactions': [
            {
              'id': 'remote-money-1',
              'user_id': 'user-1',
              'type': 'expense',
              'amount_minor': 2500,
              'currency': 'INR',
              'category': 'Food',
              'note': null,
              'counterparty': null,
              'occurred_on': '2026-01-01',
              'source': 'manual',
              'created_at': now,
              'updated_at': now,
              'deleted_at': null,
            },
          ],
          'dim_reminders': [
            {
              'id': 'remote-reminder-1',
              'user_id': 'user-1',
              'task_id': null,
              'title': 'Remote reminder one',
              'due_at': now,
              'is_enabled': true,
              'created_at': now,
              'updated_at': now,
              'deleted_at': null,
            },
            {
              'id': 'remote-reminder-2',
              'user_id': 'user-1',
              'task_id': null,
              'title': 'Remote reminder two',
              'due_at': now,
              'is_enabled': true,
              'created_at': now,
              'updated_at': now,
              'deleted_at': null,
            },
          ],
        }),
        preferences: await SharedPreferences.getInstance(),
        testContext: (
          localAccountId: accountId,
          authUserId: 'user-1',
          generation: 0,
        ),
      );

      await service.syncNow();

      expect((await changedTask).single.title, 'Hydrated task');
      expect((await changedFinance).single.amount, 2500);
      expect(await db.select(db.reminders).get(), hasLength(2));
      expect(
        (await db.taskDao.watchAllTodos().first).single.localAccountId,
        accountId,
      );
      expect(
        (await db.moneyDao.watchAllTransactions().first).single.localAccountId,
        accountId,
      );
      await db.close();
    },
  );
}

class _HydrationRemote implements SyncRemoteApi {
  _HydrationRemote(this.rowsByTable);

  final Map<String, List<Map<String, dynamic>>> rowsByTable;

  @override
  Future<Map<String, dynamic>?> getRow(String table, String serverId) async =>
      null;

  @override
  Future<Map<String, dynamic>> insertRow(
    String table,
    Map<String, dynamic> payload,
  ) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> updateRow(
    String table,
    String serverId,
    DateTime expectedUpdatedAt,
    Map<String, dynamic> payload,
  ) async => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> pullRows(
    String table,
    String userId,
    DateTime? after,
  ) async => rowsByTable[table] ?? const [];
}
