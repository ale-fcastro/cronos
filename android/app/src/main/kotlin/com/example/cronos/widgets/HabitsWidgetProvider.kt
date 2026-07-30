package com.example.cronos.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import com.example.cronos.R
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider as BaseHomeWidgetProvider

/// Widget "Hábitos": check diario + racha, hasta 5 (mismo tope que empuja
/// lib/core/services/home_widget_service.dart._pushHabits()). Tocar un
/// hábito alterna su check de hoy vía el callback de interactividad de
/// home_widget -- no tiene el problema de "finalizar tarea" de la sesión, así
/// que siempre se resuelve en background, sin abrir la app.
class HabitsWidgetProvider : BaseHomeWidgetProvider() {
    private val maxHabits = 5

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val count = widgetData.getInt("habits_count", 0)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_habits)
            views.setViewVisibility(
                R.id.widget_habits_empty,
                if (count == 0) View.VISIBLE else View.GONE,
            )

            for (i in 0 until maxHabits) {
                val rowId = rowIds[i]
                if (i >= count) {
                    views.setViewVisibility(rowId, View.GONE)
                    continue
                }
                views.setViewVisibility(rowId, View.VISIBLE)
                val id = widgetData.getString("habit_${i}_id", "") ?: ""
                val title = widgetData.getString("habit_${i}_title", "") ?: ""
                val done = widgetData.getBoolean("habit_${i}_done_today", false)
                val streak = widgetData.getInt("habit_${i}_streak", 0)

                views.setTextViewText(titleIds[i], title)
                views.setTextViewText(streakIds[i], if (streak > 0) "🔥 $streak" else "")
                views.setImageViewResource(
                    checkIds[i],
                    if (done) R.drawable.ic_habit_check_filled else R.drawable.ic_habit_check_outline,
                )
                if (id.isNotEmpty()) {
                    val uri = Uri.Builder()
                        .scheme("cronos")
                        .authority("habit-toggle")
                        .appendQueryParameter("habitId", id)
                        .build()
                    views.setOnClickPendingIntent(
                        rowId,
                        HomeWidgetBackgroundIntent.getBroadcast(context, uri),
                    )
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private val rowIds = intArrayOf(
        R.id.widget_habit_row_0, R.id.widget_habit_row_1, R.id.widget_habit_row_2,
        R.id.widget_habit_row_3, R.id.widget_habit_row_4,
    )
    private val titleIds = intArrayOf(
        R.id.widget_habit_title_0, R.id.widget_habit_title_1, R.id.widget_habit_title_2,
        R.id.widget_habit_title_3, R.id.widget_habit_title_4,
    )
    private val streakIds = intArrayOf(
        R.id.widget_habit_streak_0, R.id.widget_habit_streak_1, R.id.widget_habit_streak_2,
        R.id.widget_habit_streak_3, R.id.widget_habit_streak_4,
    )
    private val checkIds = intArrayOf(
        R.id.widget_habit_check_0, R.id.widget_habit_check_1, R.id.widget_habit_check_2,
        R.id.widget_habit_check_3, R.id.widget_habit_check_4,
    )
}
