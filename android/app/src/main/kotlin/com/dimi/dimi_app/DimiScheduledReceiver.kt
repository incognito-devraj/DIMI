package com.dimi.dimi_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager

/**
 * BroadcastReceiver that fires when an exact alarm set by DimiAlarmScheduler
 * is delivered by AlarmManager.
 *
 * A single native delivery path is used for foreground, background and
 * screen-off states so full-screen delivery does not depend on Flutter's UI
 * lifecycle.
 */
class DimiScheduledReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val notifId = intent.getIntExtra(EXTRA_NOTIF_ID, 0)
        val payload = intent.getStringExtra(EXTRA_PAYLOAD) ?: return
        val title   = intent.getStringExtra(EXTRA_TITLE)   ?: return
        val body    = intent.getStringExtra(EXTRA_BODY)    ?: ""
        val type    = intent.getStringExtra(EXTRA_TYPE)    ?: "reminder"
        if (!DimiAlarmScheduler.isCurrent(context, notifId, payload)) return

        // Acquire a wake lock so the CPU doesn't sleep before we finish.
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        @Suppress("DEPRECATION")
        val wl = pm.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
            PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "dimi:receiver_wake"
        )
        wl.acquire(5_000L) // 5-second safety cap

        try {
            // ── Path 1: app is in foreground ─────────────────────────────
            // Flutter receives the payload directly and navigates immediately.
            // No notification is posted — instant, silent, no heads-up delay.
            // ── Path 2: app is in background / killed / screen off ────────
            // Post a full-screen notification. The full-screen intent will
            // wake the screen and show DimiReminderActivity over the lock
            // screen.
            DimiNotificationHelper.showFullScreen(
                context = context,
                notifId = notifId,
                payload = payload,
                title   = title,
                body    = body,
                type    = type,
            )
        } finally {
            if (wl.isHeld) wl.release()
        }
    }

    companion object {
        const val EXTRA_NOTIF_ID = "dimi_notif_id"
        const val EXTRA_PAYLOAD  = "dimi_payload"
        const val EXTRA_TITLE    = "dimi_title"
        const val EXTRA_BODY     = "dimi_body"
        const val EXTRA_TYPE     = "dimi_type"
    }
}
