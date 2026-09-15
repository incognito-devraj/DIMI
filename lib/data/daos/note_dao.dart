import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/notes.dart';

@DriftAccessor(tables: [Notes])
class NoteDao extends DatabaseAccessor<AppDatabase> {
  NoteDao(super.db);

  Stream<List<Note>> watchAllNotes() =>
      (select(attachedDatabase.notes)
            ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
          .watch();

  Future<int> insertNote(NotesCompanion entry) =>
      into(attachedDatabase.notes).insert(entry);

  Future<int> countNotes() async =>
      (await select(attachedDatabase.notes).get()).length;

  Future<bool> updateNote(NotesCompanion entry) =>
      update(attachedDatabase.notes).replace(entry);

  Future<int> deleteNote(int id) =>
      (delete(attachedDatabase.notes)..where((n) => n.id.equals(id))).go();
}
