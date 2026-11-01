package com.dimi.dimi_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Builds and posts a full-screen notification that launches
 * DimiReminderActivity directly — bypassing flutter_local_notifications'
 * hard-coded getLaunchIntentForPackage() which always targets MainActivity.
 *
 * This mirrors how Phone/Clock/Alarm apps work on Android:
 *   • setFullScreenIntent  → wakes screen, shows over lock screen
 *   • setContentIntent     → tapping the shade banner opens the same activity
 *   • FLAG_INSISTENT        → ringtone loops until user acts
 *
 * Called from DimiScheduledReceiver when a scheduled alarm fires, or from
 * MainActivity via MethodChannel when Flutter wants to show a full-screen
 * reminder immediately.
 */
object DimiNotificationHelper {

    private const val CHANNEL_REMINDER  = "dimi_fullscreen_reminder_v2"
    private const val CHANNEL_PLANNER   = "dimi_fullscreen_planner_v2"
    private const val CHANNEL_YOUTUBE   = "dimi_fullscreen_youtube_v2"

    /** Call once at app startup (Application.onCreate or FlutterActivity.onCreate). */
    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager

        fun make(id: String, name: String, accent: Int) =
            NotificationChannel(id, name, NotificationManager.IMPORTANCE_HIGH).apply {
                description = "$name full-screen notifications"
                enableLights(true)
                lightColor = accent
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 400, 200, 400)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setBypassDnd(true)
                // Phone's default ringtone — must be set on the channel on Android 8+.
                // USAGE_NOTIFICATION keeps it audible even in priority DND modes.
                val ringtone = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                val audioAttrs = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                setSound(ringtone, audioAttrs)
            }

        nm.createNotificationChannel(make(CHANNEL_REMINDER, "Reminders",
                Color.parseColor("#F5A623")))
        nm.createNotificationChannel(make(CHANNEL_PLANNER,  "Planner",
                Color.parseColor("#F5A623")))
        nm.createNotificationChannel(make(CHANNEL_YOUTUBE,  "YouTube",
                Color.parseColor("#E53935")))
    }

    /**
     * Post a full-screen notification.
     *
     * @param notifId  stable integer id (same one flutter_local_notifications uses)
     * @param payload  JSON string forwarded as the "payload" extra so the
     *                 flutter_local_notifications handler can decode it
     * @param title    notification title
     * @param body     notification body
     * @param type     "planner" | "reminder" | "playlist" | "watch"
     */
    fun showFullScreen(
        context: Context,
        notifId: Int,
        payload: String,
        title: String,
        body: String,
        type: String,
    ) {
        ensureChannels(context)

        val channelId = when (type) {
            "planner"          -> CHANNEL_PLANNER
            "playlist", "watch"-> CHANNEL_YOUTUBE
            else               -> CHANNEL_REMINDER
        }
        val accentColor = when (type) {
            "playlist", "watch" -> Color.parseColor("#E53935")
            else                -> Color.parseColor("#F5A623")
        }

        // Build an intent that opens DimiReminderActivity directly.
        // The SELECT_NOTIFICATION action and "payload" extra make the
        // flutter_local_notifications response handler work normally.
        fun makeIntent(actionId: String? = null, requestCode: Int = notifId): PendingIntent {
            val i = Intent(context, DimiReminderActivity::class.java).apply {
                action = "SELECT_NOTIFICATION"
                putExtra("payload", payload)
                putExtra("notificationId", notifId)
                if (actionId != null) putExtra("actionId", actionId)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or
                         Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            val piFlags = PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE
            return PendingIntent.getActivity(context, requestCode, i, piFlags)
        }

        val fullScreenPi = makeIntent()
        val contentPi    = makeIntent(requestCode = notifId + 1)
        val markDonePi   = makeIntent("dimi_mark_done", notifId + 2)
        val snoozePi     = makeIntent("dimi_snooze", notifId + 3)

        // Always use the phone's default ringtone — users can override per-reminder
        // from within DIMI Settings, but the system default is the baseline.
        val ringtone = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.dimi_small_status_icon)
            .setContentTitle(title)
            .setContentText(body)
            .setColor(accentColor)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(false)           // user must interact, not swipe away
            .setOngoing(true)               // prevent dismissal by swipe
            .setSound(ringtone)
            .setVibrate(longArrayOf(0, 400, 200, 400))
            // Full-screen intent — fires immediately when screen is off / locked
            // highPriority=true tells the OS this must interrupt immediately
            .setFullScreenIntent(fullScreenPi, true)
            // Content intent — fires when user taps the shade banner
            .setContentIntent(contentPi)
            .addAction(NotificationCompat.Action.Builder(
                0, "Mark Done", markDonePi).build())
            .addAction(NotificationCompat.Action.Builder(
                0, "Snooze 5 min", snoozePi).build())
            .setShowWhen(true)

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
        // Build the notification then stamp FLAG_INSISTENT onto it directly —
        // the extras-based approach does not reliably propagate the flag.
        val notif = builder.build()
        notif.flags = notif.flags or Notification.FLAG_INSISTENT
        nm.notify(notifId, notif)

        // Android normally launches a full-screen intent only while the
        // screen is locked or off. DIMI's full-screen mode is user-selected,
        // so also deliver the same activity when the display is already on.
        // The PendingIntent is identical to the notification's content path,
        // keeping payload/action handling in one place.
        try {
            fullScreenPi.send()
        } catch (_: PendingIntent.CanceledException) {
            // The notification remains visible if the activity cannot launch.
        }
    }

    /** Cancel a specific notification (mirrors flutter_local_notifications cancel). */
    fun cancel(context: Context, notifId: Int) {
        NotificationManagerCompat.from(context).cancel(notifId)
    }
}
