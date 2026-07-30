package com.example.cronos.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import com.example.cronos.MainActivity
import com.example.cronos.R
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider as BaseHomeWidgetProvider

/// Widget "Sesión activa": tarea/actividad con el cronómetro corriendo,
/// con botones Pausar/Finalizar. Mismos datos y misma restricción que la
/// notificación persistente (ver SessionForegroundService.kt): finalizar una
/// TAREA nunca se resuelve en background, siempre abre el diálogo de
/// confirmación de la app.
class SessionWidgetProvider : BaseHomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val active = widgetData.getBoolean("session_active", false)
        val title = widgetData.getString("session_title", "") ?: ""
        val subtitle = widgetData.getString("session_subtitle", "") ?: ""
        val startedAt = widgetData.getLong("session_started_at_epoch_ms", 0L)
        val kind = widgetData.getString("session_kind", "task") ?: "task"
        val taskId = widgetData.getString("session_task_id", "") ?: ""

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_session)

            if (!active) {
                views.setTextViewText(R.id.widget_session_title, "Sin sesión activa")
                views.setTextViewText(R.id.widget_session_subtitle, "")
                views.setChronometer(R.id.widget_session_chronometer, 0L, "--:--:--", false)
                views.setViewVisibility(R.id.widget_session_actions, View.GONE)
                appWidgetManager.updateAppWidget(widgetId, views)
                continue
            }

            views.setTextViewText(R.id.widget_session_title, title)
            views.setTextViewText(R.id.widget_session_subtitle, subtitle)

            val base = SystemClock.elapsedRealtime() + (startedAt - System.currentTimeMillis())
            views.setChronometer(R.id.widget_session_chronometer, base, null, true)

            views.setViewVisibility(R.id.widget_session_actions, View.VISIBLE)
            val isTask = kind == "task"
            views.setViewVisibility(
                R.id.widget_session_pause,
                if (isTask) View.VISIBLE else View.GONE,
            )
            if (isTask && taskId.isNotEmpty()) {
                views.setOnClickPendingIntent(
                    R.id.widget_session_pause,
                    backgroundActionIntent(context, "pause", "task", taskId),
                )
                views.setOnClickPendingIntent(
                    R.id.widget_session_finish,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("cronos://task-detail?taskId=$taskId"),
                    ),
                )
            } else {
                views.setOnClickPendingIntent(
                    R.id.widget_session_finish,
                    backgroundActionIntent(context, "finish", "activity", null),
                )
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun backgroundActionIntent(
        context: Context,
        type: String,
        kind: String,
        taskId: String?,
    ): PendingIntent {
        val uriBuilder = Uri.Builder()
            .scheme("cronos")
            .authority("session-action")
            .appendQueryParameter("type", type)
            .appendQueryParameter("kind", kind)
        if (taskId != null) uriBuilder.appendQueryParameter("taskId", taskId)
        return HomeWidgetBackgroundIntent.getBroadcast(context, uriBuilder.build())
    }
}
