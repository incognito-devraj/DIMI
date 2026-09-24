import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/daos/task_dao.dart';
import 'database_provider.dart';
import 'local_account_provider.dart';

final taskDaoProvider = Provider<TaskDao>((ref) {
  ref.watch(activeAccountIdProvider);
  return ref.watch(databaseProvider).taskDao;
});

/// All tasks (newest first).
final allTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskDaoProvider).watchAllTasks();
});

final allTodosProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskDaoProvider).watchAllTodos();
});

final homeTodosProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskDaoProvider).watchHomeTodos();
});

/// Planner rows needed by the 12-month activity heatmap only.
final plannerHeatmapProvider = StreamProvider<List<Task>>((ref) {
  final today = DateTime.now();
  final end = DateTime(today.year, today.month, today.day).add(const Duration(days: 1));
  final start = DateTime(today.year, today.month - 11, 1);
  return ref.watch(taskDaoProvider).watchPlannerEntriesInRange(start, end);
});

/// Planner events for the displayed calendar month, including future dates.
final plannerTasksForMonthProvider =
    StreamProvider.family<List<Task>, DateTime>((ref, month) {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 1);
  return ref.watch(taskDaoProvider).watchPlannerEntriesInRange(start, end);
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
