package com.example.cronos.wear

import android.content.Context
import org.json.JSONObject

data class WearTask(val id: String, val title: String, val running: Boolean, val startedAt: Long?)
data class WearState(val tasks: List<WearTask>, val updatedAt: Long)

object WearStore {
    private const val PREFS = "cronos_state"
    private const val JSON = "json"

    fun save(context: Context, json: String) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(JSON, json).apply()

    fun load(context: Context): WearState {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(JSON, null)
            ?: return WearState(emptyList(), 0)
        return runCatching {
            val root = JSONObject(raw)
            val values = root.optJSONArray("tasks")
            val tasks = (0 until (values?.length() ?: 0)).map { index ->
                val item = values!!.getJSONObject(index)
                WearTask(
                    item.getString("id"), item.getString("title"),
                    item.optBoolean("running"), item.optLong("startedAt").takeIf { it > 0 },
                )
            }
            WearState(tasks, root.optLong("updatedAt"))
        }.getOrDefault(WearState(emptyList(), 0))
    }
}
