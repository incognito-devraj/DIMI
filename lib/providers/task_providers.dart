import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/daos/task_dao.dart';
import 'database_provider.dart';

final taskDaoProvider = Provider<TaskDao>((ref) {
  return ref.watch(databaseProvider).taskDao;
});

/// All tasks (newest first).
final allTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskDaoProvider).watchAllTasks();
});

final allPlannerEntriesProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskDaoProvider).watchAllPlannerEntries();
});

/// Tasks due today.
final todaysTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskDaoProvider).watchTodaysTasks();
});

/// Upcoming uncompleted tasks.
final upcomingTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskDaoProvider).watchUpcomingTasks();
});

/// Completed tasks.
final completedTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskDaoProvider).watchCompletedTasks();
});

/// Tasks for any specific date (used by Planner).
final tasksForDateProvider = StreamProvider.family<List<Task>, DateTime>((
  ref,
  date,
) {
  return ref.watch(taskDaoProvider).watchTasksForDate(date);
});

/// Tasks for a full ISO week containing [monday] (Mon–Sun).
final tasksForWeekProvider = StreamProvider.family<List<Task>, DateTime>((
  ref,
  monday,
) {
  return ref.watch(taskDaoProvider).watchTasksForWeek(monday);
});
