package com.example.cronos

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Expone datos de apps instaladas (nombre visible + icono real) que el
/// plugin de estadisticas de uso no resuelve de forma confiable para todos
/// los paquetes -- sin esto, apps sin resolver terminaban mostrando su
/// package name crudo ("com.instagram.android") en vez de "Instagram".
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "cronos/app_info"
    private val sessionServiceChannelName = "cronos/session_service"
    private val appTrackingServiceChannelName = "cronos/app_tracking_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppInfo" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName == null) {
                            result.success(null)
                        } else {
                            result.success(AppInfoResolver.getAppInfo(this, packageName))
                        }
                    }
                    "openUsageAccessSettings" -> {
                        openUsageAccessSettings()
                        result.success(null)
                    }
                    "getInstalledApps" -> {
                        result.success(getInstalledApps())
                    }
                    else -> result.notImplemented()
                }
            }

        // Arranca/detiene SessionForegroundService: lib/core/services/
        // session_notification_service.dart lo llama en cada evento de
        // TimerService (ver TimerService.events).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, sessionServiceChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startForegroundSession" -> {
                        val intent = Intent(this, SessionForegroundService::class.java).apply {
                            action = SessionForegroundService.ACTION_START
                            putExtra(
                                SessionForegroundService.EXTRA_NOTIFICATION_ID,
                                (call.argument<Int>("notificationId")) ?: -1,
                            )
                            putExtra(SessionForegroundService.EXTRA_KIND, call.argument<String>("kind"))
                            putExtra(SessionForegroundService.EXTRA_TASK_ID, call.argument<String>("taskId"))
                        }
                        ContextCompat.startForegroundService(this, intent)
                        result.success(null)
                    }
                    "stopForegroundSession" -> {
                        try {
                            startService(
                                Intent(this, SessionForegroundService::class.java).apply {
                                    action = SessionForegroundService.ACTION_STOP
                                },
                            )
                        } catch (e: IllegalStateException) {
                            // App en background sin excepción de servicio en primer
                            // plano: no hay nada corriendo para detener igual.
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Arranca/detiene AppTrackingService: lib/core/services/
        // app_tracking_service.dart lo llama al prender/apagar el toggle en
        // Configuración > App Tracking.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appTrackingServiceChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        ContextCompat.startForegroundService(
                            this,
                            Intent(this, AppTrackingService::class.java),
                        )
                        result.success(null)
                    }
                    "stop" -> {
                        stopService(Intent(this, AppTrackingService::class.java))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// Todas las apps con ícono en el launcher (excluye Cronos misma y
    /// componentes sin actividad de lanzamiento). A diferencia de
    /// `AppUsageService.queryUsage`, que solo ve apps con uso reciente, esto
    /// alimenta el selector de "apps vinculadas" de un ActivityType (App
    /// Tracking), donde hace falta poder elegir una app que todavía no se
    /// usó en la ventana consultada.
    private fun getInstalledApps(): List<Map<String, Any?>> {
        val intent = Intent(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_LAUNCHER) }
        val resolved = packageManager.queryIntentActivities(intent, 0)
        val seen = HashSet<String>()
        val result = mutableListOf<Map<String, Any?>>()
        for (info in resolved) {
            val pkg = info.activityInfo.packageName
            if (pkg == packageName || !seen.add(pkg)) continue
            try {
                val appInfo = packageManager.getApplicationInfo(pkg, 0)
                val label = packageManager.getApplicationLabel(appInfo).toString()
                val icon = packageManager.getApplicationIcon(appInfo)
                result.add(
                    mapOf(
                        "packageName" to pkg,
                        "appName" to label,
                        "icon" to AppInfoResolver.drawableToPngBytes(icon),
                    ),
                )
            } catch (e: PackageManager.NameNotFoundException) {
                // App desinstalada entre la resolución del intent y acá: se salta.
            }
        }
        return result.sortedBy { (it["appName"] as String).lowercase() }
    }

    /// Abre la pantalla de "Acceso al uso" del sistema. Desde Android 12
    /// (API 31) intenta llevar al usuario directo a la fila de Cronos con
    /// EXTRA_APP_PACKAGE; si el fabricante no lo soporta, cae a la lista
    /// general (sigue siendo mejor que quedarse sin poder conceder el permiso).
    private fun openUsageAccessSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val direct = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                direct.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                if (direct.resolveActivity(packageManager) != null) {
                    startActivity(direct)
                    return
                }
            }
            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
        } catch (e: Exception) {
            try {
                val fallback = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                fallback.data = Uri.parse("package:$packageName")
                startActivity(fallback)
            } catch (e2: Exception) {
                // Sin pantalla de sistema disponible: no hay accion posible.
            }
        }
    }
}
