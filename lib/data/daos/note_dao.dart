import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/notes.dart';
import 'sync_outbox_dao.dart';

part 'note_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(super.db);

  Stream<List<Note>> watchAllNotes() =>
      (select(notes)
            ..where((n) => n.localAccountId.equals(db.activeAccountId) & n.deletedAt.isNull())
            ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
          .watch();

  Future<int> insertNote(NotesCompanion entry) async {
    final id = await into(notes).insert(entry.copyWith(localAccountId: Value(db.activeAccountId)));
    final row = await (select(notes)..where((n) => n.id.equals(id))).getSingle();
    await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.note, localRowId: id, operation: OutboxOperation.create, serverId: row.serverId, dependencyRank: OutboxDependencyRank.note);
    return id;
  }

  Future<int> countNotes() async => (await (select(
    notes,
  )..where((n) => n.localAccountId.equals(db.activeAccountId) & n.deletedAt.isNull())).get()).length;

  Future<bool> updateNote(NotesCompanion entry) async {
    final before = await (select(notes)..where((n) => n.id.equals(entry.id.value) & n.localAccountId.equals(db.activeAccountId) & n.deletedAt.isNull())).getSingleOrNull();
    if (before == null) return false;
    final changed = await (update(notes)..where((n) => n.id.equals(entry.id.value) & n.localAccountId.equals(db.activeAccountId) & n.deletedAt.isNull()))
        .write(entry.copyWith(localAccountId: Value(db.activeAccountId), updatedAt: Value(DateTime.now()))) > 0;
    if (changed) {
      final row = await (select(notes)..where((n) => n.id.equals(entry.id.value))).getSingle();
      await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.note, localRowId: row.id, operation: OutboxOperation.update, serverId: row.serverId, baseRemoteUpdatedAt: before.updatedAt, localMutationAt: row.updatedAt, dependencyRank: OutboxDependencyRank.note);
    }
    return changed;
  }

  Future<int> deleteNote(int id) async {
    final before = await (select(notes)..where((n) => n.id.equals(id) & n.localAccountId.equals(db.activeAccountId) & n.deletedAt.isNull())).getSingleOrNull();
    if (before == null) return 0;
    final changed = await (update(notes)..where(
            (n) =>
                n.id.equals(id) & n.localAccountId.equals(db.activeAccountId) & n.deletedAt.isNull(),
          ))
          .write(NotesCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));
    if (changed > 0) {
      final row = await (select(notes)..where((n) => n.id.equals(id))).getSingle();
      await db.syncOutboxDao.enqueue(localAccountId: db.activeAccountId, entityType: OutboxEntity.note, localRowId: id, operation: OutboxOperation.delete, serverId: row.serverId, baseRemoteUpdatedAt: before.updatedAt, localMutationAt: row.updatedAt, dependencyRank: OutboxDependencyRank.note);
    }
    return changed;
  }
}
