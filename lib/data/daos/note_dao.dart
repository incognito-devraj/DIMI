import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/notes.dart';

part 'note_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(super.db);

  // ── Streams ────────────────────────────────────────────────────────────────

  /// All notes, most recently updated first.
  Stream<List<Note>> watchAllNotes() =>
      (select(notes)..orderBy([(n) => OrderingTerm.desc(n.updatedAt)])).watch();

  /// Notes filtered by category.
  Stream<List<Note>> watchByCategory(String category) =>
      (select(notes)
            ..where((n) => n.category.equals(category))
            ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
          .watch();

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<int> insertNote(NotesCompanion entry) => into(notes).insert(entry);

  Future<bool> updateNote(NotesCompanion entry) => update(notes).replace(entry);

  Future<int> deleteNote(int id) =>
      (delete(notes)..where((n) => n.id.equals(id))).go();
}
