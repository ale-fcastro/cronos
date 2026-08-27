package com.example.cronos.wear

import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

class WearActionListenerService : WearableListenerService() {
    override fun onMessageReceived(event: MessageEvent) {
        if (event.path == "/cronos/action") {
            PhoneWearBridge.enqueueAction(this, String(event.data, Charsets.UTF_8))
        }
    }
}
