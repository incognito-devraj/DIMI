import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const _channelPrefix = 'dimi_reminders';
  static const _channelDesc = 'DIMI reminder notifications';
  static const _soundKeyPrefix = 'dimi_reminder_sound_';

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    // Initialise timezone data.
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Request POST_NOTIFICATIONS permission on Android 13+.
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
      await androidPlugin.requestFullScreenIntentPermission();
    }

    _ready = true;
    if (kDebugMode) debugPrint('[NotificationService] initialised');
  }

  /// Re-opens Android's notification, exact-alarm, and full-screen permission
  /// prompts from Settings when the user previously dismissed one.
  Future<void> requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;
    await androidPlugin.requestNotificationsPermission();
    await androidPlugin.requestExactAlarmsPermission();
    await androidPlugin.requestFullScreenIntentPermission();
  }

  // ── Schedule ─────────────────────────────────────────────────────────────

  /// Schedules an exact notification for [reminder].
  /// Safe to call even if the due date is in the past — it skips silently.
  Future<void> scheduleReminder(Reminder reminder) async {
    if (!_ready || !reminder.isEnabled) return;
    if (reminder.dueAt.isBefore(DateTime.now())) return;

    final sound = await _soundForReminder(reminder.id);
    await _schedule(
      reminder.id,
      reminder.title,
      tz.TZDateTime.from(reminder.dueAt, tz.local),
      sound,
    );

    if (kDebugMode) {
      debugPrint(
        '[NotificationService] scheduled #${reminder.id} '
        '"${reminder.title}" at ${reminder.dueAt}',
      );
    }
  }

  Future<void> _schedule(
    int id,
    String title,
    tz.TZDateTime scheduled,
    String sound,
  ) async {
    await _plugin.zonedSchedule(
      id,
      'DIMI Reminder',
      title,
      scheduled,
      NotificationDetails(android: _androidDetails(sound)),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'title': title, 'sound': sound}),
    );
  }

  AndroidNotificationDetails _androidDetails(String sound) {
    final channelId = '${_channelPrefix}_$sound';
    final channelName = switch (sound) {
      'ringtone' => 'Reminders · Phone ringtone',
      'alarm' => 'Reminders · Alarm tone',
      _ => 'Reminders · Default sound',
    };
    final soundUri = switch (sound) {
      'ringtone' => const UriAndroidNotificationSound(
          'content://settings/system/ringtone',
        ),
      'alarm' => const UriAndroidNotificationSound(
          'content://settings/system/alarm_alert',
        ),
      _ => null,
    };

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      sound: soundUri,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      actions: [
        const AndroidNotificationAction(
          'snooze_5',
          'Snooze 5 min',
          showsUserInterface: false,
        ),
      ],
    );
  }

  Future<String> _soundForReminder(int id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_soundKeyPrefix$id') ?? 'default';
  }

  Future<void> setReminderSound(int id, String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_soundKeyPrefix$id', sound);
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    if (response.actionId != 'snooze_5' || response.id == null) return;

    final data = response.payload == null
        ? const <String, dynamic>{}
        : jsonDecode(response.payload!) as Map<String, dynamic>;
    await _plugin.cancel(response.id!);
    await _schedule(
      response.id!,
      data['title'] as String? ?? 'Reminder',
      tz.TZDateTime.now(tz.local).add(const Duration(minutes: 5)),
      data['sound'] as String? ?? 'default',
    );
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
