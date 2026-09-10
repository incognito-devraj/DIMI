package com.dimi.dimi_app

import io.flutter.embedding.android.FlutterActivity
import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val channelName = "com.dimi.dimi_app/transaction_detection"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            val store = getSharedPreferences("dimi_transaction_events", MODE_PRIVATE)
            when (call.method) {
                "isNotificationAccessEnabled" -> {
                    val component = ComponentName(this, DimiNotificationListenerService::class.java)
                    result.success(Settings.Secure.getString(contentResolver, "enabled_notification_listeners")?.contains(component.flattenToString()) == true)
                }
                "openNotificationAccessSettings" -> { startActivity(Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")); result.success(null) }
                "getPendingTransactionEvents" -> result.success(store.getStringSet("pending", emptySet())!!.mapNotNull { store.getString("event_$it", null)?.let { json -> org.json.JSONObject(json).takeIf { it.isFinancialNotification() }?.toMap() } })
                "getNotificationFeed" -> result.success(store.getStringSet("history", emptySet())!!.mapNotNull { store.getString("event_$it", null)?.let { json -> org.json.JSONObject(json).takeIf { it.isFinancialNotification() }?.toMap() } })
                "clearNotificationFeed" -> { store.edit().putStringSet("history", emptySet()).apply(); result.success(null) }
                "acknowledgeTransactionEvent" -> { val id = call.argument<String>("id"); if (id != null) { store.edit().remove("event_$id").putStringSet("pending", (store.getStringSet("pending", emptySet()) ?: emptySet()) - id).apply() }; result.success(null) }
                "getDetectionMode" -> {
                    val settings = getSharedPreferences("dimi_settings", MODE_PRIVATE)
                    val current = settings.getString("detection_mode", null)
                    // Migrate the previous conservative default once. Users
                    // can still choose Detect & Ask or Off afterwards.
                    if (!settings.getBoolean("automatic_default_migrated", false) && (current == null || current == "Detect & Ask")) {
                        settings.edit().putString("detection_mode", "Auto-add high confidence").putBoolean("automatic_default_migrated", true).apply()
                        result.success("Auto-add high confidence")
                    } else result.success(current ?: "Auto-add high confidence")
                }
                "setDetectionMode" -> { getSharedPreferences("dimi_settings", MODE_PRIVATE).edit().putString("detection_mode", call.argument<String>("mode") ?: "Off").putBoolean("automatic_default_migrated", true).apply(); result.success(null) }
                else -> result.notImplemented()
            }
        }
    }
}

private fun org.json.JSONObject.isFinancialNotification(): Boolean = FinancialNotificationFilter.isRelevant(optString("sourcePackage"), listOf(optString("title"), optString("body"), optString("bigText")).joinToString(" "))
private fun org.json.JSONObject.toMap(): Map<String, Any?> = keys().asSequence().associateWith { key -> when (val value = get(key)) { JSONObject.NULL -> null; else -> value } }
