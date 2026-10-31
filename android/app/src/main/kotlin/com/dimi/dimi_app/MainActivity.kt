package com.dimi.dimi_app

import android.content.Intent
import android.content.ClipData
import androidx.core.content.FileProvider
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val updateChannel = "com.dimi.dimi_app/update_installer"
    private val alarmChannel  = "com.dimi.dimi_app/alarm_scheduler"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Ensure notification channels exist before anything else
        DimiNotificationHelper.ensureChannels(this)

        if (isFullScreenNotificationLaunch(intent)) {
            // Redirect to DimiReminderActivity BEFORE super.onCreate() so
            // Flutter engine never initialises in this process context.
            val redirect = Intent(this, DimiReminderActivity::class.java).apply {
                action = intent.action
                intent.extras?.let { putExtras(it) }
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_NO_ANIMATION
            }
            finish()
            startActivity(redirect)
            overridePendingTransition(0, 0)
            return
        }

        configureNotificationWindow(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        configureNotificationWindow(intent)
        super.onNewIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── APK installer ─────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, updateChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "installApk") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val filePath = call.argument<String>("path")
                if (filePath.isNullOrBlank()) {
                    result.error("INVALID_PATH", "APK path is missing.", null)
                    return@setMethodCallHandler
                }
                try {
                    val apk = File(filePath)
                    if (!apk.isFile || !apk.canRead()) {
                        result.error("APK_NOT_FOUND", "Downloaded APK cannot be read.", null)
                        return@setMethodCallHandler
                    }
                    val apkUri = FileProvider.getUriForFile(
                        this,
                        "${applicationContext.packageName}.fileprovider",
                        apk,
                    )
                    val installerIntent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(apkUri, "application/vnd.android.package-archive")
                        clipData = ClipData.newRawUri("DIMI APK", apkUri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(installerIntent)
                    result.success(null)
                } catch (_: SecurityException) {
                    result.error("INSTALL_PERMISSION",
                        "Allow DIMI to install unknown apps, then try again.", null)
                } catch (error: Exception) {
                    result.error("INSTALL_FAILED", error.message, null)
                }
            }

        // ── Alarm scheduler ───────────────────────────────────────────────
        // Flutter calls this to schedule / cancel full-screen notifications
        // through DimiAlarmScheduler instead of flutter_local_notifications'
        // broken full-screen intent path.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, alarmChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val notifId         = call.argument<Int>("notifId") ?: 0
                        val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                        val payload         = call.argument<String>("payload") ?: ""
                        val title           = call.argument<String>("title") ?: ""
                        val body            = call.argument<String>("body") ?: ""
                        val type            = call.argument<String>("type") ?: "reminder"
                        DimiAlarmScheduler.schedule(
                            context         = this,
                            triggerAtMillis = triggerAtMillis,
                            notifId         = notifId,
                            payload         = payload,
                            title           = title,
                            body            = body,
                            type            = type,
                        )
                        result.success(null)
                    }
                    "cancel" -> {
                        val notifId = call.argument<Int>("notifId") ?: 0
                        DimiAlarmScheduler.cancel(this, notifId)
                        result.success(null)
                    }
                    "showImmediate" -> {
                        // For testing or snooze re-fire
                        val notifId = call.argument<Int>("notifId") ?: 0
                        val payload = call.argument<String>("payload") ?: ""
                        val title   = call.argument<String>("title") ?: ""
                        val body    = call.argument<String>("body") ?: ""
                        val type    = call.argument<String>("type") ?: "reminder"
                        DimiNotificationHelper.showFullScreen(
                            context = this,
                            notifId = notifId,
                            payload = payload,
                            title   = title,
                            body    = body,
                            type    = type,
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun configureNotificationWindow(source: Intent?) {
        if (source?.action == NOTIFICATION_SELECT_ACTION) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    private fun isFullScreenNotificationLaunch(source: Intent?): Boolean {
        if (source == null) return false
        val action = source.action ?: return false
        if (action != NOTIFICATION_SELECT_ACTION) return false
        val payload = source.getStringExtra("payload") ?: return false
        val fullScreenTypes = listOf("planner", "reminder", "playlist", "watch")
        return fullScreenTypes.any { type ->
            payload.contains("\"type\":\"$type\"") ||
            payload.contains("\"type\": \"$type\"")
        }
    }

    private companion object {
        const val NOTIFICATION_SELECT_ACTION = "SELECT_NOTIFICATION"
    }
}
