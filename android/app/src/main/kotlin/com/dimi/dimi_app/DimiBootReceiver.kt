package com.dimi.dimi_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.util.concurrent.Executors

/**
 * Restores DIMI's native exact alarms after Android clears AlarmManager state
 * during a reboot or package replacement. This does not start Flutter, touch
 * the database, or create a long-running service.
 */
class DimiBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.LOCKED_BOOT_COMPLETED",
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> {
                // Alarm restoration can involve many persisted entries. Keep
                // that work off Android's broadcast thread so boot completion
                // and other receivers are not held up by Flutter or disk I/O.
                val pendingResult = goAsync()
                bootExecutor.execute {
                    try {
                        // This path uses only device-protected native state; it
                        // does not wait for Flutter, Drift, or network access.
                        DimiAlarmScheduler.restoreAfterBoot(context.applicationContext)
                    } finally {
                        pendingResult.finish()
                    }
                }
            }
        }
    }

    private companion object {
        // Serial execution makes LOCKED_BOOT_COMPLETED followed by
        // BOOT_COMPLETED idempotent even when both arrive close together.
        val bootExecutor = Executors.newSingleThreadExecutor()
    }
}
