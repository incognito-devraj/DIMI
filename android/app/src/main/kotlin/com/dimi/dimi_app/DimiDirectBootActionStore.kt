package com.dimi.dimi_app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Small device-protected queue for actions taken before the first unlock. */
object DimiDirectBootActionStore {
    private const val PREFS = "dimi_direct_boot_actions"
    private const val KEY = "pending"

    private fun prefs(context: Context) = context
        .createDeviceProtectedStorageContext()
        .getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    @Synchronized
    fun enqueue(context: Context, id: Int, action: String, payload: String) {
        val old = JSONArray(prefs(context).getString(KEY, "[]") ?: "[]")
        old.put(JSONObject().apply {
            put("id", id)
            put("action", action)
            put("payload", payload)
        })
        prefs(context).edit().putString(KEY, old.toString()).apply()
    }

    @Synchronized
    fun consume(context: Context): String {
        val p = prefs(context)
        val value = p.getString(KEY, "[]") ?: "[]"
        p.edit().remove(KEY).apply()
        return value
    }
}
