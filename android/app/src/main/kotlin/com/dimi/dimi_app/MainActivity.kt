package com.dimi.dimi_app

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        configureNotificationWindow(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        configureNotificationWindow(intent)
        super.onNewIntent(intent)
    }

    private fun configureNotificationWindow(source: Intent?) {
        val action = source?.action
        if (action == NOTIFICATION_SELECT_ACTION) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    private companion object {
        const val NOTIFICATION_SELECT_ACTION =
            "SELECT_NOTIFICATION"
    }
}
