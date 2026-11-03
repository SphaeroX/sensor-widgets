package io.github.mgasc.influx_sensor_widgets.glance

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.widget.BaseAdapter
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import androidx.glance.appwidget.GlanceAppWidgetManager
import io.github.mgasc.influx_sensor_widgets.MainActivity
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

        val rootLayout =
            LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setBackgroundColor(Color.parseColor("#1E1E2E"))
                val pad = (16 * resources.displayMetrics.density).toInt()
                setPadding(pad, pad, pad, pad)
                setOnApplyWindowInsetsListener { view, insets ->
                    val p = systemBarPadding(pad, insets)
                    view.setPadding(p[0], p[1], p[2], p[3])
                    insets
                }
            }
        drawEdgeToEdge()

        val titleView =
            TextView(this).apply {
                text = "Sensor Widgets"
                setTextColor(Color.WHITE)
                textSize = 20f
                typeface = Typeface.DEFAULT_BOLD
                setPadding(0, 0, 0, (8 * resources.displayMetrics.density).toInt())
            }
        rootLayout.addView(titleView)

        if (widgets.isEmpty()) {
            val emptyMsg =
                TextView(this).apply {
                    text =
                        "Noch keine Widgets konfiguriert.\n\nBitte erstelle zuerst in der App ein Widget und platziere es anschließend auf dem Homescreen."
                    setTextColor(Color.parseColor("#A6ADC8"))
                    textSize = 15f
                    setPadding(0, (16 * resources.displayMetrics.density).toInt(), 0, (24 * resources.displayMetrics.density).toInt())
                }
            rootLayout.addView(emptyMsg)

            val openAppBtn =
                Button(this).apply {
                    text = "Sensor Widgets App öffnen"
                    setBackgroundColor(Color.parseColor("#89B4FA"))
                    setTextColor(Color.parseColor("#11111B"))
                    setOnClickListener {
                        startActivity(Intent(this@SensorWidgetConfigActivity, MainActivity::class.java))
                        finish()
                    }
                }
            rootLayout.addView(openAppBtn)
            setContentView(rootLayout)
            return
        }

        val subtitleView =
            TextView(this).apply {
                text = "Wähle das Widget für diesen Homescreen-Platzhalter:"
                setTextColor(Color.parseColor("#A6ADC8"))
                textSize = 14f
                setPadding(0, 0, 0, (12 * resources.displayMetrics.density).toInt())
            }
        rootLayout.addView(subtitleView)

        val listView =
            ListView(this).apply {
                divider = null
                dividerHeight = 0
            }

        listView.adapter =
            object : BaseAdapter() {
                override fun getCount(): Int = widgets.size

                override fun getItem(position: Int): Any = widgets[position]

                override fun getItemId(position: Int): Long = position.toLong()

                override fun getView(
                    position: Int,
                    convertView: View?,
                    parent: ViewGroup?,
                ): View {
                    val item = widgets[position]
                    val itemLayout =
                        (convertView as? LinearLayout) ?: LinearLayout(this@SensorWidgetConfigActivity).apply {
                            orientation = LinearLayout.VERTICAL
                            val p = (12 * resources.displayMetrics.density).toInt()
                            setPadding(p, p, p, p)
                            setBackgroundColor(Color.parseColor("#313244"))
                            val params =
                                LinearLayout
                                    .LayoutParams(
                                        LinearLayout.LayoutParams.MATCH_PARENT,
                                        LinearLayout.LayoutParams.WRAP_CONTENT,
                                    ).apply {
                                        bottomMargin = (8 * resources.displayMetrics.density).toInt()
                                    }
                            layoutParams = params
                        }

                    itemLayout.removeAllViews()

                    val itemTitle =
                        TextView(this@SensorWidgetConfigActivity).apply {
                            text = item.title
                            setTextColor(Color.WHITE)
                            textSize = 16f
                            typeface = Typeface.DEFAULT_BOLD
                        }
                    itemLayout.addView(itemTitle)

                    val detailsText = "${item.type.wireName.uppercase()} • ${item.measurement} [${item.field ?: "Multi"}]"
                    val itemDetails =
                        TextView(this@SensorWidgetConfigActivity).apply {
                            text = detailsText
                            setTextColor(Color.parseColor("#89B4FA"))
                            textSize = 12f
                            setPadding(0, (4 * resources.displayMetrics.density).toInt(), 0, 0)
                        }
                    itemLayout.addView(itemDetails)

                    return itemLayout
                }
            }

        listView.setOnItemClickListener { _, _, position, _ ->
            val selectedWidget = widgets[position]
            bindAndFinish(selectedWidget)
        }

        rootLayout.addView(
            listView,
            LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT),
        )
        setContentView(rootLayout)
    }

    /**
     * Android 15 enforces edge-to-edge, so the picker would be drawn below the status bar.
     * Opting in on every version keeps one code path: the root pads itself by the insets.
     */
    @Suppress("DEPRECATION")
    private fun drawEdgeToEdge() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        } else {
            window.decorView.systemUiVisibility =
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        }
    }

    @Suppress("DEPRECATION")
    private fun systemBarPadding(
        basePx: Int,
        insets: WindowInsets,
    ): IntArray =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val bars = insets.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
            ConfigScreenInsets.padding(basePx, bars.left, bars.top, bars.right, bars.bottom)
        } else {
            ConfigScreenInsets.padding(
                basePx,
                insets.systemWindowInsetLeft,
                insets.systemWindowInsetTop,
                insets.systemWindowInsetRight,
                insets.systemWindowInsetBottom,
            )
        }

    private fun bindAndFinish(widget: WidgetDefinition) {
        val boundKey = "app_widget_${appWidgetId}_bound_id"
        getSharedPreferences(WidgetStorageReader.HOME_WIDGET_PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(boundKey, widget.id)
            .apply()
        getSharedPreferences(WidgetStorageReader.PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(boundKey, widget.id)
            .apply()

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
