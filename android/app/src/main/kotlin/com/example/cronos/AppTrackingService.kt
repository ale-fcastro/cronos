package com.example.cronos

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/// Sondea qué app está en primer plano cada [POLL_INTERVAL_MS] mientras el
/// usuario tenga la detección automática de contexto activada (Configuración
/// → App Tracking), para que abrir una app vinculada a una tarea o a un
/// "contexto" (ActivityType) arranque su cronómetro solo, sin abrir Cronos.
///
/// A diferencia de [SessionForegroundService] (que arranca/para con el
/// cronómetro), este corre mientras el usuario lo tenga prendido en
/// Configuración -- por eso Android exige su propia notificación fija
/// mientras esté activo.
///
/// Sondear cada pocos segundos con un FlutterEngine nuevo por tick (el
/// patrón de HomeWidgetBackgroundIntent/nudgeCallbackDispatcher, pensado
/// para eventos esporádicos) sería demasiado lento y gastaría más batería
/// que el problema que resuelve. En cambio, este servicio crea un
/// FlutterEngine de fondo UNA sola vez y lo mantiene vivo mientras corre,
/// con un MethodChannel abierto todo el tiempo -- mismo patrón que usa
/// internamente `ActionBroadcastReceiver` de flutter_local_notifications
/// (`FlutterEngine` estático, reusado entre invocaciones).
class AppTrackingService : Service() {
    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private val handler = Handler(Looper.getMainLooper())
    private var lastForegroundPackage: String? = null
    private var lastQueryEndMs: Long = 0L
    private var running = false

    private val pollTick = object : Runnable {
        override fun run() {
            pollForegroundApp()
            if (running) handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!running) {
            running = true
            startForeground(NOTIFICATION_ID, buildNotification())
            ensureEngine()
            lastQueryEndMs = System.currentTimeMillis()
            handler.post(pollTick)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        running = false
        handler.removeCallbacks(pollTick)
        super.onDestroy()
    }

    private fun ensureEngine() {
        if (engine != null) return
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)
        val newEngine = FlutterEngine(applicationContext)
        newEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), ENTRYPOINT_NAME),
        )
        channel = MethodChannel(newEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        engine = newEngine
    }

    private fun pollForegroundApp() {
        val manager =
            getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return
        val now = System.currentTimeMillis()
        if (lastQueryEndMs >= now) return
        val events = manager.queryEvents(lastQueryEndMs, now)
        lastQueryEndMs = now

        var latestForeground: String? = null
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                latestForeground = event.packageName
            }
        }
        if (latestForeground != null &&
            latestForeground != lastForegroundPackage &&
            latestForeground != packageName
        ) {
            lastForegroundPackage = latestForeground
            channel?.invokeMethod("foregroundAppChanged", latestForeground)
        }
    }

    private fun buildNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            if (manager?.getNotificationChannel(CHANNEL_ID) == null) {
                manager?.createNotificationChannel(
                    NotificationChannel(
                        CHANNEL_ID,
                        "Detección de app activa",
                        NotificationManager.IMPORTANCE_MIN,
                    ),
                )
            }
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Croni está mirando qué app usás")
            .setContentText("Para arrancar el cronómetro solo, sin que lo toques.")
            .setSmallIcon(R.drawable.ic_stat_croni)
            .setColor(ACCENT_COLOR)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .build()
    }

    companion object {
        const val CHANNEL_NAME = "cronos/app_tracking"
        const val ENTRYPOINT_NAME = "appTrackingEntrypoint"
        private const val CHANNEL_ID = "app_tracking"
        private const val NOTIFICATION_ID = 7002
        private const val POLL_INTERVAL_MS = 4000L
        private const val ACCENT_COLOR = 0xFF9DB1F5.toInt()
    }
}
