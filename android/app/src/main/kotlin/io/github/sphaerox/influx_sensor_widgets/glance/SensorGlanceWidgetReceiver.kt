package io.github.sphaerox.influx_sensor_widgets.glance

import android.appwidget.AppWidgetManager
import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import io.github.sphaerox.influx_sensor_widgets.worker.WidgetRefreshWorker

class SensorGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = SensorGlanceAppWidget()

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetRefreshWorker.enqueuePeriodicWork(context)
    }

    /**
     * Called for the system update period, after the app saved definitions and when a widget
     * is placed. Fetches fresh data; the worker re-renders the widgets when it is done.
     * The periodic work is (re)scheduled here too, so widgets placed before it existed get it.
     */
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        WidgetRefreshWorker.enqueuePeriodicWork(context)
        WidgetRefreshWorker.enqueueOneTimeWork(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetRefreshWorker.cancelPeriodicWork(context)
    }
}
