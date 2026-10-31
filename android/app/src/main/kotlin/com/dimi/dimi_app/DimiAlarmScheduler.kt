package com.dimi.dimi_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Schedules / cancels exact alarms using AlarmManager.
 *
 * setAlarmClock() is used because it is:
 *   • Exact even in Doze mode (same as flutter_local_notifications' alarmClock mode)
 *   • Shows the clock icon in the status bar so the user knows an alarm is set
 *   • Guaranteed to fire at the requested time on all Android versions
 *
 * The alarm fires DimiScheduledReceiver, which then posts the notification
 * via DimiNotificationHelper with DimiReminderActivity as the target.
 */
object DimiAlarmScheduler {

    /**
     * Schedule (or reschedule) a single notification.
     *
     * @param triggerAtMillis  epoch milliseconds when the alarm should fire
     * @param notifId          stable integer id (matches flutter_local_notifications id)
     * @param payload          JSON payload forwarded to Flutter
     * @param title            notification title
     * @param body             notification body
     * @param type             "planner" | "reminder" | "playlist" | "watch"
     */
    fun schedule(
        context: Context,
        triggerAtMillis: Long,
        notifId: Int,
        payload: String,
        title: String,
        body: String,
        type: String,
    ) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        // Check exact-alarm permission on Android 12+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!am.canScheduleExactAlarms()) return
        }

        val pi = buildPendingIntent(context, notifId, payload, title, body, type)

        // AlarmManager.AlarmClockInfo shows a clock in the status bar and
        // fires exactly on time even in Doze/power-saving mode.
        val info = AlarmManager.AlarmClockInfo(
            triggerAtMillis,
            pi, // shown as the "show intent" when the user taps the clock icon
        )
        am.setAlarmClock(info, pi)
    }

    /** Cancel a previously scheduled alarm. */
    fun cancel(context: Context, notifId: Int) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        // Recreate an equivalent PendingIntent (extras don't need to match for cancel)
        val pi = buildPendingIntent(context, notifId, "", "", "", "")
        am.cancel(pi)
        pi.cancel()
    }

    private fun buildPendingIntent(
        context: Context,
        notifId: Int,
        payload: String,
        title: String,
        body: String,
        type: String,
    ): PendingIntent {
        val i = Intent(context, DimiScheduledReceiver::class.java).apply {
            action = "com.dimi.dimi_app.FIRE_NOTIFICATION.$notifId"
            putExtra(DimiScheduledReceiver.EXTRA_NOTIF_ID, notifId)
            putExtra(DimiScheduledReceiver.EXTRA_PAYLOAD,  payload)
            putExtra(DimiScheduledReceiver.EXTRA_TITLE,    title)
            putExtra(DimiScheduledReceiver.EXTRA_BODY,     body)
            putExtra(DimiScheduledReceiver.EXTRA_TYPE,     type)
        }
        return PendingIntent.getBroadcast(
            context,
            notifId,
            i,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
