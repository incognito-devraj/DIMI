import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/study_sessions.dart';
import '../tables/courses.dart';

part 'study_dao.g.dart';

@DriftAccessor(tables: [StudySessions, Courses])
class StudyDao extends DatabaseAccessor<AppDatabase> with _$StudyDaoMixin {
  StudyDao(super.db);

  // ── Streams — Study Sessions ───────────────────────────────────────────────

  Stream<List<StudySession>> watchAllStudySessions() => (select(
    studySessions,
  )..orderBy([(s) => OrderingTerm.desc(s.startedAt)])).watch();

  /// Sessions started within the current ISO week (Mon–Sun).
  Stream<List<StudySession>> watchThisWeeksSessions() {
    final now = DateTime.now();
    final mon = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(mon.year, mon.month, mon.day);
    final weekEnd = weekStart.add(const Duration(days: 7));
    return (select(studySessions)
          ..where((s) => s.startedAt.isBetweenValues(weekStart, weekEnd))
          ..orderBy([(s) => OrderingTerm.asc(s.startedAt)]))
        .watch();
  }

  // ── Streams — Courses ──────────────────────────────────────────────────────

  Stream<List<Course>> watchAllCourses() =>
      (select(courses)..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Inserts a completed study session and updates the course's running total.
  Future<void> logSession(StudySessionsCompanion session) async {
    await into(studySessions).insert(session);

    // Update denormalized total on the matching course (if it exists).
    final courseName = session.courseName.value;
    final existing = await (select(
      courses,
    )..where((c) => c.name.equals(courseName))).getSingleOrNull();

    if (existing != null) {
      await (update(courses)..where((c) => c.name.equals(courseName))).write(
        CoursesCompanion(
          totalLoggedMinutes: Value(
            existing.totalLoggedMinutes + session.durationMinutes.value,
          ),
        ),
      );
    }
  }

  Future<int> insertCourse(CoursesCompanion entry) =>
      into(courses).insert(entry);

  Future<bool> updateCourse(CoursesCompanion entry) =>
      update(courses).replace(entry);

  Future<int> deleteCourse(int id) =>
      (delete(courses)..where((c) => c.id.equals(id))).go();

  Future<int> deleteSession(int id) =>
      (delete(studySessions)..where((s) => s.id.equals(id))).go();
}
