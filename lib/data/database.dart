import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/tasks.dart';
import 'tables/class_sessions.dart';
import 'tables/study_sessions.dart';
import 'tables/courses.dart';
import 'tables/transactions.dart';
import 'tables/notes.dart';
import 'tables/reminders.dart';
import 'tables/document_meta.dart';
import 'tables/profile.dart';

// DAOs
import 'daos/task_dao.dart';
import 'daos/class_dao.dart';
import 'daos/study_dao.dart';
import 'daos/money_dao.dart';
import 'daos/note_dao.dart';
import 'daos/reminder_dao.dart';
import 'daos/document_dao.dart';
import 'daos/profile_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Tasks,
    ClassSessions,
    StudySessions,
    Courses,
    MoneyTransactions,
    Notes,
    Reminders,
    DocumentMeta,
    ProfileTable,
  ],
  daos: [
    TaskDao,
    ClassDao,
    StudyDao,
    MoneyDao,
    NoteDao,
    ReminderDao,
    DocumentDao,
    ProfileDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Allow injecting a custom executor (e.g. in-memory DB for tests).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(tasks, tasks.completedAt);
      }
    },
  );
}

/// Opens the SQLite file in the app's documents directory.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'dimi.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
