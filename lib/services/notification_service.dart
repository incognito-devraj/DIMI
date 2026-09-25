import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/database.dart';

// ─── Notification icon ───────────────────────────────────────────────────────
// Small status-bar icon must be a monochrome (white/transparent) PNG.
// We reference the drawable we copied from assets/logos/notification.png.
// If that drawable is not yet a valid monochrome asset, Android silently
// replaces it — this constant makes it easy to change in one place.
const _kNotifIcon = '@drawable/dimi_status_icon';

// ─────────────────────────────────────────────────────────────────────────────
// Notification type
// ─────────────────────────────────────────────────────────────────────────────

/// Determines which action buttons and icon badge a notification gets.
enum DimiNotificationType {
  /// A standard timed reminder (planner event, class, general).
  reminder,

  /// Remind the user to continue watching a YouTube playlist.
  playlist,

  /// Remind the user to complete a specific To-Do task.
  todo,

  /// Remind the user to watch/read a linked video or note.
  watch,

  /// Internal: the snooze-picker notification shown after tapping Snooze.
  snoozePicker,
}

// ─────────────────────────────────────────────────────────────────────────────
// Action ID constants (must be stable — they survive process death)
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _Action {
  static const markDone = 'dimi_mark_done';
  static const openPlaylist = 'dimi_open_playlist';
  static const open = 'dimi_open';
  static const snooze = 'dimi_snooze'; // shows picker
  static const snooze5 = 'dimi_snooze_5';
  static const snooze10 = 'dimi_snooze_10';
  static const snooze30 = 'dimi_snooze_30';
  static const snooze60 = 'dimi_snooze_60';
  static const snoozeTomorrow = 'dimi_snooze_tomorrow';
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification channels
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _Channel {
  static const reminderId = 'dimi_reminders';
  static const playlistId = 'dimi_playlist';
  static const todoId = 'dimi_todo';
  static const watchId = 'dimi_watch';
  static const snoozePicker = 'dimi_snooze_picker';
}

// ─────────────────────────────────────────────────────────────────────────────
// Payload keys
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _Key {
  static const type = 'type';
  static const title = 'title';
  static const body = 'body';
  static const sound = 'sound';
  static const reminderId = 'reminder_id';
  static const taskId = 'task_id';
  static const playlistId = 'playlist_id';
  static const origId = 'orig_id'; // for snooze: original notification id
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────────────────────

/// Handles scheduling and cancelling local Android notifications.
/// Call [init] once at app startup before [runApp].
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  // Injected DB reference so action callbacks can write completions.
  AppDatabase? _db;

  void attachDatabase(AppDatabase db) => _db = db;

  // ── Snooze-picker notification ID offset ───────────────────────────────
  // We show the picker as a new notification whose id = original id + offset.
  static const _snoozePickerOffset = 100000;

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    tz.initializeTimeZones();

    // Use the new DIMI notification icon for the small status-bar icon.
    // The small icon MUST be a monochrome/white alpha-only drawable on
    // Android 5+ — notification.png should be prepared as such.
    const androidInit = AndroidInitializationSettings(_kNotifIcon);

    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: _handleResponseBackground,
    );

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

  Future<void> requestPermissions() async {
    final ap = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (ap == null) return;
    await ap.requestNotificationsPermission();
    await ap.requestExactAlarmsPermission();
    await ap.requestFullScreenIntentPermission();
  }

  // ── Public schedule helpers ───────────────────────────────────────────────

  /// Schedules a standard reminder notification.
  Future<void> scheduleReminder(Reminder reminder) async {
    if (!_ready || !reminder.isEnabled) return;
    if (reminder.dueAt.isBefore(DateTime.now())) return;

    final sound = await _soundForReminder(reminder.id);
    final type = _typeForReminder(reminder.title);
    final notificationTitle = _notificationTitleForReminder(reminder.title);
    final detail = _detailFromReminderTitle(reminder.title);
    final payload = _buildPayload(
      type: type,
      title: notificationTitle,
      body: detail,
      sound: sound,
      reminderId: reminder.id,
      taskId: reminder.taskId,
    );

    await _scheduleAt(
      id: reminder.notificationId,
      title: notificationTitle,
      body: detail,
      scheduled: tz.TZDateTime.from(reminder.dueAt, tz.local),
      details: _buildDetails(
        type: type,
        sound: sound,
        bigText: _bigTextForReminder(
          type: type,
          title: notificationTitle,
          detail: detail,
        ),
      ),
      payload: payload,
    );
  }

  /// Schedules a playlist watch-reminder notification.
  Future<void> schedulePlaylistReminder({
    required int notificationId,
    required String playlistTitle,
    required int unwatchedCount,
    required DateTime dueAt,
    required int playlistLocalId,
  }) async {
    if (!_ready) return;
    if (dueAt.isBefore(DateTime.now())) return;

    final payload = _buildPayload(
      type: DimiNotificationType.playlist,
      title: 'Continue Watching',
      body:
          '$playlistTitle • $unwatchedCount unwatched video${unwatchedCount == 1 ? '' : 's'}',
      playlistId: playlistLocalId,
    );

    await _scheduleAt(
      id: notificationId,
      title: 'Continue Watching',
      body:
          '$playlistTitle • $unwatchedCount unwatched video${unwatchedCount == 1 ? '' : 's'}',
      scheduled: tz.TZDateTime.from(dueAt, tz.local),
      details: _buildDetails(
        type: DimiNotificationType.playlist,
        bigText:
            'You have $unwatchedCount unwatched videos in "$playlistTitle". Keep the momentum going! 🎯',
      ),
      payload: payload,
    );
  }

  /// Schedules a to-do completion reminder.
  Future<void> scheduleTodoReminder({
    required int notificationId,
    required String taskTitle,
    required String detail, // e.g. "You planned 2 problems today"
    required DateTime dueAt,
    int? taskId,
  }) async {
    if (!_ready) return;
    if (dueAt.isBefore(DateTime.now())) return;

    final payload = _buildPayload(
      type: DimiNotificationType.todo,
      title: taskTitle,
      body: detail,
      taskId: taskId,
    );

    await _scheduleAt(
      id: notificationId,
      title: taskTitle,
      body: detail,
      scheduled: tz.TZDateTime.from(dueAt, tz.local),
      details: _buildDetails(
        type: DimiNotificationType.todo,
        bigText: '$taskTitle\n$detail',
      ),
      payload: payload,
    );
  }

  /// Schedules a watch/remember reminder.
  Future<void> scheduleWatchReminder({
    required int notificationId,
    required String contentTitle,
    required DateTime dueAt,
    int? taskId,
    int? playlistId,
  }) async {
    if (!_ready) return;
    if (dueAt.isBefore(DateTime.now())) return;

    final payload = _buildPayload(
      type: DimiNotificationType.watch,
      title: 'Remember to Watch',
      body: contentTitle,
      taskId: taskId,
      playlistId: playlistId,
    );

    await _scheduleAt(
      id: notificationId,
      title: 'Remember to Watch',
      body: contentTitle,
      scheduled: tz.TZDateTime.from(dueAt, tz.local),
      details: _buildDetails(
        type: DimiNotificationType.watch,
        bigText:
            'You wanted to watch/read:\n"$contentTitle"\n\nTap Open to get started 📺',
      ),
      payload: payload,
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancelReminder(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id);
    await _plugin.cancel(id + _snoozePickerOffset);
  }

  Future<void> rescheduleAll(List<Reminder> reminders) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    for (final r in reminders) {
      await scheduleReminder(r);
    }
  }

  Future<void> setReminderSound(int id, String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dimi_reminder_sound_$id', sound);
  }

  // ── Action response handler ───────────────────────────────────────────────

  Future<void> _handleResponse(NotificationResponse response) async {
    await _processAction(response);
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<void> _processAction(NotificationResponse response) async {
    final id = response.id;
    final actionId = response.actionId;
    if (id == null) return;

    final data = response.payload == null
        ? const <String, dynamic>{}
        : jsonDecode(response.payload!) as Map<String, dynamic>;

    switch (actionId) {
      // ── Mark done ────────────────────────────────────────────────────────
      case _Action.markDone:
        await _plugin.cancel(id);
        await _plugin.cancel(id + _snoozePickerOffset);
        final taskId = data[_Key.taskId] as int?;
        if (taskId != null && _db != null) {
          await _db!.taskDao.toggleCompleted(taskId, true);
        }
        final reminderId = data[_Key.reminderId] as int?;
        if (reminderId != null && _db != null) {
          await _db!.reminderDao.toggleEnabled(reminderId, false);
        }

      // ── Open / Open Playlist ─────────────────────────────────────────────
      case _Action.openPlaylist:
      case _Action.open:
        await _plugin.cancel(id);
      // Deep-link handled by go_router — we just dismiss the notification.
      // The notification tap (null actionId) also reaches here if the user
      // taps the body; the router's initialLocation handles routing.

      // ── Snooze (show picker) ─────────────────────────────────────────────
      case _Action.snooze:
        await _plugin.cancel(id);
        await _showSnoozePicker(
          pickerId: id + _snoozePickerOffset,
          origId: id,
          origPayload: response.payload ?? '{}',
          origTitle: data[_Key.title] as String? ?? 'Reminder',
        );

      // ── Snooze durations ─────────────────────────────────────────────────
      case _Action.snooze5:
      case _Action.snooze10:
      case _Action.snooze30:
      case _Action.snooze60:
      case _Action.snoozeTomorrow:
        await _plugin.cancel(id); // dismiss picker
        final snoozeMin = _snoozeMinutes(actionId!);
        final origId = data[_Key.origId] as int? ?? (id - _snoozePickerOffset);
        final origPayload = data['orig_payload'] as String? ?? '{}';
        final origData = jsonDecode(origPayload) as Map<String, dynamic>;
        final type = DimiNotificationType.values.firstWhere(
          (t) => t.name == (origData[_Key.type] as String? ?? 'reminder'),
          orElse: () => DimiNotificationType.reminder,
        );
        final sound = origData[_Key.sound] as String? ?? 'default';
        final dueAt = actionId == _Action.snoozeTomorrow
            ? _tomorrowMorning()
            : tz.TZDateTime.now(tz.local).add(Duration(minutes: snoozeMin));

        await _scheduleAt(
          id: origId,
          title: origData[_Key.title] as String? ?? 'Reminder',
          body: origData[_Key.body] as String? ?? '',
          scheduled: dueAt,
          details: _buildDetails(type: type, sound: sound),
          payload: origPayload,
        );
    }
  }

  /// Shows a snooze-picker notification listing all snooze options as actions.
  Future<void> _showSnoozePicker({
    required int pickerId,
    required int origId,
    required String origPayload,
    required String origTitle,
  }) async {
    final pickerPayload = jsonEncode({
      _Key.type: DimiNotificationType.snoozePicker.name,
      _Key.origId: origId,
      'orig_payload': origPayload,
    });

    await _plugin.show(
      pickerId,
      'Snooze "$origTitle"',
      'Choose how long to snooze',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _Channel.snoozePicker,
          'Snooze Options',
          channelDescription: 'Snooze duration picker for DIMI reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: _kNotifIcon,
          color: const Color(0xFFF5A623),
          category: AndroidNotificationCategory.reminder,
          autoCancel: true,
          actions: const [
            AndroidNotificationAction(
              _Action.snooze5,
              'Snooze 5 min',
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              _Action.snooze10,
              'Snooze 10 min',
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              _Action.snooze30,
              'Snooze 30 min',
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              _Action.snooze60,
              'Snooze 1 hour',
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              _Action.snoozeTomorrow,
              'Tomorrow 8 AM',
              showsUserInterface: false,
            ),
          ],
        ),
      ),
      payload: pickerPayload,
    );
  }

  // ── Build notification details per type ───────────────────────────────────

  AndroidNotificationDetails _buildDetails({
    required DimiNotificationType type,
    String sound = 'default',
    String? bigText,
  }) {
    final channelId = switch (type) {
      DimiNotificationType.reminder => _Channel.reminderId,
      DimiNotificationType.playlist => _Channel.playlistId,
      DimiNotificationType.todo => _Channel.todoId,
      DimiNotificationType.watch => _Channel.watchId,
      DimiNotificationType.snoozePicker => _Channel.snoozePicker,
    };
    final channelName = switch (type) {
      DimiNotificationType.reminder => 'Reminders',
      DimiNotificationType.playlist => 'Playlist Reminders',
      DimiNotificationType.todo => 'To-Do Reminders',
      DimiNotificationType.watch => 'Watch Reminders',
      DimiNotificationType.snoozePicker => 'Snooze Options',
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

    final actions = _actionsFor(type);

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'DIMI $channelName',
      importance: Importance.max,
      priority: Priority.max,
      icon: _kNotifIcon,
      // DIMI amber accent shown in the notification shade on supported OEMs
      color: switch (type) {
        DimiNotificationType.playlist => const Color(0xFFE53935),
        DimiNotificationType.todo => const Color(0xFF43A047),
        DimiNotificationType.watch => const Color(0xFF7E57C2),
        _ => const Color(0xFFF5A623),
      },
      largeIcon: const DrawableResourceAndroidBitmap('dimi_logo'),
      sound: soundUri,
      category: AndroidNotificationCategory.reminder,
      fullScreenIntent: type == DimiNotificationType.reminder,
      autoCancel: false,
      // Expanded big-text style for richer information when pulled down
      styleInformation: bigText != null
          ? BigTextStyleInformation(
              bigText,
              htmlFormatBigText: false,
              contentTitle: null,
              summaryText: 'DIMI',
            )
          : null,
      actions: actions,
    );
  }

  List<AndroidNotificationAction> _actionsFor(DimiNotificationType type) {
    return switch (type) {
      DimiNotificationType.reminder => const [
        AndroidNotificationAction(
          _Action.markDone,
          'Mark done',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          _Action.snooze,
          'Snooze',
          showsUserInterface: false,
        ),
      ],
      DimiNotificationType.playlist => const [
        AndroidNotificationAction(
          _Action.openPlaylist,
          'Open Playlist',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          _Action.snooze,
          'Snooze',
          showsUserInterface: false,
        ),
      ],
      DimiNotificationType.todo => const [
        AndroidNotificationAction(
          _Action.markDone,
          'Mark done',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          _Action.snooze,
          'Snooze',
          showsUserInterface: false,
        ),
      ],
      DimiNotificationType.watch => const [
        AndroidNotificationAction(
          _Action.open,
          'Open',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          _Action.snooze,
          'Snooze',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          _Action.markDone,
          'Mark done',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
      DimiNotificationType.snoozePicker => const [],
    };
  }

  // ── Schedule helper ───────────────────────────────────────────────────────

  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduled,
    required AndroidNotificationDetails details,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        NotificationDetails(android: details),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      if (kDebugMode)
        debugPrint(
          '[NotificationService] scheduled #$id "$title" at $scheduled',
        );
    } catch (e, st) {
      // Never let a notification failure block the UI or DB write.
      if (kDebugMode)
        debugPrint('[NotificationService] schedule failed #$id: $e\n$st');
    }
  }

  // ── Payload builder ───────────────────────────────────────────────────────

  String _buildPayload({
    required DimiNotificationType type,
    required String title,
    required String body,
    String sound = 'default',
    int? reminderId,
    int? taskId,
    int? playlistId,
  }) {
    final map = <String, dynamic>{
      _Key.type: type.name,
      _Key.title: title,
      _Key.body: body,
      _Key.sound: sound,
    };
    if (reminderId != null) map[_Key.reminderId] = reminderId;
    if (taskId != null) map[_Key.taskId] = taskId;
    if (playlistId != null) map[_Key.playlistId] = playlistId;
    return jsonEncode(map);
  }

  // ── Sound preference ──────────────────────────────────────────────────────

  Future<String> _soundForReminder(int id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('dimi_reminder_sound_$id') ?? 'default';
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  String _detailFromReminderTitle(String title) {
    // If the title already has a detail hint ("Tick off:" / "Watch:") strip it.
    if (title.startsWith('Tick off: ')) return 'Complete your to-do item';
    if (title.startsWith('Watch: ')) return title.substring(7);
    return 'Tap to open DIMI';
  }

  DimiNotificationType _typeForReminder(String title) {
    if (title.startsWith('Watch: ')) return DimiNotificationType.watch;
    if (title.startsWith('Tick off: ')) return DimiNotificationType.todo;
    return DimiNotificationType.reminder;
  }

  String _notificationTitleForReminder(String title) {
    if (title.startsWith('Watch: ')) return 'Continue Watching';
    if (title.startsWith('Tick off: ')) return title.substring(9);
    return title;
  }

  String _bigTextForReminder({
    required DimiNotificationType type,
    required String title,
    required String detail,
  }) => switch (type) {
    DimiNotificationType.watch => 'Continue watching:\n$detail\n\nTap Open to get started.',
    DimiNotificationType.todo => '$title\n$detail',
    _ => '$title\n$detail\n\nDon\'t forget to be on time! ✨',
  };

  int _snoozeMinutes(String actionId) => switch (actionId) {
    _Action.snooze5 => 5,
    _Action.snooze10 => 10,
    _Action.snooze30 => 30,
    _Action.snooze60 => 60,
    _ => 5,
  };

  tz.TZDateTime _tomorrowMorning() {
    final now = tz.TZDateTime.now(tz.local);
    final tomorrow = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + 1,
      8,
    );
    return tomorrow;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top-level background callback (required by flutter_local_notifications)
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
void _handleResponseBackground(NotificationResponse response) {
  // Background isolate — we can only perform lightweight DB-free work here.
  // Full DB interactions happen in the foreground handler after the app starts.
  debugPrint('[NotificationService] background action: ${response.actionId}');
}
