import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/database.dart';

// ─── Notification icon ───────────────────────────────────────────────────────
// Small status-bar icon must be a monochrome (white/transparent) PNG.
// We reference the native drawable copied from the monochrome Android resource.
// The full-colour artwork is intentionally separate; Android masks/tints the
// small icon and cannot use a normal colour logo in this slot.
// Use the requested monochrome notification drawable for item 1.
const _kNotifIcon = 'dimi_small_status_icon';
const _thumbnailCacheVersion = 2;

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

/// Controls whether reminder-class notifications are ordinary shade
/// notifications or Android full-screen notifications.
enum DimiNotificationMode { normal, fullScreen }

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
  static const timeMillis = 'time_millis';
  static const reminderId = 'reminder_id';
  static const taskId = 'task_id';
  static const playlistId = 'playlist_id';
  static const accountId = 'account_id';
  static const notificationId = 'notification_id';
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
  Future<void>? _initFuture;

  // Injected DB reference so action callbacks can write completions.
  AppDatabase? _db;

  /// Called after a notification action has committed its local Drift change
  /// in the foreground app isolate.
  VoidCallback? onLocalActionCommitted;

  /// Opens a playlist directly from its notification action.
  Future<void> Function(int playlistId)? onOpenPlaylistUnwatched;

  /// Opens the dedicated in-app full-screen reminder experience.
  Future<void> Function(Map<String, dynamic> data)? onOpenFullScreenReminder;

  /// Navigates to the Planner screen, focused on [taskId]'s date.
  Future<void> Function(Map<String, dynamic> data)? onOpenPlanner;

  /// Navigates to the Reminders screen, highlighting [reminderId].
  Future<void> Function(Map<String, dynamic> data)? onOpenReminder;

  /// Notification tap payload queued while the UI closures are not yet wired
  /// (e.g. the app was launched from a killed state via a body tap).
  Map<String, dynamic>? _pendingTapData;

  void attachDatabase(AppDatabase db) => _db = db;

  static const _confirmationIdOffset = 200000;
  static const _dailyOccurrenceOffset = 1000000000;
  static const _dailyOccurrenceDays = 30;
  static const _notificationModeKey = 'dimi_notification_mode';

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
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
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();

    // One-time migration: clear payloads that referenced the old icon name.
    // This must only run once — running cancelAll() on every launch wipes all
    // pending AlarmManager entries and breaks background/reboot delivery.
    final prefs = await SharedPreferences.getInstance();
    const migrationKey = 'dimi_notif_icon_migrated_v3';
    if (prefs.getBool(migrationKey) != true) {
      await _plugin.cancelAll();
      await prefs.setBool(migrationKey, true);
    }

    _ready = true;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchDetails?.notificationResponse != null) {
      await _processAction(launchDetails!.notificationResponse!);
    }
    if (kDebugMode) debugPrint('[NotificationService] initialised');
  }

  Future<void> requestPermissions() async {
    final initFuture = _initFuture;
    if (!_ready && initFuture != null) {
      await initFuture;
    }
    if (!_ready) return;

    final ap = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (ap == null) return;
    await ap.requestNotificationsPermission();
    await ap.requestFullScreenIntentPermission();
  }

  // ── Public schedule helpers ───────────────────────────────────────────────

  /// Schedules a standard reminder notification.
  Future<void> scheduleReminder(
    Reminder reminder, {
    int? notificationIdOverride,
    DateTime? dueAtOverride,
  }) async {
    if (!_ready || !reminder.isEnabled) return;
    final isDailyPlaylist = _isDailyPlaylistReminder(reminder);
    if (isDailyPlaylist && notificationIdOverride == null) {
      await _ensureDailyReminderTime(reminder);
    }
    var dueAt = dueAtOverride ?? reminder.dueAt;
    if (dueAt.isBefore(DateTime.now())) {
      if (!isDailyPlaylist) return;
      dueAt = await _upcomingDailyDue(reminder, DateTime.now());
    }
    final notificationId = notificationIdOverride ?? reminder.notificationId;

    final sound = await _soundForReminder(reminder.id);
    final type = await _typeForReminder(reminder);
    final fullScreen = await isFullScreenModeEnabled();
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
      scheduledAt: dueAt,
      notificationId: notificationId,
      reminderId: reminder.id,
      taskId: reminder.taskId,
      playlistId: playlistId,
      accountId: reminder.localAccountId,
    );

    await _scheduleAt(
      id: notificationId,
      title: notificationTitle,
      body: detail,
      scheduled: tz.TZDateTime.from(dueAt, tz.local),
      details: _buildDetails(
        type: type,
        sound: sound,
        bigText: detail,
        bigPicturePath: thumbnailPath,
        fullScreenIntent:
            fullScreen &&
            (type == DimiNotificationType.reminder ||
                type == DimiNotificationType.planner),
      ),
      payload: payload,
    );
    if (isDailyPlaylist && notificationIdOverride == null) {
      var nextDue = await _nextDailyDue(reminder, dueAt);
      for (var day = 1; day <= _dailyOccurrenceDays; day++) {
        await scheduleReminder(
          reminder,
          notificationIdOverride:
              reminder.notificationId + _dailyOccurrenceOffset + day,
          dueAtOverride: nextDue,
        );
        nextDue = await _nextDailyDue(reminder, nextDue);
      }
    }
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
    int? reminderId,
    required String taskTitle,
    required String detail, // e.g. "You planned 2 problems today"
    required DateTime dueAt,
    int? taskId,
    int? playlistId,
    String? thumbnailUrl,
  }) async {
    if (!_ready) return;
    if (dueAt.isBefore(DateTime.now())) return;

    final isPlaylistTickOff = playlistId != null;
    final type = isPlaylistTickOff
        ? DimiNotificationType.playlist
        : DimiNotificationType.todo;
    final notificationTitle = isPlaylistTickOff
        ? 'End of Day Reminder ✅'
        : taskTitle;
    final notificationBody = isPlaylistTickOff
        ? 'Tick off your watched videos! ✅\n$taskTitle\n$detail'
        : detail;
    final displayBody = isPlaylistTickOff
        ? '$taskTitle\n$detail'
        : notificationBody;
    final displayTitle = isPlaylistTickOff
        ? 'End of Day Reminder \u2705'
        : notificationTitle;
    final thumbnailPath = isPlaylistTickOff
        ? await _cacheThumbnail(thumbnailUrl, notificationId)
        : null;
    final payload = _buildPayload(
      type: type,
      title: displayTitle,
      body: displayBody,
      reminderId: reminderId,
      taskId: taskId,
      playlistId: playlistId,
      accountId: _db?.activeAccountId,
    );

    await _scheduleAt(
      id: notificationId,
      title: displayTitle,
      body: displayBody,
      scheduled: tz.TZDateTime.from(dueAt, tz.local),
      details: _buildDetails(
        type: type,
        bigText: displayBody,
        bigPicturePath: thumbnailPath,
      ),
      payload: payload,
    );
  }

  /// Schedules a watch/remember reminder.
  Future<void> scheduleWatchReminder({
    required int notificationId,
    int? reminderId,
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
      reminderId: reminderId,
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
    // Playlist reminders also keep a separately scheduled next-day
    // occurrence. Disabling/deleting the reminder must remove both.
    for (var day = 1; day <= _dailyOccurrenceDays; day++) {
      await _plugin.cancel(id + _dailyOccurrenceOffset + day);
    }
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
    // Do NOT call cancelAll() here — it wipes all pending AlarmManager entries
    // including ones for reminders that haven't fired yet. Individual
    // scheduleReminder() calls replace existing alarms by notification ID.
    for (final r in reminders) {
      await scheduleReminder(r);
    }
  }

  Future<bool> isFullScreenModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_notificationModeKey) ==
        DimiNotificationMode.fullScreen.name;
  }

  /// Persists the mode and reapplies it to already scheduled reminders so a
  /// setting change takes effect without waiting for the next edit or reboot.
  Future<void> setNotificationMode(DimiNotificationMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationModeKey, mode.name);
    if (mode == DimiNotificationMode.fullScreen && _ready) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestFullScreenIntentPermission();
    }
    if (_ready && _db != null) {
      await rescheduleAll(await _db!.reminderDao.getAllEnabled());
    }
  }

  Future<void> setReminderSound(int id, String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dimi_reminder_sound_$id', sound);
  }

  Future<void> setDailyReminderTime(
    int id, {
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dimi_daily_reminder_hour_$id', hour);
    await prefs.setInt('dimi_daily_reminder_minute_$id', minute);
  }

  bool _isDailyPlaylistReminder(Reminder reminder) =>
      reminder.title.startsWith('Watch: ') ||
      reminder.title.startsWith('Tick off: ');

  Future<void> _ensureDailyReminderTime(Reminder reminder) async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('dimi_daily_reminder_hour_${reminder.id}')) {
      await setDailyReminderTime(
        reminder.id,
        hour: reminder.dueAt.hour,
        minute: reminder.dueAt.minute,
      );
    }
  }

  Future<DateTime> _nextDailyDue(Reminder reminder, DateTime from) async {
    final prefs = await SharedPreferences.getInstance();
    final hour =
        prefs.getInt('dimi_daily_reminder_hour_${reminder.id}') ??
        reminder.dueAt.hour;
    final minute =
        prefs.getInt('dimi_daily_reminder_minute_${reminder.id}') ??
        reminder.dueAt.minute;
    return DateTime(from.year, from.month, from.day + 1, hour, minute);
  }

  Future<DateTime> _upcomingDailyDue(Reminder reminder, DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    final hour =
        prefs.getInt('dimi_daily_reminder_hour_${reminder.id}') ??
        reminder.dueAt.hour;
    final minute =
        prefs.getInt('dimi_daily_reminder_minute_${reminder.id}') ??
        reminder.dueAt.minute;
    var due = DateTime(now.year, now.month, now.day, hour, minute);
    if (!due.isAfter(now)) due = due.add(const Duration(days: 1));
    return due;
  }

  /// Stores a private copy so Android can read the file when the scheduled
  /// notification fires, even if the original picker URI is no longer valid.
  Future<String?> pickReminderSound(int id) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'ogg', 'm4a', 'aac'],
      withData: false,
    );
    final sourcePath = result?.files.single.path;
    if (sourcePath == null || sourcePath.isEmpty) return null;

    final directory = await getApplicationSupportDirectory();
    final soundDirectory = Directory('${directory.path}/dimi_reminder_sounds');
    await soundDirectory.create(recursive: true);
    final extension = result!.files.single.extension ?? 'mp3';
    final destination = File(
      '${soundDirectory.path}/reminder_${id}_${DateTime.now().microsecondsSinceEpoch}.$extension',
    );
    await File(sourcePath).copy(destination.path);

    final value = 'file:${destination.path}';
    await setReminderSound(id, value);
    return value;
  }

  Future<String> getReminderSound(int id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('dimi_reminder_sound_$id') ?? 'default';
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

    final type = data[_Key.type] as String?;

    // ── Restore account context for background isolates ──────────────────
    final accountId = data[_Key.accountId] as int?;
    if (accountId != null && accountId > 0) {
      _db?.setActiveAccountId(accountId);
    }

    switch (actionId) {
      // ── Mark done ────────────────────────────────────────────────────────
      case _Action.markDone:
        // Cancel before rescheduling recurring playlist occurrences. If the
        // fired notification is the daily follow-up ID, cancelling after the
        // write would cancel the newly scheduled next occurrence instead.
        await _plugin.cancel(id);
        await _markDone(data);

        // After committing the DB write, navigate to the relevant screen.
        final playlistId = data[_Key.playlistId] as int?;
        if (playlistId != null &&
            (type == DimiNotificationType.playlist.name ||
                type == DimiNotificationType.watch.name)) {
          // Navigate to the unwatched section of this specific playlist.
          final openPlaylist = onOpenPlaylistUnwatched;
          if (openPlaylist != null) {
            unawaited(openPlaylist(playlistId));
          } else {
            _pendingTapData = {...data, '_action': _Action.markDone};
          }
        } else if (type == DimiNotificationType.planner.name) {
          // Navigate to the planner focused on the event's date.
          final openPlanner = onOpenPlanner;
          if (openPlanner != null) {
            unawaited(openPlanner(data));
          } else {
            _pendingTapData = {...data, '_action': _Action.markDone};
          }
        } else {
          // Standard reminder — navigate to reminders screen.
          final openReminder = onOpenReminder;
          if (openReminder != null) {
            unawaited(openReminder(data));
          } else {
            _pendingTapData = {...data, '_action': _Action.markDone};
          }
        }
        break;

      // ── Open / Open Playlist ─────────────────────────────────────────────
      case _Action.openPlaylist:
      case _Action.open:
        await _plugin.cancel(id);
        break;

      case _Action.snooze:
        await _snoozeReminder(id, data);
        break;

      // ── Body tap (null actionId) — navigate to the relevant screen ────────
      default:
        // Full-screen mode for reminder/planner types.
        if (await isFullScreenModeEnabled() &&
            (type == DimiNotificationType.reminder.name ||
                type == DimiNotificationType.planner.name)) {
          final openFullScreen = onOpenFullScreenReminder;
          if (openFullScreen != null) {
            await openFullScreen(data);
            return;
          }
          // Queue for drain after widget mounts.
          _pendingTapData = data;
          return;
        }
        // Route body taps to the appropriate screen.
        await _navigateForBodyTap(type, data);
        break;
    }
  }

  /// Navigates to the screen appropriate for a notification body tap.
  /// When UI closures are not yet wired (app launched from a killed state),
  /// the payload is queued in [_pendingTapData] and replayed after
  /// [drainPendingTap] is called from the widget tree.
  Future<void> _navigateForBodyTap(
    String? type,
    Map<String, dynamic> data,
  ) async {
    if (type == DimiNotificationType.planner.name) {
      final openPlanner = onOpenPlanner;
      if (openPlanner != null) {
        await openPlanner(data);
      } else {
        _pendingTapData = data;
      }
    } else if (type == DimiNotificationType.playlist.name ||
        type == DimiNotificationType.watch.name) {
      final playlistId = data[_Key.playlistId] as int?;
      if (playlistId != null) {
        final openPlaylist = onOpenPlaylistUnwatched;
        if (openPlaylist != null) {
          await openPlaylist(playlistId);
        } else {
          _pendingTapData = data;
        }
      }
    } else {
      // reminder (normal mode), todo, finance — reminders screen fallback
      final openReminder = onOpenReminder;
      if (openReminder != null) {
        await openReminder(data);
      } else {
        _pendingTapData = data;
      }
    }
  }

  /// Replays a tap payload queued while the UI closures were not yet assigned.
  /// Call this from [_DimiAppState.initState] immediately after wiring all
  /// navigation closures (onOpenPlanner, onOpenReminder, etc.).
  Future<void> drainPendingTap() async {
    final pending = _pendingTapData;
    if (pending == null) return;
    _pendingTapData = null;

    final type = pending[_Key.type] as String?;
    final action = pending['_action'] as String?;

    if (action == _Action.markDone) {
      // Mark-done navigation replay.
      final playlistId = pending[_Key.playlistId] as int?;
      if (playlistId != null &&
          (type == DimiNotificationType.playlist.name ||
              type == DimiNotificationType.watch.name)) {
        final openPlaylist = onOpenPlaylistUnwatched;
        if (openPlaylist != null) await openPlaylist(playlistId);
      } else if (type == DimiNotificationType.planner.name) {
        final openPlanner = onOpenPlanner;
        if (openPlanner != null) await openPlanner(pending);
      } else {
        final openReminder = onOpenReminder;
        if (openReminder != null) await openReminder(pending);
      }
      return;
    }

    // Body-tap replay — check for full-screen first.
    if (await isFullScreenModeEnabled() &&
        (type == DimiNotificationType.reminder.name ||
            type == DimiNotificationType.planner.name)) {
      final openFullScreen = onOpenFullScreenReminder;
      if (openFullScreen != null) {
        await openFullScreen(pending);
        return;
      }
    }
    await _navigateForBodyTap(type, pending);
  }

  Future<void> _snoozeReminder(
    int notificationId,
    Map<String, dynamic> data,
  ) async {
    if (_db == null) return;
    try {
      final reminderId = data[_Key.reminderId] as int?;
      final taskId = data[_Key.taskId] as int?;
      // Planner notifications must resolve through task_id so snooze edits
      // the reminder belonging to the exact Planner event.
      final reminder = taskId != null
          ? await _db!.reminderDao.getByTaskId(taskId)
          : reminderId != null
          ? await _db!.reminderDao.getById(reminderId)
          : null;
      if (reminder == null) return;

      // A daily playlist reminder has one persisted time and a set of
      // separately scheduled occurrences. Snoozing must affect only the
      // notification that fired; changing the reminder row would move the
      // daily time (and every future occurrence) by five minutes.
      if (_isDailyPlaylistReminder(reminder)) {
        await _plugin.cancel(notificationId);
        await scheduleReminder(
          reminder,
          notificationIdOverride: notificationId,
          dueAtOverride: DateTime.now().add(const Duration(minutes: 5)),
        );
        return;
      }

      final dueAt = DateTime.now().add(const Duration(minutes: 5));
      final changed = await _db!.reminderDao.updateReminder(
        RemindersCompanion(
          id: Value(reminder.id),
          dueAt: Value(dueAt),
          isEnabled: const Value(true),
        ),
      );
      if (!changed) return;
      // Drift is the first commit. UI refresh must not depend on scheduling.
      onLocalActionCommitted?.call();
      final updated = await _db!.reminderDao.getById(reminder.id);
      if (updated != null) {
        try {
          await _plugin.cancel(notificationId);
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('[NotificationService] snooze cancel failed: $e\n$st');
          }
        }
        await scheduleReminder(updated);
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[NotificationService] snooze failed: $e\n$st');
      }
    }
  }

  Future<void> _markDone(Map<String, dynamic> data) async {
    if (_db == null) return;
    try {
      await _markDoneUnsafe(data);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[NotificationService] mark done failed: $e\n$st');
      }
    }
  }

  Future<void> _markDoneUnsafe(Map<String, dynamic> data) async {
    final playlistId = data[_Key.playlistId] as int?;
    final reminderId = data[_Key.reminderId] as int?;
    if (playlistId != null) {
      await _db!.youtubePlaylistDao.markWatchedToday(playlistId);
      final reminder = reminderId == null
          ? null
          : await _db!.reminderDao.getById(reminderId);
      if (reminder != null) {
        final playlistHasWork = await _db!.youtubePlaylistDao
            .hasUncompletedVideos(playlistId);
        if (!playlistHasWork) {
          await _db!.reminderDao.toggleEnabled(reminder.id, false);
          await cancelReminder(reminder.notificationId);
          await _showConfirmation(
            id: (reminderId ?? playlistId) + _confirmationIdOffset,
            title: 'Playlist complete',
            body: 'All videos in this playlist are complete.',
          );
          return;
        }
        final now = DateTime.now();
        final nextDue = await _nextDailyDue(reminder, now);
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
    if (taskId != null) {
      // TaskDao also disables the linked Planner reminder and enqueues its
      // local-first update, so notification and manual completion match.
      await _db!.taskDao.completeFromNotification(taskId);
    } else if (reminderId != null) {
      await _db!.reminderDao.toggleEnabled(reminderId, false);
    }
    onLocalActionCommitted?.call();
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
    bool fullScreenIntent = false,
  }) {
    final channelBase = switch (type) {
      DimiNotificationType.reminder => _Channel.reminderId,
      DimiNotificationType.planner => _Channel.plannerId,
      DimiNotificationType.finance => _Channel.financeId,
      DimiNotificationType.playlist => _Channel.youtubeId,
      DimiNotificationType.todo => _Channel.reminderId,
      DimiNotificationType.watch => _Channel.youtubeId,
    };
    // Android freezes a channel's sound after its first creation. A distinct
    // channel per sound prevents a previous/default channel from winning.
    final channelId = '${channelBase}_${_stableSoundId(sound)}';
    final channelName = switch (type) {
      DimiNotificationType.reminder => 'Reminders',
      DimiNotificationType.planner => 'Planner',
      DimiNotificationType.finance => 'Finance',
      DimiNotificationType.playlist => 'YouTube',
      DimiNotificationType.todo => 'Reminders',
      DimiNotificationType.watch => 'YouTube',
    };

    final soundValue = sound.startsWith('file:') ? sound.substring(5) : sound;
    final soundUri = switch (soundValue) {
      'ringtone' => const UriAndroidNotificationSound(
        'content://settings/system/ringtone',
      ),
      'alarm' => const UriAndroidNotificationSound(
        'content://settings/system/alarm_alert',
      ),
      _ when soundValue.isNotEmpty && soundValue != 'default' =>
        UriAndroidNotificationSound('file://$soundValue'),
      _ => null,
    };

    final actions = _actionsFor(type);
    final largeIconName = _largeIconFor(type);

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
      largeIcon: largeIconName == null
          ? null
          : DrawableResourceAndroidBitmap(largeIconName),
      sound: soundUri,
      category: AndroidNotificationCategory.reminder,
      fullScreenIntent: fullScreenIntent,
      autoCancel: true,
      // Expanded big-text style for richer information when pulled down
      styleInformation: bigPicturePath != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(bigPicturePath),
              hideExpandedLargeIcon: false,
              summaryText: bigText,
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

  String _stableSoundId(String sound) {
    if (sound == 'default') return 'default';
    var value = 17;
    for (final unit in sound.codeUnits) {
      value = (value * 31 + unit) & 0x7fffffff;
    }
    return value.toRadixString(36);
  }

  String? _largeIconFor(DimiNotificationType type) => switch (type) {
    DimiNotificationType.planner => 'dimi_planner',
    DimiNotificationType.finance => 'dimi_finance',
    DimiNotificationType.reminder ||
    DimiNotificationType.todo => 'dimi_reminder_large',
    // Playlist/watch notifications have no notification-specific large
    // illustration. Leave largeIcon unset so Android/OEM can supply the
    // application's identity icon where supported.
    DimiNotificationType.playlist || DimiNotificationType.watch => null,
  };

  List<AndroidNotificationAction> _actionsFor(DimiNotificationType type) {
    return const [
      AndroidNotificationAction(
        _Action.markDone,
        'Mark Done',
        titleColor: Color(0xFF1B1B1B),
        // Run completion in the main app isolate so the live Drift streams
        // emit immediately and Planner updates without waiting for sync.
        showsUserInterface: true,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        _Action.snooze,
        'Snooze 5 min',
        titleColor: Color(0xFF1B1B1B),
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
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      if (kDebugMode) {
        debugPrint(
          '[NotificationService] scheduled #$id "$title" at $scheduled',
        );
      }
    } catch (e, st) {
      // Never let a notification failure block the UI or DB write.
      if (kDebugMode) {
        debugPrint('[NotificationService] schedule failed #$id: $e\n$st');
      }
    }
  }

  // ── Payload builder ───────────────────────────────────────────────────────

  String _buildPayload({
    required DimiNotificationType type,
    required String title,
    required String body,
    String sound = 'default',
    DateTime? scheduledAt,
    int? notificationId,
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
    if (scheduledAt != null) {
      map[_Key.timeMillis] = scheduledAt.millisecondsSinceEpoch;
    }
    if (notificationId != null) map[_Key.notificationId] = notificationId;
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

      if (!await cache.exists()) {
        await cache.create(recursive: true);
      }

      final file = File(
        '${cache.path}/${notificationId}_v$_thumbnailCacheVersion.jpg',
      );
      if (await file.exists()) return file.path;

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close().timeout(
          const Duration(seconds: 8),
        );
        if (response.statusCode != 200) return null;

        final builder = BytesBuilder();
        await for (final chunk in response) {
          builder.add(chunk);
        }

        final normalized = _normalizeThumbnail(builder.takeBytes());
        await file.writeAsBytes(normalized);

        return file.path;
      } finally {
        client.close(force: true);
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[NotificationService] thumbnail cache failed: $error');
      }
      return null;
    }
  }

  Uint8List _normalizeThumbnail(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    var image = decoded;

    const darkThreshold = 24;
    const uniformFraction = 0.9;

    int luma(img.Pixel p) => (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();

    bool rowIsBar(int y) {
      var dark = 0;
      for (var x = 0; x < image.width; x++) {
        if (luma(image.getPixel(x, y)) < darkThreshold) dark++;
      }
      return dark / image.width >= uniformFraction;
    }

    bool colIsBar(int x) {
      var dark = 0;
      for (var y = 0; y < image.height; y++) {
        if (luma(image.getPixel(x, y)) < darkThreshold) dark++;
      }
      return dark / image.height >= uniformFraction;
    }

    var top = 0;
    while (top < image.height ~/ 3 && rowIsBar(top)) {
      top++;
    }

    var bottom = image.height - 1;
    while (bottom > image.height * 2 ~/ 3 && rowIsBar(bottom)) {
      bottom--;
    }

    var left = 0;
    while (left < image.width ~/ 3 && colIsBar(left)) {
      left++;
    }

    var right = image.width - 1;
    while (right > image.width * 2 ~/ 3 && colIsBar(right)) {
      right--;
    }

    if (top > 0 ||
        bottom < image.height - 1 ||
        left > 0 ||
        right < image.width - 1) {
      image = img.copyCrop(
        image,
        x: left,
        y: top,
        width: right - left + 1,
        height: bottom - top + 1,
      );
    }

    const targetRatio = 16 / 9;
    final currentRatio = image.width / image.height;

    if (currentRatio > targetRatio) {
      final newWidth = (image.height * targetRatio).round();
      final x = (image.width - newWidth) ~/ 2;

      image = img.copyCrop(
        image,
        x: x,
        y: 0,
        width: newWidth,
        height: image.height,
      );
    } else if (currentRatio < targetRatio) {
      final newHeight = (image.width / targetRatio).round();
      final y = (image.height - newHeight) ~/ 2;

      image = img.copyCrop(
        image,
        x: 0,
        y: y,
        width: image.width,
        height: newHeight,
      );
    }

    final resized = img.copyResize(image, width: 640);

    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  String _detailFromReminderTitle(String title, {DimiNotificationType? type}) {
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
    if (title.startsWith('Watch: ')) return 'Daily Watch Reminder';
    if (title.startsWith('Tick off: ')) return 'End of Day Reminder';
    return title;
  }

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
