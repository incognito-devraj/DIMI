package com.dimi.dimi_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class DimiRetryReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_NOTIF_ID, 0)
        val payload = intent.getStringExtra(EXTRA_PAYLOAD) ?: return
        if (!DimiAlarmScheduler.isCurrent(context, id, payload)) return
        DimiNotificationHelper.showFullScreen(
            context, id, payload,
            intent.getStringExtra(EXTRA_TITLE) ?: return,
            intent.getStringExtra(EXTRA_BODY) ?: "",
            intent.getStringExtra(EXTRA_TYPE) ?: "reminder",
            intent.getIntExtra(EXTRA_RETRY_COUNT, 1),
        )
    }
    companion object {
        const val EXTRA_NOTIF_ID = "dimi_retry_notif_id"
        const val EXTRA_PAYLOAD = "dimi_retry_payload"
        const val EXTRA_TITLE = "dimi_retry_title"
        const val EXTRA_BODY = "dimi_retry_body"
        const val EXTRA_TYPE = "dimi_retry_type"
        const val EXTRA_RETRY_COUNT = "dimi_retry_count"
    }
}
