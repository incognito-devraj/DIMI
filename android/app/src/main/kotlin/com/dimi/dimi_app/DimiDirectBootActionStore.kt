package com.dimi.dimi_app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Stores reminder actions taken before credential-protected app data is available. */
object DimiDirectBootActionStore {
    private const val PREFS = "dimi_direct_boot_actions"
    private const val KEY_PENDING = "pending"

    private fun prefs(context: Context) = context
        .createDeviceProtectedStorageContext()
        .getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    @Synchronized
    fun enqueue(context: Context, id: Int, action: String, payload: String) {
        val store = prefs(context)
        val pending = JSONArray(store.getString(KEY_PENDING, "[]") ?: "[]")
        pending.put(JSONObject().apply {
            put("id", id)
            put("action", action)
            put("payload", payload)
        })
        store.edit().putString(KEY_PENDING, pending.toString()).apply()
    }

    @Synchronized
    fun consume(context: Context): String {
        val store = prefs(context)
        val pending = store.getString(KEY_PENDING, "[]") ?: "[]"
        store.edit().remove(KEY_PENDING).apply()
        return pending
    }
}
