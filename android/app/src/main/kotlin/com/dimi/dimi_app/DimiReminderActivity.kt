package com.dimi.dimi_app

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Dedicated full-screen entry point for reminder / planner notifications.
 *
 * The OS launches this activity (via the full-screen intent or via the
 * MainActivity redirect) instead of MainActivity, so the main app UI
 * never flashes on screen before the full-screen notification UI appears.
 *
 * Flutter routing works the same way as in MainActivity — the
 * flutter_local_notifications plugin picks up the SELECT_NOTIFICATION
 * action and payload from onNewIntent / the launch intent and calls
 * onOpenFullScreenReminder, which navigates to DimiReminderScreen.
 */
class DimiReminderActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // Show on lock screen and turn screen on — same as before.
        setShowWhenLocked(true)
        setTurnScreenOn(true)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
