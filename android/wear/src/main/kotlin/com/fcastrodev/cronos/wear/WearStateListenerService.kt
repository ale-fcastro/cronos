package com.fcastrodev.cronos.wear

import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService

class WearStateListenerService : WearableListenerService() {
    override fun onDataChanged(events: DataEventBuffer) {
        events.filter { it.type == DataEvent.TYPE_CHANGED && it.dataItem.uri.path == "/cronos/state" }
            .forEach { event ->
                DataMapItem.fromDataItem(event.dataItem).dataMap.getString("json")?.let {
                    WearStore.save(this, it)
                }
            }
    }
}
