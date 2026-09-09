import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/daos/class_dao.dart';
import 'database_provider.dart';

final classDaoProvider = Provider<ClassDao>((ref) {
  return ref.watch(databaseProvider).classDao;
});

final allClassesProvider = StreamProvider<List<ClassSession>>((ref) {
  return ref.watch(classDaoProvider).watchAllClasses();
});

/// Sessions for a specific ISO weekday. Pass 1–7.
final classesForDayProvider = StreamProvider.family<List<ClassSession>, int>((
  ref,
  dayOfWeek,
) {
  return ref.watch(classDaoProvider).watchClassesForDay(dayOfWeek);
});
