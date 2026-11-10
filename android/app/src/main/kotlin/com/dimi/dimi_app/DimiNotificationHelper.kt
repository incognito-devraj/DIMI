package com.dimi.dimi_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import android.app.KeyguardManager
import android.os.UserManager
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

    // v7 full-screen channels are silent. DimiReminderActivity plays the
    // ringtone itself; channel audio here would play a second copy.
    private const val CHANNEL_REMINDER  = "dimi_fullscreen_reminder_v7"
    private const val CHANNEL_PLANNER   = "dimi_fullscreen_planner_v7"
    private const val CHANNEL_YOUTUBE   = "dimi_fullscreen_youtube_v7"
    private const val CHANNEL_FALLBACK  = "dimi_notification_fallback_v6"
    private const val CHANNEL_HEADS_UP  = "dimi_notification_heads_up_v6"

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
                // The activity is the only ringtone player for a full-screen
                // alarm. Keep the notification itself silent to avoid doubling it.
                setSound(null, null)
            }

        nm.createNotificationChannel(make(CHANNEL_REMINDER, "Reminders",
                Color.parseColor("#F5A623")))
        nm.createNotificationChannel(make(CHANNEL_PLANNER,  "Planner",
                Color.parseColor("#F5A623")))
        nm.createNotificationChannel(make(CHANNEL_YOUTUBE,  "YouTube",
                Color.parseColor("#E53935")))

        // Normal (non-full-screen) notification channels: phone's default NOTIFICATION tone.
        nm.createNotificationChannel(NotificationChannel(
            CHANNEL_FALLBACK, "DIMI notifications", NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "DIMI standard notifications"
            enableLights(true)
            lightColor = Color.parseColor("#F5A623")
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 250, 120, 250)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            val tone = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            setSound(tone, attrs)
        })
        nm.createNotificationChannel(NotificationChannel(
            CHANNEL_HEADS_UP, "DIMI alerts", NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "DIMI notification popups"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 250, 120, 250)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            val tone = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            setSound(tone, attrs)
        })
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
        retryCount: Int = 0,
    ) {
        ensureChannels(context)

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
        val isDirectBoot = Build.VERSION.SDK_INT >= Build.VERSION_CODES.N &&
            try {
                !(context.getSystemService(Context.USER_SERVICE) as UserManager).isUserUnlocked
            } catch (_: Exception) {
                // Some vendor ROMs (Samsung, Xiaomi) throw SecurityException here.
                // Treat as "not Direct Boot" so the alarm still posts normally.
                false
            }
        // Android can report FSI access as unavailable during Direct Boot even
        // when the app is allowed to use it after the first unlock. Keep the
        // alarm channel for this delivery and let System UI evaluate the FSI.
        val fullScreenAllowed = isDirectBoot || Build.VERSION.SDK_INT < 34 ||
            nm.canUseFullScreenIntent()
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val keyguard = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val screenIsOffOrLocked = !power.isInteractive || keyguard.isKeyguardLocked
        val channelId = if (!fullScreenAllowed) {
            CHANNEL_FALLBACK
        } else if (screenIsOffOrLocked) {
            // Use AUDIBLE alarm channels when screen is off/locked so the notification
            // itself plays sound (Android 8+ requires channel-level audio config).
            // DimiReminderActivity also plays the ringtone, creating a loud, persistent
            // alarm experience. The brief overlap is intentional and matches how the
            // system Clock app works.
            when (type) {
                "planner" -> CHANNEL_PLANNER
                "playlist", "watch" -> CHANNEL_YOUTUBE
                else -> CHANNEL_REMINDER
            }
        } else {
            CHANNEL_HEADS_UP
        }
        val accentColor = when (type) {
            "playlist", "watch" -> Color.parseColor("#E53935")
            else                -> Color.parseColor("#F5A623")
        }

        // Build an intent that opens DimiReminderActivity directly.
        // The SELECT_NOTIFICATION action and "payload" extra make the
        // flutter_local_notifications response handler work normally.
        fun makeIntent(actionId: String? = null, requestCode: Int = notifId): PendingIntent {
            val target = if (isDirectBoot) DimiDirectBootActivity::class.java
                else DimiReminderActivity::class.java
            val i = Intent(context, target).apply {
                action = "SELECT_NOTIFICATION"
                // PendingIntent identity ignores extras. A URI keeps each
                // notification/action token distinct even when IDs are
                // consecutive (requestCode + 1/+2/+3 can otherwise collide).
                data = Uri.parse(
                    "dimi-notification://${context.packageName}/$notifId/" +
                        "${requestCode}/${actionId ?: "open"}"
                )
                putExtra("payload", payload)
                putExtra("notificationId", notifId)
                putExtra("title", title)
                putExtra("body", body)
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
            .setSilent(false)
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

        // Notification channels are unavailable before Android O. Keep the
        // full-screen alarm silent there too; the Activity plays the ringtone.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            if (fullScreenAllowed && screenIsOffOrLocked) {
                builder.setSound(null)
            } else {
                builder.setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                )
            }
        }

        // Build the notification then stamp FLAG_INSISTENT onto it directly —
        // the extras-based approach does not reliably propagate the flag.
        val notif = builder.build()
        nm.notify(notifId, notif)
        scheduleRetry(context, notifId, payload, title, body, type, retryCount)

        // Android owns delivery of the full-screen intent when the display is
        // off or the keyguard is showing. When the user is actively using the
        // phone, Android intentionally downgrades it to a heads-up alert; in
        // that case we launch the same dedicated activity ourselves so DIMI's
        // explicit full-screen preference is consistent without launching the
        // normal MainActivity.
        // Android chooses the full-screen activity only while locked/off.
        // While unlocked this remains a heads-up alarm popup.
    }

    private fun scheduleRetry(
        context: Context, notifId: Int, payload: String, title: String,
        body: String, type: String, retryCount: Int,
    ) {
        if (retryCount >= 2) return
        val intent = Intent(context, DimiRetryReceiver::class.java).apply {
            action = "com.dimi.dimi_app.RETRY_NOTIFICATION.$notifId"
            putExtra(DimiRetryReceiver.EXTRA_NOTIF_ID, notifId)
            putExtra(DimiRetryReceiver.EXTRA_PAYLOAD, payload)
            putExtra(DimiRetryReceiver.EXTRA_TITLE, title)
            putExtra(DimiRetryReceiver.EXTRA_BODY, body)
            putExtra(DimiRetryReceiver.EXTRA_TYPE, type)
            putExtra(DimiRetryReceiver.EXTRA_RETRY_COUNT, retryCount + 1)
        }
        val pi = PendingIntent.getBroadcast(context, notifId + 700000000, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        alarm.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP,
            System.currentTimeMillis() + 5 * 60 * 1000L, pi)
    }

    /** Cancel a specific notification (mirrors flutter_local_notifications cancel). */
    fun cancel(context: Context, notifId: Int) {
        NotificationManagerCompat.from(context).cancel(notifId)
        cancelRetry(context, notifId)
    }

    /** Leaves a single audible, ordinary shade notification after the alarm UI ends. */
    fun showShadeFallback(context: Context, notifId: Int, title: String, body: String) {
        ensureChannels(context)
        val notification = NotificationCompat.Builder(context, CHANNEL_FALLBACK)
            .setSmallIcon(R.drawable.dimi_small_status_icon)
            .setContentTitle(title)
            .setContentText(body)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setOngoing(false)
            .setTimeoutAfter(5 * 60 * 1000L)
            .build()
        NotificationManagerCompat.from(context).notify(notifId, notification)
    }

    fun cancelRetry(context: Context, notifId: Int) {
        val pi = PendingIntent.getBroadcast(context, notifId + 700000000,
            Intent(context, DimiRetryReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        alarm.cancel(pi)
        pi.cancel()
    }
}
