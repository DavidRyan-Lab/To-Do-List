package com.example.todo_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class TodoWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.todo_widget)

            val prefs = HomeWidgetPlugin.getData(context)
            val todayTodos = prefs.getString("widget_todos", "할 일을 추가해 보세요!")
            views.setTextViewText(R.id.widget_todos, todayTodos)

            // 위젯 누르면 앱 실행
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_title, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_todos, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}