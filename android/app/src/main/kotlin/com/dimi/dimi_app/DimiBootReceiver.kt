package com.dimi.dimi_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

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
                // Restore only native device-protected alarm records. This is
                // deliberately independent of Flutter, Drift, and Supabase so
                // a reboot cannot wait for login or network availability.
                DimiAlarmScheduler.restoreAfterBoot(context.applicationContext)
            }
        }
    }
}
