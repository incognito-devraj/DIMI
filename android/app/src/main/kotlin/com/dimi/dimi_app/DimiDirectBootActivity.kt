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

/** Native first-stage alarm UI used before the device's first PIN unlock. */
class DimiDirectBootActivity : Activity() {
    private var player: MediaPlayer? = null
    private var completed = false
    private var rings = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON,
        )
        setShowWhenLocked(true)
        setTurnScreenOn(true)
        DimiNotificationHelper.clearVisible(this, intent.getIntExtra("notificationId", 0))
        render()
        val action = intent.getStringExtra("actionId")
        if (action != null) handleAction(action) else startRingtone()
    }

    private fun render() {
        val title = intent.getStringExtra("title") ?: "DIMI reminder"
        val body = intent.getStringExtra("body") ?: "You have a reminder."
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
            setBackgroundColor(Color.rgb(250, 246, 236))
        }
        root.addView(TextView(this).apply {
            text = "DIMI"
            textSize = 24f
            setTextColor(Color.rgb(25, 25, 25))
            gravity = Gravity.CENTER
        }, LinearLayout.LayoutParams(-1, -2))
        root.addView(TextView(this).apply {
            text = title
            textSize = 30f
            setTextColor(Color.rgb(25, 25, 25))
            gravity = Gravity.CENTER
            setPadding(0, 36, 0, 12)
        }, LinearLayout.LayoutParams(-1, -2))
        root.addView(TextView(this).apply {
            text = body
            textSize = 18f
            setTextColor(Color.DKGRAY)
            gravity = Gravity.CENTER
        }, LinearLayout.LayoutParams(-1, -2))
        val actions = LinearLayout(this).apply {
            gravity = Gravity.CENTER
            setPadding(0, 42, 0, 0)
        }
        actions.addView(Button(this).apply {
            text = "Snooze 5 min"
            setOnClickListener { handleAction("dimi_snooze") }
        }, LinearLayout.LayoutParams(0, -2, 1f))
        actions.addView(Button(this).apply {
            text = "Mark Done"
            setOnClickListener { handleAction("dimi_mark_done") }
        }, LinearLayout.LayoutParams(0, -2, 1f))
        root.addView(actions, LinearLayout.LayoutParams(-1, -2))
        setContentView(root)
    }

    private fun startRingtone() {
        val media = MediaPlayer()
        player = media
        media.setAudioAttributes(AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build())
        media.setDataSource(this, RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE))
        media.setOnCompletionListener {
            rings++
            if (rings >= 3) finishAlarm() else it.start()
        }
        media.prepare()
        media.start()
    }

    private fun handleAction(action: String) {
        if (completed) return
        completed = true
        stopRingtone()
        val id = intent.getIntExtra("notificationId", 0)
        val payload = intent.getStringExtra("payload") ?: ""
        val title = intent.getStringExtra("title") ?: "DIMI reminder"
        val body = intent.getStringExtra("body") ?: "You have a reminder."
        val type = intent.getStringExtra("type") ?: "reminder"
        if (id != 0 && payload.isNotBlank()) {
            DimiNotificationHelper.cancel(this, id)
            if (action == "dimi_snooze") {
                DimiAlarmScheduler.schedule(
                    this, System.currentTimeMillis() + 5 * 60 * 1000L,
                    id, payload, title, body, type,
                )
            } else {
                DimiAlarmScheduler.cancel(this, id)
            }
            DimiDirectBootActionStore.enqueue(this, id, action, payload)
        }
        finishAndRemoveTask()
    }

    private fun finishAlarm() {
        if (completed) return
        completed = true
        stopRingtone()
        val id = intent.getIntExtra("notificationId", 0)
        if (id != 0) DimiNotificationHelper.showShadeFallback(
            this, id,
            intent.getStringExtra("title") ?: "DIMI reminder",
            intent.getStringExtra("body") ?: "You have a reminder.",
        )
        finishAndRemoveTask()
    }

    private fun stopRingtone() {
        player?.let { if (it.isPlaying) it.stop(); it.release() }
        player = null
    }

    override fun onDestroy() {
        stopRingtone()
        super.onDestroy()
    }
}
