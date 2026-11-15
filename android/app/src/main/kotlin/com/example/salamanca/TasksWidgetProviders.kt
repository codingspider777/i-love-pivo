package com.example.salamanca

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Базовый провайдер: Flutter рендерит виджет в PNG (HomeWidget.renderFlutterWidget)
 * и кладёт путь в SharedPreferences под ключом [prefKey]. Здесь мы лишь показываем
 * картинку и открываем приложение по тапу.
 */
abstract class BaseTasksWidgetProvider : HomeWidgetProvider() {
    abstract val prefKey: String

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.tasks_widget).apply {
                val path = widgetData.getString(prefKey, null)
                val bitmap = path?.let { BitmapFactory.decodeFile(it) }
                if (bitmap != null) {
                    setImageViewBitmap(R.id.widget_image, bitmap)
                    setViewVisibility(R.id.widget_placeholder, View.GONE)
                } else {
                    setViewVisibility(R.id.widget_placeholder, View.VISIBLE)
                }
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

class TasksWidgetSmall : BaseTasksWidgetProvider() {
    override val prefKey = "widget_small"
}

class TasksWidgetMedium : BaseTasksWidgetProvider() {
    override val prefKey = "widget_medium"
}

class TasksWidgetLarge : BaseTasksWidgetProvider() {
    override val prefKey = "widget_large"
}
