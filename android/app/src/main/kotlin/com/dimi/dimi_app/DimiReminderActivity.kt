package com.dimi.dimi_app

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

/**
 * Dedicated full-screen entry point for reminder / planner notifications.
 *
 * Key design goals:
 *  1. Fires immediately — screen comes on with no delay, no white flash.
 *  2. Shows over the lock screen even when the phone is completely off.
 *  3. Never opens MainActivity first — the full-screen intent points here
 *     directly via DimiNotificationHelper.
 *  4. Transparent window background set before super.onCreate() prevents
 *     the brief white Flutter engine boot flash.
 */
class DimiReminderActivity : FlutterActivity() {

    private var _wakeLock: PowerManager.WakeLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // ── 1. Transparent background before engine starts ────────────────
        // This is the single most effective way to prevent the white flash:
        // the window is invisible while Flutter renders its first frame.
        window.setBackgroundDrawableResource(android.R.color.transparent)

        // ── 2. Wake screen + show over lock screen (all API levels) ───────
        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED      or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD      or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON        or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON        or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
        )

        // ── 3. API 27+ equivalents (Oreo+) ────────────────────────────────
        setShowWhenLocked(true)
        setTurnScreenOn(true)

        // ── 4. Dismiss keyguard on API 27+ ────────────────────────────────
        val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        km.requestDismissKeyguard(this, null)

        // ── 5. Acquire a brief CPU wake lock so the broadcast receiver's
        //    work completes even if the CPU tries to go back to sleep ───────
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        @Suppress("DEPRECATION")
        _wakeLock = pm.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
            PowerManager.ACQUIRE_CAUSES_WAKEUP   or
            PowerManager.ON_AFTER_RELEASE,
            "dimi:reminder_wake"
        ).also { it.acquire(10_000L) } // 10-second safety cap

        super.onCreate(savedInstanceState)
    }

    override fun onDestroy() {
        _wakeLock?.let { if (it.isHeld) it.release() }
        _wakeLock = null
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
