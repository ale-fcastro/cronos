package com.example.cronos

import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import java.io.ByteArrayOutputStream

/// Resuelve nombre visible + icono real de una app instalada contra
/// PackageManager. Usado tanto por MainActivity (canal `cronos/app_info`
/// del engine principal) como por AppTrackingService (su propio engine de
/// fondo, sin Activity) -- PackageManager solo necesita un Context, no una
/// Activity, así que ambos pueden compartir esta misma implementación en
/// vez de mantener dos copias que puedan divergir.
object AppInfoResolver {
    fun getAppInfo(context: Context, packageName: String): Map<String, Any?>? {
        return try {
            val pm = context.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            val label = pm.getApplicationLabel(appInfo).toString()
            val icon = pm.getApplicationIcon(appInfo)
            mapOf(
                "appName" to label,
                "icon" to drawableToPngBytes(icon),
            )
        } catch (e: PackageManager.NameNotFoundException) {
            null
        } catch (e: Exception) {
            null
        }
    }

    fun drawableToPngBytes(drawable: Drawable): ByteArray {
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
}
