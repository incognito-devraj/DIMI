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
import 'tables/transaction_detection.dart';

// DAOs
import 'daos/task_dao.dart';
import 'daos/class_dao.dart';
import 'daos/study_dao.dart';
import 'daos/money_dao.dart';
import 'daos/note_dao.dart';
import 'daos/reminder_dao.dart';
import 'daos/document_dao.dart';
import 'daos/profile_dao.dart';
import 'daos/transaction_detection_dao.dart';

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
    TransactionDetectionEvents,
    TransactionCandidates,
    MerchantCategoryRules,
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
    TransactionDetectionDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Allow injecting a custom executor (e.g. in-memory DB for tests).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

  /// Removes only the original handoff/demo dataset. Real profiles are left
  /// untouched, so existing user data is not wiped on upgrade.
  Future<void> clearLegacyDemoContent() async {
    final profile = await profileDao.getProfile();
    if (profile?.name != 'Student' || profile?.email.isNotEmpty == true) {
      return;
    }
    await transaction(() async {
      await delete(tasks).go();
      await delete(classSessions).go();
      await delete(studySessions).go();
      await delete(courses).go();
      await delete(moneyTransactions).go();
      await delete(notes).go();
      await delete(reminders).go();
      await delete(documentMeta).go();
      await delete(transactionDetectionEvents).go();
      await delete(transactionCandidates).go();
      await delete(merchantCategoryRules).go();
      await delete(profileTable).go();
    });
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(tasks, tasks.completedAt);
      }
      if (from < 3) {
        await m.addColumn(tasks, tasks.isPlannerEntry);
      }
      if (from < 4) {
        await m.addColumn(tasks, tasks.plannedMinutes);
        await m.addColumn(tasks, tasks.completedMinutes);
      }
      if (from < 5) {
        await m.createTable(transactionDetectionEvents);
        await m.createTable(transactionCandidates);
        await m.createTable(merchantCategoryRules);
      }
      if (from < 6) {
        await m.addColumn(transactionCandidates, transactionCandidates.accountHint);
        await m.addColumn(transactionCandidates, transactionCandidates.paymentMethod);
        await m.addColumn(transactionCandidates, transactionCandidates.balanceAfterMinor);
      }
      if (from < 7) {
        await m.addColumn(transactionCandidates, transactionCandidates.bankConfirmationStatus);
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
