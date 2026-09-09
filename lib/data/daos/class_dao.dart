import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/class_sessions.dart';

part 'class_dao.g.dart';

@DriftAccessor(tables: [ClassSessions])
class ClassDao extends DatabaseAccessor<AppDatabase> with _$ClassDaoMixin {
  ClassDao(super.db);

  // ── Streams ────────────────────────────────────────────────────────────────

  /// All class sessions, ordered by day then start time.
  Stream<List<ClassSession>> watchAllClasses() =>
      (select(classSessions)..orderBy([
            (c) => OrderingTerm.asc(c.dayOfWeek),
            (c) => OrderingTerm.asc(c.startTime),
          ]))
          .watch();

  /// Sessions for a specific ISO weekday (1=Mon … 7=Sun).
  Stream<List<ClassSession>> watchClassesForDay(int dayOfWeek) =>
      (select(classSessions)
            ..where((c) => c.dayOfWeek.equals(dayOfWeek))
            ..orderBy([(c) => OrderingTerm.asc(c.startTime)]))
          .watch();

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<int> insertClass(ClassSessionsCompanion entry) =>
      into(classSessions).insert(entry);

  Future<bool> updateClass(ClassSessionsCompanion entry) =>
      update(classSessions).replace(entry);

  Future<int> deleteClass(int id) =>
      (delete(classSessions)..where((c) => c.id.equals(id))).go();
}
