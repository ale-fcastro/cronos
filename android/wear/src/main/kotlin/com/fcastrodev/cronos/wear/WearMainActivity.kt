package com.fcastrodev.cronos.wear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Spacer
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import kotlinx.coroutines.delay
import org.json.JSONObject

class WearMainActivity : ComponentActivity(), DataClient.OnDataChangedListener {
    private var currentState by mutableStateOf(WearState(emptyList(), 0))

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        currentState = WearStore.load(this)
        setContent { CronosWear() }
    }

    override fun onResume() {
        super.onResume()
        currentState = WearStore.load(this)
        Wearable.getDataClient(this).addListener(this)
    }

    override fun onPause() {
        Wearable.getDataClient(this).removeListener(this)
        super.onPause()
    }

    override fun onDataChanged(events: DataEventBuffer) {
        events.filter { it.type == DataEvent.TYPE_CHANGED && it.dataItem.uri.path == "/cronos/state" }
            .forEach { event ->
                DataMapItem.fromDataItem(event.dataItem).dataMap.getString("json")?.let { json ->
                    WearStore.save(this, json)
                    currentState = WearStore.load(this)
                }
            }
    }

    @Composable
    private fun CronosWear() {
        val state = currentState
        val task = state.tasks.firstOrNull { it.running } ?: state.tasks.firstOrNull()
        var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
        LaunchedEffect(task?.running) {
            while (task?.running == true) {
                now = System.currentTimeMillis()
                delay(1000)
            }
        }
        MaterialTheme {
            Column(
                modifier = Modifier.fillMaxSize().padding(horizontal = 34.dp, vertical = 26.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(
                    "CRONOS",
                    color = Color(0xFF9BB7FF),
                    style = MaterialTheme.typography.titleMedium,
                )
                Spacer(Modifier.height(8.dp))
                Text(
                    task?.title ?: "Sin tareas cercanas",
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.titleSmall,
                )
                if (task?.running == true && task.startedAt != null) {
                    val seconds = ((now - task.startedAt) / 1000).coerceAtLeast(0)
                    Text(String.format("%02d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60))
                }
                if (task != null) {
                    Button(onClick = {
                        sendAction(if (task.running) "pause" else "start", task.id)
                        currentState = state.copy(tasks = state.tasks.map {
                            if (it.id == task.id) it.copy(running = !task.running) else it.copy(running = false)
                        })
                    }) { Text(if (task.running) "Pausar" else "Iniciar") }
                }
                if (state.updatedAt == 0L) {
                    Spacer(Modifier.height(8.dp))
                    Text(
                        "Abre Cronos en el teléfono para sincronizar",
                        textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.bodySmall,
                        color = Color(0xFFB8B8C0),
                    )
                }
            }
        }
    }

    private fun sendAction(type: String, taskId: String) {
        val payload = JSONObject(mapOf(
            "id" to "${System.currentTimeMillis()}-$taskId-$type",
            "type" to type,
            "taskId" to taskId,
            "createdAt" to System.currentTimeMillis(),
        )).toString().toByteArray()
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            nodes.forEach { Wearable.getMessageClient(this).sendMessage(it.id, "/cronos/action", payload) }
        }
    }
}
