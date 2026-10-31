package io.github.mgasc.influx_sensor_widgets.glance

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.TextView
import androidx.glance.appwidget.GlanceAppWidgetManager
import io.github.mgasc.influx_sensor_widgets.model.WidgetDefinition
import io.github.mgasc.influx_sensor_widgets.storage.WidgetStorageReader
import io.github.mgasc.influx_sensor_widgets.worker.WidgetRefreshWorker
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch

class SensorWidgetConfigActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private val scope = MainScope()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val storage = WidgetStorageReader(this)
        val widgets = storage.getWidgetDefinitions()

        if (widgets.isEmpty()) {
            val emptyView =
                TextView(this).apply {
                    text = "Noch keine Widgets in der App konfiguriert.\nBitte erstelle zuerst ein Widget in der Sensor Widgets App."
                    setPadding(48, 48, 48, 48)
                    textSize = 16f
                }
            setContentView(emptyView)
            return
        }

        val listView = ListView(this)
        val titles = widgets.map { "${it.title} (${it.type.wireName})" }
        listView.adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, titles)

        listView.setOnItemClickListener { _, _, position, _ ->
            val selectedWidget = widgets[position]
            bindAndFinish(selectedWidget)
        }

        setContentView(listView)
    }

    private fun bindAndFinish(widget: WidgetDefinition) {
        val prefs = getSharedPreferences(WidgetStorageReader.PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString("app_widget_${appWidgetId}_bound_id", widget.id).apply()

        WidgetRefreshWorker.enqueueOneTimeWork(this, widget.id)

        scope.launch {
            try {
                val glanceManager = GlanceAppWidgetManager(this@SensorWidgetConfigActivity)
                val glanceId = glanceManager.getGlanceIdBy(appWidgetId)
                SensorGlanceAppWidget().update(this@SensorWidgetConfigActivity, glanceId)
            } catch (_: Exception) {
            }

            val resultValue =
                Intent().apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
            setResult(RESULT_OK, resultValue)
            finish()
        }
    }
}
