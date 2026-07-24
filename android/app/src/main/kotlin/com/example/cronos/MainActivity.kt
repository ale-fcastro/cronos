package com.example.cronos

import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/// Expone datos de apps instaladas (nombre visible + icono real) que el
/// plugin de estadisticas de uso no resuelve de forma confiable para todos
/// los paquetes -- sin esto, apps sin resolver terminaban mostrando su
/// package name crudo ("com.instagram.android") en vez de "Instagram".
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "cronos/app_info"

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
                            result.success(getAppInfo(packageName))
                        }
                    }
                    "openUsageAccessSettings" -> {
                        openUsageAccessSettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getAppInfo(packageName: String): Map<String, Any?>? {
        return try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            val label = pm.getApplicationLabel(appInfo).toString()
            val icon = pm.getApplicationIcon(appInfo)
            mapOf(
                "appName" to label,
                "icon" to drawableToPngBytes(icon)
            )
        } catch (e: PackageManager.NameNotFoundException) {
            null
        } catch (e: Exception) {
            null
        }
    }

    private fun drawableToPngBytes(drawable: Drawable): ByteArray {
        val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            drawable.bitmap
        } else {
            val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 108
            val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 108
            val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bmp
        }
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
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
