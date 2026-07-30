package com.example.cronos

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

/// Mantiene el proceso en foreground mientras corre un cronómetro de sesión
/// (elegido explícitamente por sobre solo una notificación "ongoing"), para
/// que el sistema no trate a Cronos como "en background" en gestores de
/// batería agresivos.
///
/// El texto/chronometer de la notificación los arma
/// lib/core/services/session_notification_service.dart vía
/// flutter_local_notifications -- este servicio solo la "adopta" (la busca
/// por id ya publicada) para startForeground() y le agrega los botones
/// nativos Pausar/Finalizar, sin duplicar esa lógica acá.
///
/// "Finalizar" de una TAREA nunca se resuelve acá: finalizar una tarea pasa
/// siempre por el diálogo de confirmación de la app (ver
/// showCompleteTaskDialog), así que ese botón abre la app en cambio
/// (ver MainActivity/main.dart, host "task-detail"). Pausar una tarea y
/// finalizar una actividad no tienen esa restricción, así que se resuelven
/// en background vía el callback de interactividad de home_widget, ya
/// registrado en Dart al arrancar la app (ver sessionActionCallback en
/// main.dart).
class SessionForegroundService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> handleStart(intent)
            ACTION_PAUSE -> handleBackgroundActionAndStop(intent, "pause")
            ACTION_FINISH_ACTIVITY -> handleBackgroundActionAndStop(intent, "finish")
            ACTION_STOP -> stopSelfCleanly()
        }
        return START_NOT_STICKY
    }

    private fun handleStart(intent: Intent) {
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1)
        val kind = intent.getStringExtra(EXTRA_KIND) ?: "task"
        val taskId = intent.getStringExtra(EXTRA_TASK_ID)
        val original = findActiveNotification(notificationId)
        if (original == null) {
            stopSelfCleanly()
            return
        }
        val builder = NotificationCompat.Builder(applicationContext, original)
        if (kind == "task") {
            builder.addAction(
                0,
                "Pausar",
                servicePendingIntent(ACTION_PAUSE, notificationId, kind, taskId, requestCodeOffset = 1),
            )
            if (taskId != null) {
                builder.addAction(0, "Finalizar", openTaskDetailPendingIntent(taskId))
            }
        } else {
            builder.addAction(
                0,
                "Finalizar",
                servicePendingIntent(ACTION_FINISH_ACTIVITY, notificationId, kind, null, requestCodeOffset = 2),
            )
        }
        startForeground(notificationId, builder.build())
    }

    /// Dispara la mutación real vía el callback de interactividad de
    /// home_widget (ya registrado en Dart) y no espera su resultado: dejar
    /// de ser foreground es instantáneo y no depende de que esa mutación en
    /// background termine -- si el proceso muriera un instante después, el
    /// broadcast ya encoló su propio trabajo durable.
    private fun handleBackgroundActionAndStop(intent: Intent, type: String) {
        val kind = intent.getStringExtra(EXTRA_KIND) ?: "task"
        val taskId = intent.getStringExtra(EXTRA_TASK_ID)
        val uriBuilder = Uri.Builder()
            .scheme("cronos")
            .authority("session-action")
            .appendQueryParameter("type", type)
            .appendQueryParameter("kind", kind)
        if (taskId != null) uriBuilder.appendQueryParameter("taskId", taskId)
        try {
            HomeWidgetBackgroundIntent.getBroadcast(applicationContext, uriBuilder.build()).send()
        } catch (e: PendingIntent.CanceledException) {
            // Sin nada que hacer si el broadcast ya no es válido.
        }
        stopSelfCleanly()
    }

    private fun stopSelfCleanly() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun findActiveNotification(id: Int): Notification? {
        if (id == -1) return null
        val manager = getSystemService(NotificationManager::class.java)
        return manager?.activeNotifications?.firstOrNull { it.id == id }?.notification
    }

    private fun servicePendingIntent(
        action: String,
        notificationId: Int,
        kind: String,
        taskId: String?,
        requestCodeOffset: Int,
    ): PendingIntent {
        val intent = Intent(this, SessionForegroundService::class.java).apply {
            this.action = action
            putExtra(EXTRA_NOTIFICATION_ID, notificationId)
            putExtra(EXTRA_KIND, kind)
            putExtra(EXTRA_TASK_ID, taskId)
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        // requestCode único por acción para que Pausar y Finalizar no se
        // pisen el PendingIntent entre sí.
        return PendingIntent.getService(
            this,
            notificationId * 10 + requestCodeOffset,
            intent,
            flags,
        )
    }

    /// "Finalizar" de una tarea abre la app en el detalle con el diálogo de
    /// completar -- mismo mecanismo que ya usa el widget "Hoy" > "+ Registrar"
    /// (ver HomeWidgetProvider.kt), reusado acá solo como transporte de Uri.
    private fun openTaskDetailPendingIntent(taskId: String): PendingIntent =
        es.antonborri.home_widget.HomeWidgetLaunchIntent.getActivity(
            applicationContext,
            MainActivity::class.java,
            Uri.parse("cronos://task-detail?taskId=$taskId"),
        )

    companion object {
        const val ACTION_START = "com.example.cronos.action.START_SESSION"
        const val ACTION_STOP = "com.example.cronos.action.STOP_SESSION"
        const val ACTION_PAUSE = "com.example.cronos.action.PAUSE_SESSION"
        const val ACTION_FINISH_ACTIVITY = "com.example.cronos.action.FINISH_ACTIVITY_SESSION"
        const val EXTRA_NOTIFICATION_ID = "notificationId"
        const val EXTRA_KIND = "kind"
        const val EXTRA_TASK_ID = "taskId"
    }
}
