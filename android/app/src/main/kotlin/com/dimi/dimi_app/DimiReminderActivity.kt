package com.dimi.dimi_app

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.PowerManager
import android.media.MediaPlayer
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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

    private val reminderChannel = "com.dimi.dimi_app/reminder_intent"
    private val alarmChannel = "com.dimi.dimi_app/alarm_scheduler"

    private var _wakeLock: PowerManager.WakeLock? = null
    private var ringtonePlayer: MediaPlayer? = null
    private var alarmRingingFinished = false
    private var shadeFallbackShown = false

    override fun onCreate(savedInstanceState: Bundle?) {
        val actionIntent = intent.getStringExtra("actionId") != null

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

        // Action buttons use this activity as a direct PendingIntent so the
        // payload can be handed to Flutter. They are not a new alarm event:
        // never start the ringtone again when Mark Done/Snooze is pressed.
        // Starting it here was the cause of the ringtone continuing after a
        // normal notification action was tapped.
        if (!actionIntent) {
            // Cancel any pending retry alarm immediately — the full-screen
            // activity is already visible so a retry firing 5 minutes later
            // would just play a second ringtone on top of the existing one.
            val notifId = intent.getIntExtra("notificationId", 0)
            if (notifId != 0) DimiNotificationHelper.cancelRetry(this, notifId)

            // Play only after the native alarm window exists, so Flutter engine
            // startup cannot lead the audio by a second or two.
            playThreeRings()
        }

        super.onCreate(savedInstanceState)

    }

    private fun playThreeRings() {
        val player = MediaPlayer()
        ringtonePlayer = player
        try {
            player.setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build())
            player.setDataSource(
                this,
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE),
            )
            player.setOnCompletionListener {
                // Loop the ringtone indefinitely until the user interacts with the alarm.
                // This matches the behavior of system alarm apps (Clock, Phone) and ensures
                // the alarm continues until explicitly dismissed, snoozed, or marked done.
                if (!alarmRingingFinished) {
                    it.start()
                }
            }
            player.prepare()
            player.start()
        } catch (_: Exception) {
            // A missing or unavailable system ringtone must not crash the
            // lock-screen activity before Flutter has a chance to render.
            ringtonePlayer = null
            player.release()
        }
    }

    private fun stopRingtone() {
        alarmRingingFinished = true
        ringtonePlayer?.let {
            if (it.isPlaying) it.stop()
            it.release()
        }
        ringtonePlayer = null
        val notificationId = intent.getIntExtra("notificationId", 0)
        val title = intent.getStringExtra("title") ?: "DIMI reminder"
        val body = intent.getStringExtra("body") ?: "You have a reminder."
        if (alarmRingingFinished && !shadeFallbackShown && notificationId != 0) {
            shadeFallbackShown = true
            DimiNotificationHelper.showShadeFallback(this, notificationId, title, body)
            window.decorView.postDelayed({ finishAndRemoveTask() }, 250L)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, reminderChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "getReminderIntent") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val payload = intent.getStringExtra("payload")
                if (payload.isNullOrBlank()) {
                    result.success(null)
                } else {
                    result.success(mapOf(
                        "payload" to payload,
                        "notificationId" to intent.getIntExtra("notificationId", 0),
                        "actionId" to intent.getStringExtra("actionId"),
                    ))
                    intent.removeExtra("payload")
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, alarmChannel)
            .setMethodCallHandler { call, result ->
                val id = call.argument<Int>("notifId") ?: 0
                when (call.method) {
                    "cancel" -> {
                        DimiAlarmScheduler.cancel(this, id)
                        DimiNotificationHelper.cancel(this, id)
                        result.success(null)
                    }
                    "cancelRetry" -> {
                        DimiNotificationHelper.cancelRetry(this, id)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        _wakeLock?.let { if (it.isHeld) it.release() }
        _wakeLock = null
        stopRingtone()
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        if (intent.getStringExtra("actionId") != null) {
            // An action can arrive while the alarm activity is already open.
            // Stop any existing alarm audio before forwarding the action.
            alarmRingingFinished = false
            stopRingtone()
        }
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
