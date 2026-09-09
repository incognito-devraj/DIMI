import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/daos/reminder_dao.dart';
import 'database_provider.dart';

final reminderDaoProvider = Provider<ReminderDao>((ref) {
  return ref.watch(databaseProvider).reminderDao;
});

final allRemindersProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(reminderDaoProvider).watchAllReminders();
});

final todaysRemindersProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(reminderDaoProvider).watchTodaysReminders();
});

final upcomingRemindersProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(reminderDaoProvider).watchUpcomingReminders();
});
