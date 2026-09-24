import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/daos/note_dao.dart';
import 'database_provider.dart';
import 'local_account_provider.dart';

final noteDaoProvider = Provider<NoteDao>((ref) {
  ref.watch(activeAccountIdProvider);
  return NoteDao(ref.watch(databaseProvider));
});

final allNotesProvider = StreamProvider<List<Note>>((ref) {
  return ref.watch(noteDaoProvider).watchAllNotes();
});
