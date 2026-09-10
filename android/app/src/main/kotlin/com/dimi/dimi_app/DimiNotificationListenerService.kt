package com.dimi.dimi_app

import android.app.Notification
import android.content.ComponentName
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONObject

class DimiNotificationListenerService : NotificationListenerService() {
    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "DIMI_NOTIFICATION_LISTENER_CONNECTED")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val detectionMode = getSharedPreferences("dimi_settings", Context.MODE_PRIVATE).getString("detection_mode", "Detect & Ask")
        if (detectionMode == "Off") return
        val extras = sbn.notification.extras
        val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.take(160)
        val body = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.take(500)
        val bigText = extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.take(1000)
        val text = listOfNotNull(title, body, bigText).joinToString(" ").lowercase()
        val id = "${sbn.key}:${sbn.postTime}"
        if (!FinancialNotificationFilter.isRelevant(sbn.packageName, text)) return
        if ((applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0) Log.d(TAG, "DIMI_TRANSACTION_DETECTED packageName=${sbn.packageName} timestamp=${sbn.postTime}")
        val event = JSONObject().apply {
            put("id", id); put("sourcePackage", sbn.packageName); put("sourceType", "NOTIFICATION")
            put("title", title); put("body", body); put("bigText", bigText)
            put("timestamp", sbn.postTime); put("receivedAt", System.currentTimeMillis())
        }
        val store = getSharedPreferences("dimi_transaction_events", Context.MODE_PRIVATE)
        val pending = store.getStringSet("pending", emptySet())!!.toMutableSet()
        if (!store.contains("event_$id")) {
            if (pending.size >= 50) { val oldest = pending.firstOrNull(); if (oldest != null) { store.edit().remove("event_$oldest").apply(); pending.remove(oldest) } }
            val history = store.getStringSet("history", emptySet())!!.toMutableSet()
            if (history.size >= 50) { val oldest = history.firstOrNull(); if (oldest != null) history.remove(oldest) }
            store.edit().putString("event_$id", event.toString()).putStringSet("pending", pending.apply { add(id) }).putStringSet("history", history.apply { add(id) }).apply()
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        if ((applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0) Log.d(TAG, "DIMI_NOTIFICATION_REMOVED packageName=${sbn.packageName} timestamp=${System.currentTimeMillis()}")
    }

    companion object { private const val TAG = "DimiNotification" }
}
