import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dimi_app/data/database.dart';
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
}
