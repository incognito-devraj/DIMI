package com.dimi.dimi_app

import android.app.Activity
import android.graphics.Color
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/** Native lock-screen UI for alarms delivered before the first device unlock. */
class DimiDirectBootActivity : Activity() {
    private var player: MediaPlayer? = null
    private var handled = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
        )
        setShowWhenLocked(true)
        setTurnScreenOn(true)
        render()
        playAlarmTone()
    }

    private fun render() {
        val title = intent.getStringExtra("title") ?: "DIMI reminder"
        val body = intent.getStringExtra("body") ?: "You have a reminder."
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(40, 48, 40, 48)
            setBackgroundColor(Color.rgb(250, 246, 236))
        }
        content.addView(TextView(this).apply {
            text = "DIMI"
            textSize = 22f
            gravity = Gravity.CENTER
            setTextColor(Color.rgb(25, 25, 25))
        })
        content.addView(TextView(this).apply {
            text = title
            textSize = 30f
            gravity = Gravity.CENTER
            setTextColor(Color.rgb(25, 25, 25))
            setPadding(0, 32, 0, 12)
        })
        content.addView(TextView(this).apply {
            text = body
            textSize = 18f
            gravity = Gravity.CENTER
            setTextColor(Color.DKGRAY)
        })
        val actions = LinearLayout(this).apply {
            gravity = Gravity.CENTER
            setPadding(0, 36, 0, 0)
        }
        actions.addView(Button(this).apply {
            text = "Snooze 5 min"
            setOnClickListener { handleAction("dimi_snooze") }
        }, LinearLayout.LayoutParams(0, -2, 1f))
        actions.addView(Button(this).apply {
            text = "Mark Done"
            setOnClickListener { handleAction("dimi_mark_done") }
        }, LinearLayout.LayoutParams(0, -2, 1f))
        content.addView(actions)
        setContentView(content)
    }

    private fun playAlarmTone() {
        val media = MediaPlayer()
        player = media
        try {
            media.setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build())
            media.setDataSource(
                this,
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE),
            )
            media.setOnPreparedListener { it.start() }
            media.setOnCompletionListener {
                // Loop indefinitely until user interaction (matches DimiReminderActivity behavior)
                if (!handled) {
                    it.start()
                }
            }
            media.setOnErrorListener { _, _, _ ->
                showFallbackAndFinish()
                true
            }
            media.prepareAsync()
        } catch (_: Exception) {
            showFallbackAndFinish()
        }
    }

    private fun finishRinging() {
        if (handled) return
        handled = true
        stopPlayer()
        DimiNotificationHelper.showShadeFallback(
            this,
            intent.getIntExtra("notificationId", 0),
            intent.getStringExtra("title") ?: "DIMI reminder",
            intent.getStringExtra("body") ?: "You have a reminder.",
        )
        finishAndRemoveTask()
    }

    private fun showFallbackAndFinish() {
        if (handled) return
        handled = true
        stopPlayer()
        DimiNotificationHelper.showShadeFallback(
            this,
            intent.getIntExtra("notificationId", 0),
            intent.getStringExtra("title") ?: "DIMI reminder",
            intent.getStringExtra("body") ?: "You have a reminder.",
        )
        finishAndRemoveTask()
    }

    private fun handleAction(action: String) {
        if (handled) return
        handled = true
        stopPlayer()
        val id = intent.getIntExtra("notificationId", 0)
        val payload = intent.getStringExtra("payload") ?: ""
        val title = intent.getStringExtra("title") ?: "DIMI reminder"
        val body = intent.getStringExtra("body") ?: "You have a reminder."
        val type = intent.getStringExtra("type") ?: "reminder"
        if (id > 0 && payload.isNotBlank()) {
            DimiNotificationHelper.cancel(this, id)
            DimiAlarmScheduler.cancel(this, id)
            if (action == "dimi_snooze") {
                DimiAlarmScheduler.schedule(
                    context = this,
                    triggerAtMillis = System.currentTimeMillis() + 5 * 60 * 1000L,
                    notifId = id,
                    payload = payload,
                    title = title,
                    body = body,
                    type = type,
                )
            }
            DimiDirectBootActionStore.enqueue(this, id, action, payload)
        }
        finishAndRemoveTask()
    }

    private fun stopPlayer() {
        player?.let { media ->
            try {
                if (media.isPlaying) media.stop()
            } catch (_: IllegalStateException) {
                // It may still be preparing when the user acts.
            } finally {
                media.release()
            }
        }
        player = null
    }

    override fun onDestroy() {
        stopPlayer()
        super.onDestroy()
    }
}
