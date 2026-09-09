import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/daos/note_dao.dart';
import 'database_provider.dart';

final noteDaoProvider = Provider<NoteDao>((ref) {
  return ref.watch(databaseProvider).noteDao;
});

final allNotesProvider = StreamProvider<List<Note>>((ref) {
  return ref.watch(noteDaoProvider).watchAllNotes();
});

final notesByCategoryProvider = StreamProvider.family<List<Note>, String>((
  ref,
  category,
) {
  return ref.watch(noteDaoProvider).watchByCategory(category);
});
