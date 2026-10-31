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

    override fun onCreate(savedInstanceState: Bundle?) {
        if (isFullScreenNotificationLaunch(intent)) {
            // Redirect to DimiReminderActivity BEFORE super.onCreate()
            // so Flutter engine never initialises in this process.
            // finish() first suppresses the window, then start the target.
            val redirect = Intent(this, DimiReminderActivity::class.java).apply {
                action = intent.action
                intent.extras?.let { putExtras(it) }
                // NEW_TASK so it doesn't inherit MainActivity's back stack
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
                    result.error(
                        "INSTALL_PERMISSION",
                        "Allow DIMI to install unknown apps, then try again.",
                        null,
                    )
                } catch (error: Exception) {
                    result.error("INSTALL_FAILED", error.message, null)
                }
            }
    }

    private fun configureNotificationWindow(source: Intent?) {
        val action = source?.action
        if (action == NOTIFICATION_SELECT_ACTION) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    /**
     * Returns true when this activity was launched by the flutter_local_notifications
     * plugin's full-screen intent (which always targets the launcher activity).
     * We detect this by checking for the notification payload extra that the
     * plugin attaches to every notification tap / full-screen launch intent.
     */
    private fun isFullScreenNotificationLaunch(source: Intent?): Boolean {
        if (source == null) return false
        val action = source.action ?: return false
        // The plugin sets SELECT_NOTIFICATION as the action for all notification
        // intents. If the payload contains a type that uses full-screen mode,
        // redirect to DimiReminderActivity instead.
        if (action != NOTIFICATION_SELECT_ACTION) return false
        val payload = source.getStringExtra("payload") ?: return false
        // Match both "type":"planner" and "type": "planner" (with/without space)
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
