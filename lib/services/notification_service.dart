import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/database.dart';

// ─── Notification icon ───────────────────────────────────────────────────────
// Small status-bar icon must be a monochrome (white/transparent) PNG.
// We reference the drawable we copied from assets/logos/notification.png.
// If that drawable is not yet a valid monochrome asset, Android silently
// replaces it — this constant makes it easy to change in one place.
const _kNotifIcon = 'dimi_small_status_icon';

// ─────────────────────────────────────────────────────────────────────────────
// Notification type
// ─────────────────────────────────────────────────────────────────────────────

/// Determines which action buttons and icon badge a notification gets.
enum DimiNotificationType {
  /// A standard timed reminder (planner event, class, general).
  reminder,

  planner,

  finance,

  /// Remind the user to continue watching a YouTube playlist.
  playlist,

  /// Remind the user to complete a specific To-Do task.
  todo,

  /// Remind the user to watch/read a linked video or note.
  watch,

}

// ─────────────────────────────────────────────────────────────────────────────
// Action ID constants (must be stable — they survive process death)
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _Action {
  static const markDone = 'dimi_mark_done';
  static const openPlaylist = 'dimi_open_playlist';
  static const open = 'dimi_open';
  static const snooze = 'dimi_snooze';
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification channels
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _Channel {
  // Versioned IDs ensure Android does not reuse an old channel label such as
  // the previous "DIMI" channel name already stored on the device.
  static const reminderId = 'dimi_reminders_v2';
  static const youtubeId = 'dimi_youtube_v2';
  static const plannerId = 'dimi_planner_v2';
  static const financeId = 'dimi_finance_v2';
  static const todoId = 'dimi_todo_v2';
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
  static const accountId = 'account_id';
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

  static const _confirmationIdOffset = 200000;

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

    // Scheduled notifications persist across an APK update. Clear any
    // payloads created with a previous icon name before main.dart reloads the
    // enabled reminders using the current notification configuration.
    await _plugin.cancelAll();

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
    final type = await _typeForReminder(reminder);
    final notificationTitle = _notificationTitleForReminder(reminder.title);
    final detail = _detailFromReminderTitle(reminder.title, type: type);
    final playlist = await _playlistForReminder(reminder.title);
    final playlistId = playlist?.id;
    final thumbnailPath = await _cacheThumbnail(
      playlist?.thumbnailUrl,
      reminder.notificationId,
    );
    final payload = _buildPayload(
      type: type,
      title: notificationTitle,
      body: detail,
      sound: sound,
      reminderId: reminder.id,
      taskId: reminder.taskId,
      playlistId: playlistId,
      accountId: reminder.localAccountId,
    );

    await _scheduleAt(
      id: reminder.notificationId,
      title: notificationTitle,
      body: detail,
      scheduled: tz.TZDateTime.from(reminder.dueAt, tz.local),
      details: _buildDetails(
        type: type,
        sound: sound,
        bigText: detail,
        bigPicturePath: thumbnailPath,
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
    String? thumbnailUrl,
  }) async {
    if (!_ready) return;
    if (dueAt.isBefore(DateTime.now())) return;

    final thumbnailPath = await _cacheThumbnail(thumbnailUrl, notificationId);
    final payload = _buildPayload(
      type: DimiNotificationType.playlist,
      title: 'YouTube Reminder',
      body:
          '$playlistTitle • $unwatchedCount unwatched video${unwatchedCount == 1 ? '' : 's'}',
      playlistId: playlistLocalId,
    );

    await _scheduleAt(
      id: notificationId,
      title: 'YouTube Reminder',
      body:
          '$playlistTitle • $unwatchedCount unwatched video${unwatchedCount == 1 ? '' : 's'}',
      scheduled: tz.TZDateTime.from(dueAt, tz.local),
      details: _buildDetails(
        type: DimiNotificationType.playlist,
        bigPicturePath: thumbnailPath,
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
    int? playlistId,
  }) async {
    if (!_ready) return;
    if (dueAt.isBefore(DateTime.now())) return;

    final isPlaylistTickOff = playlistId != null;
    final type = isPlaylistTickOff
        ? DimiNotificationType.playlist
        : DimiNotificationType.todo;
    final notificationTitle = isPlaylistTickOff
        ? 'End of Day Reminder'
        : taskTitle;
    final notificationBody = isPlaylistTickOff
        ? 'Tick off your watched videos! ✅\n$taskTitle\n$detail'
        : detail;
    final payload = _buildPayload(
      type: type,
      title: notificationTitle,
      body: notificationBody,
      taskId: taskId,
      playlistId: playlistId,
      accountId: _db?.activeAccountId,
    );

    await _scheduleAt(
      id: notificationId,
      title: notificationTitle,
      body: notificationBody,
      scheduled: tz.TZDateTime.from(dueAt, tz.local),
      details: _buildDetails(
        type: type,
        bigText: notificationBody,
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
    String? thumbnailUrl,
  }) async {
    if (!_ready) return;
    if (dueAt.isBefore(DateTime.now())) return;

    final thumbnailPath = await _cacheThumbnail(thumbnailUrl, notificationId);
    final payload = _buildPayload(
      type: DimiNotificationType.watch,
      title: 'YouTube Reminder',
      body: 'Time to watch your playlist!\n$contentTitle',
      taskId: taskId,
      playlistId: playlistId,
      accountId: _db?.activeAccountId,
    );

    await _scheduleAt(
      id: notificationId,
      title: 'YouTube Reminder',
      body: 'Time to watch your playlist!\n$contentTitle',
      scheduled: tz.TZDateTime.from(dueAt, tz.local),
      details: _buildDetails(
        type: DimiNotificationType.watch,
        bigPicturePath: thumbnailPath,
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
  }

  Future<void> showTestNotification() async {
    if (!_ready) return;
    await _plugin.show(
      987654,
      'Testing Events',
      'Don\'t forget to be on time.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _Channel.reminderId,
          'Reminders',
          channelDescription: 'Reminder notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: _kNotifIcon,
          color: const Color(0xFFF5A623),
          largeIcon: const DrawableResourceAndroidBitmap('dimi_reminder_large'),
          autoCancel: true,
        ),
      ),
    );
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

    // Background actions run with a fresh database instance. Restore the
    // account carried by the reminder payload before using account-scoped DAOs.
    var accountId = data[_Key.accountId] as int?;
    if (accountId != null && accountId > 0) {
      _db?.setActiveAccountId(accountId!);
    }

    switch (actionId) {
      // ── Mark done ────────────────────────────────────────────────────────
      case _Action.markDone:
        await _markDone(data);
        await _plugin.cancel(id);

      // ── Open / Open Playlist ─────────────────────────────────────────────
      case _Action.openPlaylist:
      case _Action.open:
        await _plugin.cancel(id);
      // Deep-link handled by go_router — we just dismiss the notification.
      // The notification tap (null actionId) also reaches here if the user
      // taps the body; the router's initialLocation handles routing.

      case _Action.snooze:
        await _snoozeReminder(id, data);
        break;

    }
  }

  Future<void> _snoozeReminder(int notificationId, Map<String, dynamic> data) async {
    if (_db == null) return;
    final reminderId = data[_Key.reminderId] as int?;
    final taskId = data[_Key.taskId] as int?;
    final reminder = reminderId != null
        ? await _db!.reminderDao.getById(reminderId)
        : taskId != null
        ? await _db!.reminderDao.getByTaskId(taskId)
        : null;
    if (reminder == null) return;
    final dueAt = DateTime.now().add(const Duration(minutes: 5));
    await _db!.reminderDao.updateReminder(
      RemindersCompanion(
        id: Value(reminder.id),
        dueAt: Value(dueAt),
        isEnabled: const Value(true),
      ),
    );
    final updated = await _db!.reminderDao.getById(reminder.id);
    if (updated != null) {
      await _plugin.cancel(notificationId);
      await scheduleReminder(updated);
    }
  }

  Future<void> _markDone(Map<String, dynamic> data) async {
    if (_db == null) return;
    final playlistId = data[_Key.playlistId] as int?;
    final reminderId = data[_Key.reminderId] as int?;
    if (playlistId != null) {
      await _db!.youtubePlaylistDao.markWatchedToday(playlistId);
      final reminder = reminderId == null
          ? null
          : await _db!.reminderDao.getById(reminderId);
      if (reminder != null) {
        final now = DateTime.now();
        var nextDue = DateTime(
          now.year,
          now.month,
          now.day,
          reminder.dueAt.hour,
          reminder.dueAt.minute,
        );
        if (!nextDue.isAfter(now)) nextDue = nextDue.add(const Duration(days: 1));
        await _db!.reminderDao.updateReminder(
          RemindersCompanion(
            id: Value(reminder.id),
            title: Value(reminder.title),
            dueAt: Value(nextDue),
            isEnabled: const Value(true),
          ),
        );
        final updated = await _db!.reminderDao.getById(reminder.id);
        if (updated != null) await scheduleReminder(updated);
      }
      await _showConfirmation(
        id: (reminderId ?? playlistId) + _confirmationIdOffset,
        title: 'Playlist updated',
        body: "Today's watched videos have been marked done.",
      );
      return;
    }

    final taskId = data[_Key.taskId] as int?;
    if (taskId != null) await _db!.taskDao.completeFromNotification(taskId);
    if (reminderId != null) {
      await _db!.reminderDao.toggleEnabled(reminderId, false);
    }
  }

  Future<void> _showConfirmation({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _Channel.reminderId,
          'Reminders',
          channelDescription: 'Reminder confirmations',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: _kNotifIcon,
          color: const Color(0xFFF5A623),
          largeIcon: const DrawableResourceAndroidBitmap('dimi_logo'),
          autoCancel: true,
        ),
      ),
    );
  }

  // ── Build notification details per type ───────────────────────────────────

  AndroidNotificationDetails _buildDetails({
    required DimiNotificationType type,
    String sound = 'default',
    String? bigText,
    String? bigPicturePath,
  }) {
    final channelId = switch (type) {
      DimiNotificationType.reminder => _Channel.reminderId,
      DimiNotificationType.planner => _Channel.plannerId,
      DimiNotificationType.finance => _Channel.financeId,
      DimiNotificationType.playlist => _Channel.youtubeId,
      DimiNotificationType.todo => _Channel.reminderId,
      DimiNotificationType.watch => _Channel.youtubeId,
    };
    final channelName = switch (type) {
      DimiNotificationType.reminder => 'Reminders',
      DimiNotificationType.planner => 'Planner',
      DimiNotificationType.finance => 'Finance',
      DimiNotificationType.playlist => 'YouTube',
      DimiNotificationType.todo => 'Reminders',
      DimiNotificationType.watch => 'YouTube',
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
      channelDescription: '$channelName notifications',
      importance: Importance.max,
      priority: Priority.max,
      icon: _kNotifIcon,
      // DIMI amber accent shown in the notification shade on supported OEMs
      color: switch (type) {
        DimiNotificationType.playlist => const Color(0xFFE53935),
        DimiNotificationType.planner => const Color(0xFFF5A623),
        DimiNotificationType.finance => const Color(0xFF34C759),
        DimiNotificationType.todo => const Color(0xFF43A047),
        DimiNotificationType.watch => const Color(0xFF7E57C2),
        _ => const Color(0xFFF5A623),
      },
      largeIcon: DrawableResourceAndroidBitmap(_largeIconFor(type)),
      sound: soundUri,
      category: AndroidNotificationCategory.reminder,
      fullScreenIntent: type == DimiNotificationType.reminder,
      autoCancel: true,
      // Expanded big-text style for richer information when pulled down
      styleInformation: bigPicturePath != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(bigPicturePath),
              hideExpandedLargeIcon: false,
            )
          : bigText != null
          ? BigTextStyleInformation(
              bigText,
              htmlFormatBigText: false,
              contentTitle: null,
            )
          : null,
      actions: actions,
    );
  }

  String _largeIconFor(DimiNotificationType type) => switch (type) {
    DimiNotificationType.planner => 'dimi_planner',
    DimiNotificationType.finance => 'dimi_finance',
    DimiNotificationType.reminder || DimiNotificationType.todo =>
      'dimi_reminder_large',
    DimiNotificationType.playlist || DimiNotificationType.watch => 'dimi_logo',
  };

  List<AndroidNotificationAction> _actionsFor(DimiNotificationType type) {
    return const [
        AndroidNotificationAction(
          _Action.markDone,
          'Mark Done',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          _Action.snooze,
          'Snooze 5 min',
          showsUserInterface: false,
        ),
      ];
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
    int? accountId,
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
    if (accountId != null && accountId > 0) map[_Key.accountId] = accountId;
    return jsonEncode(map);
  }

  // ── Sound preference ──────────────────────────────────────────────────────

  Future<String> _soundForReminder(int id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('dimi_reminder_sound_$id') ?? 'default';
  }

  Future<String?> _cacheThumbnail(String? url, int notificationId) async {
    if (url == null || url.isEmpty) return null;
    try {
      final directory = await getApplicationSupportDirectory();
      final cache = Directory('${directory.path}/dimi_notification_thumbnails');
      if (!await cache.exists()) await cache.create(recursive: true);
      final file = File('${cache.path}/$notificationId.jpg');
      if (await file.exists()) return file.path;

      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close().timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) return null;
        await response.pipe(file.openWrite());
        return file.path;
      } finally {
        client.close(force: true);
      }
    } catch (error) {
      if (kDebugMode) debugPrint('[NotificationService] thumbnail cache failed: $error');
      return null;
    }
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  String _detailFromReminderTitle(
    String title, {
    DimiNotificationType? type,
  }) {
    // If the title already has a detail hint ("Tick off:" / "Watch:") strip it.
    if (title.startsWith('Tick off: ')) {
      return 'Tick off your watched videos!\n${title.substring(10)}';
    }
    if (title.startsWith('Watch: ')) {
      return 'Time to watch your playlist!\n${title.substring(7)}';
    }
    return switch (type) {
      DimiNotificationType.planner => 'Your planner event is starting.',
      DimiNotificationType.finance => 'Review your finances.',
      _ => 'Don\'t forget to be on time.',
    };
  }

  Future<YoutubePlaylist?> _playlistForReminder(String title) async {
    if (_db == null) return null;
    final playlistTitle = title.startsWith('Watch: ')
        ? title.substring(7)
        : title.startsWith('Tick off: ')
        ? title.substring(10)
        : null;
    if (playlistTitle == null) return null;
    return _db!.youtubePlaylistDao.getByTitle(playlistTitle);
  }

  Future<DimiNotificationType> _typeForReminder(Reminder reminder) async {
    final title = reminder.title;
    if (title.startsWith('Watch: ')) return DimiNotificationType.watch;
    if (title.startsWith('Tick off: ')) return DimiNotificationType.playlist;
    if (title.startsWith('Finance: ')) return DimiNotificationType.finance;
    if (reminder.taskId != null && _db != null) {
      final task = await _db!.taskDao.getById(reminder.taskId!);
      if (task?.isPlannerEntry == true) return DimiNotificationType.planner;
    }
    return DimiNotificationType.reminder;
  }

  String _notificationTitleForReminder(String title) {
    if (title.startsWith('Watch: ')) return 'YouTube Reminder';
    if (title.startsWith('Tick off: ')) return 'End of Day Reminder';
    return title;
  }

  String _bigTextForReminder({
    required DimiNotificationType type,
    required String title,
    required String detail,
  }) => switch (type) {
    DimiNotificationType.watch => '$detail\n\nTap Mark done when you finish.',
    DimiNotificationType.todo => '$title\n$detail',
    _ => '$title\n$detail\n\nDon\'t forget to be on time! ✨',
  };

}

// ─────────────────────────────────────────────────────────────────────────────
// Top-level background callback (required by flutter_local_notifications)
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
void _handleResponseBackground(NotificationResponse response) {
  unawaited(_handleResponseInBackground(response));
}

@pragma('vm:entry-point')
Future<void> _handleResponseInBackground(NotificationResponse response) async {
  final service = NotificationService.instance;
  if (!service._ready) {
    tz.initializeTimeZones();
    await service._plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings(_kNotifIcon),
      ),
    );
    service._ready = true;
  }
  service.attachDatabase(AppDatabase());
  await service._processAction(response);
}
