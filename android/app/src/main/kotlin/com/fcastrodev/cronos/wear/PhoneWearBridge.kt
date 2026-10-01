package com.fcastrodev.cronos.wear

import android.content.Context
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

object PhoneWearBridge {
    private const val PREFS = "cronos_wear"
    private const val ACTIONS = "pending_actions"

    fun publishState(context: Context, state: Map<String, Any?>, result: MethodChannel.Result) {
        val request = PutDataMapRequest.create("/cronos/state").apply {
            dataMap.putString("json", JSONObject(state).toString())
            dataMap.putLong("updatedAt", System.currentTimeMillis())
        }.asPutDataRequest().setUrgent()
        Wearable.getDataClient(context).putDataItem(request)
            .addOnSuccessListener { result.success(null) }
            .addOnFailureListener { result.error("WEAR_SYNC", it.message, null) }
    }

    fun enqueueAction(context: Context, json: String) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val items = JSONArray(prefs.getString(ACTIONS, "[]"))
        items.put(JSONObject(json))
        prefs.edit().putString(ACTIONS, items.toString()).apply()
    }

    fun takePendingActions(context: Context): List<Map<String, Any?>> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val items = JSONArray(prefs.getString(ACTIONS, "[]"))
        prefs.edit().remove(ACTIONS).apply()
        return (0 until items.length()).map { index ->
            val item = items.getJSONObject(index)
            item.keys().asSequence().associateWith { key -> item.opt(key) }
        }
    }
}
