import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/daos/study_dao.dart';
import 'database_provider.dart';

final studyDaoProvider = Provider<StudyDao>((ref) {
  return ref.watch(databaseProvider).studyDao;
});

final allCoursesProvider = StreamProvider<List<Course>>((ref) {
  return ref.watch(studyDaoProvider).watchAllCourses();
});

final allStudySessionsProvider = StreamProvider<List<StudySession>>((ref) {
  return ref.watch(studyDaoProvider).watchAllStudySessions();
});

final thisWeeksStudySessionsProvider = StreamProvider<List<StudySession>>((
  ref,
) {
  return ref.watch(studyDaoProvider).watchThisWeeksSessions();
});
