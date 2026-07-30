package com.example.cronos.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.widget.RemoteViews
import com.example.cronos.R
import es.antonborri.home_widget.HomeWidgetProvider as BaseHomeWidgetProvider

/// Widget "Semanal": una barra por día (L-D) con el score de
/// lib/core/services/home_widget_service.dart._pushWeekly(), mismo cálculo
/// que ya usa el dashboard (StatsEngine) -- este provider solo dibuja.
///
/// RemoteViews no permite alturas dinámicas por peso ni drawables
/// vectoriales parametrizados en tiempo de ejecución, así que cada barra se
/// dibuja como un bitmap chico (más portable entre versiones de Android que
/// las APIs de RemoteViews.setViewLayoutHeight, agregadas recién en API 31).
class WeeklyWidgetProvider : BaseHomeWidgetProvider() {
    private val barIds = intArrayOf(
        R.id.weekly_bar_0, R.id.weekly_bar_1, R.id.weekly_bar_2, R.id.weekly_bar_3,
        R.id.weekly_bar_4, R.id.weekly_bar_5, R.id.weekly_bar_6,
    )
    private val labelIds = intArrayOf(
        R.id.weekly_label_0, R.id.weekly_label_1, R.id.weekly_label_2, R.id.weekly_label_3,
        R.id.weekly_label_4, R.id.weekly_label_5, R.id.weekly_label_6,
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val scores = (widgetData.getString("weekly_scores", "") ?: "")
            .split(",").mapNotNull { it.toDoubleOrNull() }
        val labels = (widgetData.getString("weekly_labels", "") ?: "").split(",")

        val density = context.resources.displayMetrics.density
        val barWidthPx = (18 * density).toInt()
        val barHeightPx = (64 * density).toInt()

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_weekly)
            for (i in 0 until 7) {
                val value = scores.getOrElse(i) { 0.0 }.coerceIn(0.0, 1.0)
                // El datasource siempre arma la lista con hoy como último punto.
                val isToday = i == 6
                views.setImageViewBitmap(
                    barIds[i],
                    buildBarBitmap(barWidthPx, barHeightPx, value, isToday),
                )
                views.setTextViewText(labelIds[i], labels.getOrElse(i) { "" })
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun buildBarBitmap(width: Int, height: Int, value: Double, isToday: Boolean): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val radius = width / 2f

        paint.color = 0xFF3A3D45.toInt() // widget_neutral_bar: track de fondo
        canvas.drawRoundRect(RectF(0f, 0f, width.toFloat(), height.toFloat()), radius, radius, paint)

        val barHeight = (height * value).toFloat().coerceAtLeast(radius * 2)
        paint.color = if (isToday) 0xFF9DB1F5.toInt() else 0xFF6A6F79.toInt()
        canvas.drawRoundRect(
            RectF(0f, height - barHeight, width.toFloat(), height.toFloat()),
            radius,
            radius,
            paint,
        )
        return bitmap
    }
}
