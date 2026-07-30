package com.example.cronos.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import com.example.cronos.MainActivity
import com.example.cronos.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider as BaseHomeWidgetProvider

/// Widget "Hoy": score, tiempo productivo/perdido y próxima tarea. Los
/// datos los empuja lib/core/services/home_widget_service.dart a
/// SharedPreferences cada vez que cambia algo relevante -- este provider
/// solo pinta lo último que se guardó, nunca calcula nada por su cuenta.
class HomeWidgetProvider : BaseHomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_home)

            views.setTextViewText(
                R.id.widget_home_score,
                widgetData.getInt("today_score", 0).toString(),
            )
            views.setTextViewText(
                R.id.widget_home_productive,
                widgetData.getString("today_productive_label", "--"),
            )
            views.setTextViewText(
                R.id.widget_home_lost,
                widgetData.getString("today_lost_label", "--"),
            )

            val nextTitle = widgetData.getString("today_next_task_title", "") ?: ""
            val nextTime = widgetData.getString("today_next_task_time", "") ?: ""
            views.setTextViewText(
                R.id.widget_home_next_task,
                if (nextTitle.isEmpty()) "Sin tareas planificadas" else "$nextTime · $nextTitle",
            )

            views.setOnClickPendingIntent(R.id.widget_home_register, quickRegisterIntent(context))

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /// Usa el mecanismo propio de home_widget (en vez de un Intent armado a
    /// mano) para que HomeWidget.initiallyLaunchedFromHomeWidget()/
    /// widgetClicked del lado Dart puedan distinguir este tap de un launch
    /// normal desde el launcher.
    private fun quickRegisterIntent(context: Context): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("cronos://quick-register"),
        )
}
