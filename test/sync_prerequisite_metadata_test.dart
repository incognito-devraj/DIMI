import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dimi_app/data/database.dart';
import 'package:dimi_app/data/daos/sync_outbox_dao.dart';

void main() {
  late AppDatabase db;
  final base = DateTime.utc(2026, 1, 1, 12);
  final mutation1 = DateTime.utc(2026, 1, 1, 12, 0, 1);
  final mutation2 = DateTime.utc(2026, 1, 1, 12, 0, 2);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.localAccountDao.ensureOfflineAccount();
  });

  tearDown(() => db.close());

  Future<int> account(String name) => db.into(db.localAccounts).insert(
        LocalAccountsCompanion.insert(
          authProvider: name,
          displayName: Value(name),
          createdAt: base,
        ),
      );

  test('create carries null remote base and local mutation version', () async {
    await db.syncOutboxDao.enqueue(
      localAccountId: db.activeAccountId,
      entityType: OutboxEntity.note,
      localRowId: 10,
      operation: OutboxOperation.create,
      localMutationAt: mutation1,
      dependencyRank: OutboxDependencyRank.note,
    );
    final row = await db.select(db.syncOutbox).getSingle();
    expect(row.baseRemoteUpdatedAt?.toUtc(), isNull);
    expect(row.updatedAt.toUtc(), mutation1);
    expect(row.serverId, isNull);
  });

  test('update preserves its first remote base across coalesced updates', () async {
    await db.syncOutboxDao.enqueue(
      localAccountId: db.activeAccountId,
      entityType: OutboxEntity.note,
      localRowId: 10,
      operation: OutboxOperation.update,
      baseRemoteUpdatedAt: base,
      localMutationAt: mutation1,
      serverId: 'note-10',
      dependencyRank: OutboxDependencyRank.note,
    );
    await db.syncOutboxDao.enqueue(
      localAccountId: db.activeAccountId,
      entityType: OutboxEntity.note,
      localRowId: 10,
      operation: OutboxOperation.update,
      baseRemoteUpdatedAt: mutation1,
      localMutationAt: mutation2,
      serverId: 'note-10',
      dependencyRank: OutboxDependencyRank.note,
    );
    final row = await db.select(db.syncOutbox).getSingle();
    expect(row.baseRemoteUpdatedAt?.toUtc(), base);
    expect(row.updatedAt.toUtc(), mutation2);
    expect(row.serverId, 'note-10');
  });

  test('tombstone keeps the original base and delete operation', () async {
    await db.syncOutboxDao.enqueue(
      localAccountId: db.activeAccountId,
      entityType: OutboxEntity.task,
      localRowId: 7,
      operation: OutboxOperation.update,
      baseRemoteUpdatedAt: base,
      localMutationAt: mutation1,
      dependencyRank: OutboxDependencyRank.task,
    );
    await db.syncOutboxDao.enqueue(
      localAccountId: db.activeAccountId,
      entityType: OutboxEntity.task,
      localRowId: 7,
      operation: OutboxOperation.delete,
      baseRemoteUpdatedAt: mutation1,
      localMutationAt: mutation2,
      dependencyRank: OutboxDependencyRank.task,
    );
    final row = await db.select(db.syncOutbox).getSingle();
    expect(row.operation, OutboxOperation.delete);
    expect(row.baseRemoteUpdatedAt?.toUtc(), base);
    expect(row.updatedAt.toUtc(), mutation2);
  });

  test('outbox account ownership remains isolated', () async {
    final second = await account('offline-test-2');
    await db.syncOutboxDao.enqueue(
      localAccountId: db.activeAccountId,
      entityType: OutboxEntity.note,
      localRowId: 1,
      operation: OutboxOperation.create,
      localMutationAt: mutation1,
      dependencyRank: OutboxDependencyRank.note,
    );
    await db.syncOutboxDao.enqueue(
      localAccountId: second,
      entityType: OutboxEntity.note,
      localRowId: 1,
      operation: OutboxOperation.create,
      localMutationAt: mutation1,
      dependencyRank: OutboxDependencyRank.note,
    );
    expect((await db.select(db.syncOutbox).get()).map((r) => r.localAccountId).toSet(),
        containsAll(<int>[db.activeAccountId, second]));
  });

  test('DAO update captures pre-mutation version and keeps it on second update', () async {
    final id = await db.noteDao.insertNote(NotesCompanion.insert(
      title: 'first',
      content: 'body',
      category: 'general',
      createdAt: base,
      updatedAt: base,
    ));
    await (db.delete(db.syncOutbox)).go();
    await db.noteDao.updateNote(NotesCompanion(
      id: Value(id),
      title: const Value('second'),
      content: const Value('body'),
      category: const Value('general'),
    ));
    var outbox = await db.select(db.syncOutbox).getSingle();
    expect(outbox.baseRemoteUpdatedAt?.toUtc(), base);
    await db.noteDao.updateNote(NotesCompanion(
      id: Value(id),
      title: const Value('third'),
      content: const Value('body'),
      category: const Value('general'),
    ));
    outbox = await db.select(db.syncOutbox).getSingle();
    expect(outbox.baseRemoteUpdatedAt?.toUtc(), base);
  });

  test('DAO tombstone captures the pre-mutation version', () async {
    final id = await db.noteDao.insertNote(NotesCompanion.insert(
      title: 'delete me',
      content: 'body',
      category: 'general',
      createdAt: base,
      updatedAt: base,
    ));
    await (db.delete(db.syncOutbox)).go();
    await db.noteDao.deleteNote(id);
    final outbox = await db.select(db.syncOutbox).getSingle();
    expect(outbox.operation, OutboxOperation.delete);
    expect(outbox.baseRemoteUpdatedAt?.toUtc(), base);
  });
}
