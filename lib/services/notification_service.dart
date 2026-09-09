import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/database.dart';

/// Handles scheduling and cancelling local Android notifications for Reminders.
/// Call [init] once at app startup before [runApp].
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  // ── Android notification channel ─────────────────────────────────────────

  static const _channelId = 'dimi_reminders';
  static const _channelName = 'Reminders';
  static const _channelDesc = 'DIMI reminder notifications';

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

  static const NotificationDetails _notifDetails = NotificationDetails(
    android: _androidDetails,
  );

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    // Initialise timezone data.
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    // Request POST_NOTIFICATIONS permission on Android 13+.
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    _ready = true;
    if (kDebugMode) debugPrint('[NotificationService] initialised');
  }

  // ── Schedule ─────────────────────────────────────────────────────────────

  /// Schedules an exact notification for [reminder].
  /// Safe to call even if the due date is in the past — it skips silently.
  Future<void> scheduleReminder(Reminder reminder) async {
    if (!_ready || !reminder.isEnabled) return;
    if (reminder.dueAt.isBefore(DateTime.now())) return;

    final scheduled = tz.TZDateTime.from(reminder.dueAt, tz.local);

    await _plugin.zonedSchedule(
      reminder.id,
      'DIMI Reminder',
      reminder.title,
      scheduled,
      _notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    if (kDebugMode) {
      debugPrint(
        '[NotificationService] scheduled #${reminder.id} '
        '"${reminder.title}" at ${reminder.dueAt}',
      );
    }
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancelReminder(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id);
    if (kDebugMode) debugPrint('[NotificationService] cancelled #$id');
  }

  // ── Reschedule all ────────────────────────────────────────────────────────

  /// Called on app start and after device reboot. Schedules all enabled
  /// future reminders. Already-fired ones are skipped by [scheduleReminder].
  Future<void> rescheduleAll(List<Reminder> reminders) async {
    if (!_ready) return;
    // Cancel everything first to avoid duplicates.
    await _plugin.cancelAll();
    for (final r in reminders) {
      await scheduleReminder(r);
    }
    if (kDebugMode) {
      debugPrint(
        '[NotificationService] rescheduled ${reminders.length} '
        'reminders',
      );
    }
  }
}
