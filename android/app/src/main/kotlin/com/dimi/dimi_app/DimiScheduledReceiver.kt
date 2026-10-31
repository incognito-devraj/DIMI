package com.dimi.dimi_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * BroadcastReceiver that fires when an exact alarm set by DimiAlarmScheduler
 * is delivered by the system.  It pulls the notification data from the intent
 * extras and delegates to DimiNotificationHelper to post a full-screen
 * notification that targets DimiReminderActivity directly.
 *
 * This receiver is the native-side counterpart to flutter_local_notifications'
 * ScheduledNotificationReceiver — it exists because the plugin cannot be
 * configured to use a custom activity as the full-screen intent target.
 */
class DimiScheduledReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val notifId  = intent.getIntExtra(EXTRA_NOTIF_ID,   0)
        val payload  = intent.getStringExtra(EXTRA_PAYLOAD) ?: return
        val title    = intent.getStringExtra(EXTRA_TITLE)   ?: return
        val body     = intent.getStringExtra(EXTRA_BODY)    ?: ""
        val type     = intent.getStringExtra(EXTRA_TYPE)    ?: "reminder"

        DimiNotificationHelper.showFullScreen(
            context = context,
            notifId = notifId,
            payload = payload,
            title   = title,
            body    = body,
            type    = type,
        )
    }

    companion object {
        const val EXTRA_NOTIF_ID = "dimi_notif_id"
        const val EXTRA_PAYLOAD  = "dimi_payload"
        const val EXTRA_TITLE    = "dimi_title"
        const val EXTRA_BODY     = "dimi_body"
        const val EXTRA_TYPE     = "dimi_type"
    }
}
