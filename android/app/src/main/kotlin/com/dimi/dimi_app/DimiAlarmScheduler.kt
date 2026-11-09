package com.dimi.dimi_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject

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
    private const val PAYLOAD_PREFIX = "dimi_alarm_payload_"
    private const val METADATA_PREFIX = "dimi_alarm_metadata_"
    private const val PREFS_NAME = "dimi_alarms"
    private const val DEVICE_PREFS_NAME = "dimi_alarms_device_v2"

    private fun deviceAlarmPrefs(context: Context) = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        context.createDeviceProtectedStorageContext()
            .getSharedPreferences(DEVICE_PREFS_NAME, Context.MODE_PRIVATE)
    } else context.getSharedPreferences(DEVICE_PREFS_NAME, Context.MODE_PRIVATE)

    // Read the previous device-protected store too, so an update does not
    // strand alarms written by the earlier scheduler.
    private fun legacyDeviceAlarmPrefs(context: Context) = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        context.createDeviceProtectedStorageContext()
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    } else context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private fun alarmPrefs(context: Context) = deviceAlarmPrefs(context)

    private fun writeAlarm(context: Context, notifId: Int, payload: String, metadata: String) {
        val stores = mutableListOf(deviceAlarmPrefs(context), legacyDeviceAlarmPrefs(context))
        // Keep a credential-protected copy for normal app recovery, but never
        // depend on it during Direct Boot.
        try { stores += context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE) } catch (_: Exception) {}
        stores.forEach { it.edit()
            .putString(PAYLOAD_PREFIX + notifId, payload)
            .putString(METADATA_PREFIX + notifId, metadata)
            .commit() }
    }

    private fun removeAlarm(context: Context, notifId: Int) {
        val stores = mutableListOf(deviceAlarmPrefs(context), legacyDeviceAlarmPrefs(context))
        try { stores += context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE) } catch (_: Exception) {}
        stores.forEach { it.edit()
            .remove(PAYLOAD_PREFIX + notifId)
            .remove(METADATA_PREFIX + notifId)
            .apply() }
    }

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

        val pi = buildPendingIntent(context, notifId, payload, title, body, type)
        val metadata = JSONObject().apply {
                    put("triggerAtMillis", triggerAtMillis)
                    put("payload", payload)
                    put("title", title)
                    put("body", body)
                    put("type", type)
                }.toString()
        writeAlarm(context, notifId, payload, metadata)

        // AlarmManager.AlarmClockInfo is the most reliable exact path and
        // survives Doze. Some OEMs report exact-alarm access as unavailable
        // even when USE_EXACT_ALARM is declared, however. Do not silently
        // drop the user's alarm in that case: use the idle-compatible fallback
        // and let the receiver deliver the notification as soon as Android
        // releases the device from idle.
        val exactAllowed = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            am.canScheduleExactAlarms()
        if (exactAllowed) {
            val info = AlarmManager.AlarmClockInfo(
                triggerAtMillis,
                pi, // shown as the "show intent" when the user taps the clock icon
            )
            am.setAlarmClock(info, pi)
        } else {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
        }
    }

    /** Cancel a previously scheduled alarm. */
    fun cancel(context: Context, notifId: Int) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        // Recreate an equivalent PendingIntent (extras don't need to match for cancel)
        val pi = buildPendingIntent(context, notifId, "", "", "", "")
        am.cancel(pi)
        pi.cancel()
        
        // Clean up both the payload and metadata immediately
        removeAlarm(context, notifId)
        
        // Also cancel any pending retry alarm
        val retryIntent = Intent(context, DimiRetryReceiver::class.java).apply {
            action = "com.dimi.dimi_app.RETRY_NOTIFICATION.$notifId"
        }
        val retryPi = PendingIntent.getBroadcast(
            context,
            notifId + 700000000,
            retryIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        am.cancel(retryPi)
        retryPi.cancel()
    }
    
    /** 
     * Remove all stored alarm metadata older than 24 hours.
     * Called by Flutter during app startup to prevent ghost alarms.
     */
    fun cleanupStaleEntries(context: Context) {
        val now = System.currentTimeMillis()
        cleanupStore(deviceAlarmPrefs(context), now)
        cleanupStore(legacyDeviceAlarmPrefs(context), now)
    }

    fun isCurrent(context: Context, notifId: Int, payload: String): Boolean =
        listOf(deviceAlarmPrefs(context), legacyDeviceAlarmPrefs(context)).any {
            it.getString(PAYLOAD_PREFIX + notifId, null) == payload
        }

    private fun cleanupStore(prefs: android.content.SharedPreferences, now: Long) {
        val editor = prefs.edit()
        for ((key, value) in prefs.all.filterKeys { it.startsWith(METADATA_PREFIX) }) {
            try {
                val ageHours = (now - JSONObject(value as String).getLong("triggerAtMillis")) / (1000 * 60 * 60)
                if (ageHours > 24) {
                    val id = key.removePrefix(METADATA_PREFIX).toInt()
                    editor.remove(PAYLOAD_PREFIX + id).remove(key)
                }
            } catch (_: Exception) { editor.remove(key) }
        }
        editor.apply()
    }

    /** Reinstalls only the native alarms that Android cleared during reboot. */
    fun restoreAfterBoot(context: Context) {
        val prefs = alarmPrefs(context)
        val now = System.currentTimeMillis()
        val metadata = (prefs.all.asSequence() + legacyDeviceAlarmPrefs(context).all.asSequence())
            .filter { it.key.startsWith(METADATA_PREFIX) }
            .distinctBy { it.key }
            .toList()
        
        // Spread out overdue alarms by 2 seconds each to prevent simultaneous
        // notification flood after unlock. First overdue alarm fires immediately.
        var overdueDelaySeconds = 0

        for ((key, value) in metadata) {
            val json = value as? String ?: continue
            try {
                val data = JSONObject(json)
                val triggerAtMillis = data.getLong("triggerAtMillis")
                val notifId = key.removePrefix(METADATA_PREFIX).toInt()
                
                // If alarm is more than 24 hours old, skip it — it's stale.
                // Flutter will reconcile from the database on next app launch.
                val ageHours = (now - triggerAtMillis) / (1000 * 60 * 60)
                if (ageHours > 24) {
                    // Clean up the stale entry
                    prefs.edit()
                        .remove(PAYLOAD_PREFIX + notifId)
                        .remove(METADATA_PREFIX + notifId)
                        .apply()
                    continue
                }
                
                // If Android rebooted across the trigger time, stagger delivery
                // to prevent all notifications firing simultaneously after unlock.
                val effectiveTrigger = if (triggerAtMillis <= now) {
                    now + (overdueDelaySeconds * 2000L) + 500L
                    .also { overdueDelaySeconds++ }
                } else {
                    triggerAtMillis
                }
                
                schedule(
                    context = context,
                    triggerAtMillis = effectiveTrigger,
                    notifId = notifId,
                    payload = data.getString("payload"),
                    title = data.getString("title"),
                    body = data.getString("body"),
                    type = data.getString("type"),
                )
            } catch (_: Exception) {
                // Ignore one malformed record; Flutter reconciliation will
                // rebuild valid alarms from the database on next app launch.
            }
        }
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
