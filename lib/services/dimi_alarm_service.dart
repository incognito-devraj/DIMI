import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native bridge to DimiAlarmScheduler (Kotlin).
///
/// Schedules exact AlarmManager alarms that fire DimiScheduledReceiver, which
/// posts a full-screen notification pointing directly at DimiReminderActivity —
/// no MainActivity flash, works with screen off, lock screen and foreground.
class DimiAlarmService {
  DimiAlarmService._();
  static final DimiAlarmService instance = DimiAlarmService._();

  static const _channel = MethodChannel('com.dimi.dimi_app/alarm_scheduler');
  static const reminderIntentChannel = MethodChannel(
    'com.dimi.dimi_app/reminder_intent',
  );

  /// Schedule a full-screen notification at [triggerAt].
  ///
  /// [payload] must be the same JSON string that flutter_local_notifications
  /// would have used — the Flutter handler decodes it via jsonDecode.
  Future<void> schedule({
    required int notifId,
    required DateTime triggerAt,
    required String payload,
    required String title,
    required String body,
    required String type, // "planner" | "reminder" | "playlist" | "watch"
  }) async {
    try {
      await _channel.invokeMethod<void>('schedule', {
        'notifId': notifId,
        'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
        'payload': payload,
        'title': title,
        'body': body,
        'type': type,
      });
      if (kDebugMode) {
        debugPrint('[DimiAlarm] scheduled #$notifId "$title" at $triggerAt');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DimiAlarm] schedule failed #$notifId: $e');
      }
    }
  }

  /// Cancel an alarm previously set with [schedule].
  Future<void> cancel(int notifId) async {
    try {
      await _channel.invokeMethod<void>('cancel', {'notifId': notifId});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DimiAlarm] cancel failed #$notifId: $e');
      }
    }
  }

  /// Remove all alarm metadata older than 24 hours.
  /// Called during app startup to prevent ghost alarms after reboot.
  Future<void> cleanupStaleEntries() async {
    try {
      await _channel.invokeMethod<void>('cleanupStaleEntries');
      if (kDebugMode) {
        debugPrint('[DimiAlarm] cleaned up stale alarm entries');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DimiAlarm] cleanup failed: $e');
      }
    }
  }

  Future<void> cancelRetry(int notifId) async {
    try {
      await _channel.invokeMethod<void>('cancelRetry', {'notifId': notifId});
    } catch (e) {
      if (kDebugMode)
        debugPrint('[DimiAlarm] retry cancel failed #$notifId: $e');
    }
  }

  /// Show a full-screen notification immediately (used for snooze re-fire).
  Future<void> showImmediate({
    required int notifId,
    required String payload,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await _channel.invokeMethod<void>('showImmediate', {
        'notifId': notifId,
        'payload': payload,
        'title': title,
        'body': body,
        'type': type,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DimiAlarm] showImmediate failed #$notifId: $e');
      }
    }
  }
}
