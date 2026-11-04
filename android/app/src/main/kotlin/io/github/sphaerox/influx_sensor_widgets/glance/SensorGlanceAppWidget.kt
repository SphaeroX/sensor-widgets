package io.github.sphaerox.influx_sensor_widgets.glance

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.RowScope
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import io.github.sphaerox.influx_sensor_widgets.MainActivity
import io.github.sphaerox.influx_sensor_widgets.R
import io.github.sphaerox.influx_sensor_widgets.glance.chart.NativeChartBitmapRenderer
import io.github.sphaerox.influx_sensor_widgets.l10n.WidgetTexts
import io.github.sphaerox.influx_sensor_widgets.model.WidgetType
import io.github.sphaerox.influx_sensor_widgets.storage.WidgetStorageReader
import io.github.sphaerox.influx_sensor_widgets.worker.WidgetRefreshWorker

private val ColorError = ColorProvider(Color(0xFFF38BA8))

/** Glance color providers and scale of the current widget (see [AppearancePalette]). */
private class GlancePalette(
    val palette: AppearancePalette,
) {
    val text = ColorProvider(Color(palette.text))
    val muted = ColorProvider(Color(palette.muted))
    val accent = ColorProvider(Color(palette.accent))
    val background = ColorProvider(Color(palette.background))

    fun sp(size: Float) = (size * palette.fontScale).sp
}

private val LocalPalette = staticCompositionLocalOf { GlancePalette(AppearancePalette.resolve(null)) }

private val ColorTrack = ColorProvider(Color(0xFF313244))
private val ColorDotActive = ColorProvider(Color(0xFFA6E3A1))
private val ColorDotInactive = ColorProvider(Color(0xFF585B70))

class SensorGlanceAppWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(
        context: Context,
        id: GlanceId,
    ) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)

        provideContent {
            // Reading the version subscribes this session to refreshAll(): every stored refresh
            // reloads definition and cache instead of keeping the state of the first render.
            val refreshVersion = currentState(REFRESH_VERSION_KEY) ?: 0L
            val uiState = remember(refreshVersion) { loadUiState(context, appWidgetId) }
            WidgetRootContent(uiState)
        }
    }

    private fun loadUiState(
        context: Context,
        appWidgetId: Int,
    ): WidgetUiState {
        val storage = WidgetStorageReader(context)

        // Read bound widget ID from HomeWidgetPreferences or legacy prefs
        val boundKey = "app_widget_${appWidgetId}_bound_id"
        val homePrefs = context.getSharedPreferences(WidgetStorageReader.HOME_WIDGET_PREFS_NAME, Context.MODE_PRIVATE)
        val boundWidgetId =
            homePrefs.getString(boundKey, null)
                ?: context.getSharedPreferences(WidgetStorageReader.PREFS_NAME, Context.MODE_PRIVATE).getString(boundKey, null)

        val allWidgets = storage.getWidgetDefinitions()
        val widgetDef =
            if (boundWidgetId != null) {
                allWidgets.find { it.id == boundWidgetId }
            } else {
                allWidgets.firstOrNull()
            }

        // Trigger background refresh if cache is missing
        if (widgetDef != null && storage.getWidgetCache(widgetDef.id) == null) {
            WidgetRefreshWorker.enqueueOneTimeWork(context, widgetDef.id)
        }

        val cacheJson = if (widgetDef != null) storage.getWidgetCache(widgetDef.id) else null
        return WidgetUiStateMapper.mapToUiState(
            appWidgetId = appWidgetId,
            boundWidgetId = widgetDef?.id ?: boundWidgetId,
            widget = widgetDef,
            cacheJson = cacheJson,
            texts = WidgetTexts.of(context),
        )
    }

    @Composable
    private fun WidgetRootContent(state: WidgetUiState) {
        CompositionLocalProvider(LocalPalette provides GlancePalette(AppearancePalette.resolve(state.appearance))) {
            WidgetRootBox(state)
        }
    }

    @Composable
    private fun WidgetRootBox(state: WidgetUiState) {
        Box(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .background(LocalPalette.current.background)
                    .cornerRadius(LocalPalette.current.palette.cornerRadiusDp.dp)
                    .clickable(actionStartActivity<MainActivity>()),
        ) {
            Box(modifier = GlanceModifier.fillMaxSize().padding(12.dp)) {
                WidgetStateContent(state)
            }
            if (state.isConfigured && !state.isLoading && state.widgetId.isNotEmpty()) {
                RefreshTapTarget(state.widgetId)
            }
        }
    }

    /**
     * Drawn above the content so its larger tap area wins over the root "open app" click;
     * the glyph sits where the header keeps [WidgetSizing.REFRESH_GLYPH_SLOT_DP] free.
     */
    @Composable
    private fun RefreshTapTarget(widgetId: String) {
        Box(modifier = GlanceModifier.fillMaxSize(), contentAlignment = Alignment.TopEnd) {
            Box(
                modifier =
                    GlanceModifier
                        .size(WidgetSizing.REFRESH_TOUCH_TARGET_DP.dp)
                        .clickable(
                            actionRunCallback<RefreshActionCallback>(
                                actionParametersOf(ActionParameters.Key<String>("widget_id") to widgetId),
                            ),
                        ),
                contentAlignment = Alignment.TopEnd,
            ) {
                Text(
                    text = "↻",
                    style =
                        TextStyle(
                            color = LocalPalette.current.accent,
                            fontWeight = FontWeight.Bold,
                            fontSize = LocalPalette.current.sp(14f),
                        ),
                    modifier = GlanceModifier.padding(top = 12.dp, end = 12.dp),
                )
            }
        }
    }

    @Composable
    private fun WidgetStateContent(state: WidgetUiState) {
        if (!state.isConfigured) {
            UnconfiguredView()
        } else if (state.isLoading) {
            LoadingView(state.title)
        } else if (state.errorMessage != null) {
            ErrorView(state.title, state.errorMessage)
        } else {
            ConfiguredWidgetContent(state)
            if (state.warningMessage != null) {
                Column(
                    modifier = GlanceModifier.fillMaxSize(),
                    verticalAlignment = Alignment.Bottom,
                ) {
                    Text(
                        text = state.warningMessage,
                        style = TextStyle(color = ColorError, fontSize = LocalPalette.current.sp(10f)),
                        maxLines = 2,
                    )
                }
            }
        }
    }

    @Composable
    private fun UnconfiguredView() {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = LocalContext.current.getString(R.string.widget_setup_title),
                style = TextStyle(color = LocalPalette.current.text, fontWeight = FontWeight.Bold, fontSize = LocalPalette.current.sp(14f)),
            )
            Spacer(modifier = GlanceModifier.height(4.dp))
            Text(
                text = LocalContext.current.getString(R.string.widget_tap_to_open),
                style = TextStyle(color = LocalPalette.current.muted, fontSize = LocalPalette.current.sp(11f)),
            )
        }
    }

    @Composable
    private fun LoadingView(title: String) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            WidgetHeader(title = title, timestamp = "Lade...", showRefresh = false)
            Spacer(modifier = GlanceModifier.height(12.dp))
            Text(
                text = LocalContext.current.getString(R.string.widget_loading),
                style = TextStyle(color = LocalPalette.current.muted, fontSize = LocalPalette.current.sp(12f)),
            )
        }
    }

    @Composable
    private fun ErrorView(
        title: String,
        error: String,
    ) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            WidgetHeader(
                title = title,
                timestamp = LocalContext.current.getString(R.string.widget_error_header),
                showRefresh = true,
            )
            Spacer(modifier = GlanceModifier.height(8.dp))
            Text(
                text = error,
                style = TextStyle(color = ColorError, fontSize = LocalPalette.current.sp(11f)),
                maxLines = 2,
            )
        }
    }

    @Composable
    private fun ConfiguredWidgetContent(state: WidgetUiState) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            WidgetHeader(
                title = state.title,
                timestamp = state.timestampStr ?: "",
                showRefresh = true,
            )
            Spacer(modifier = GlanceModifier.height(6.dp))

            when (state.type) {
                WidgetType.SINGLE_VALUE -> SingleValueView(state)
                WidgetType.HISTORY_CHART -> HistoryChartView(state)
                WidgetType.INDICATOR_LAMP -> IndicatorLampView(state)
                WidgetType.GAUGE_BAR -> GaugeBarView(state)
                WidgetType.AGGREGATE -> AggregateView(state)
                WidgetType.MULTI_VALUE -> MultiValueView(state)
            }
        }
    }

    @Composable
    private fun WidgetHeader(
        title: String,
        timestamp: String,
        showRefresh: Boolean,
    ) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = title,
                style =
                    TextStyle(
                        color = LocalPalette.current.text,
                        fontWeight = FontWeight.Bold,
                        fontSize = LocalPalette.current.sp(13f),
                    ),
                maxLines = 1,
                modifier = GlanceModifier.defaultWeight(),
            )
            if (timestamp.isNotEmpty()) {
                Text(
                    text = timestamp,
                    style = TextStyle(color = LocalPalette.current.muted, fontSize = LocalPalette.current.sp(10f)),
                )
            }
            if (showRefresh) {
                // The ↻ glyph itself is drawn by RefreshTapTarget on top of this slot.
                Spacer(modifier = GlanceModifier.width(WidgetSizing.REFRESH_GLYPH_SLOT_DP.dp))
            }
        }
    }

    @Composable
    private fun SingleValueView(state: WidgetUiState) {
        val scale = WidgetSizing.primaryValueScale(LocalSize.current.height.value)
        Row(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = state.singleValue ?: "--",
                style =
                    TextStyle(
                        color = LocalPalette.current.accent,
                        fontWeight = FontWeight.Bold,
                        fontSize = LocalPalette.current.sp(28f * scale),
                    ),
            )
            if (!state.unit.isNullOrEmpty()) {
                Spacer(modifier = GlanceModifier.width(4.dp))
                Text(
                    text = state.unit,
                    style = TextStyle(color = LocalPalette.current.muted, fontSize = LocalPalette.current.sp(14f * scale)),
                )
            }
        }
    }

    @Composable
    private fun HistoryChartView(state: WidgetUiState) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "${state.singleValue ?: "--"} ${state.unit ?: ""}",
                    style =
                        TextStyle(
                            color = LocalPalette.current.text,
                            fontWeight = FontWeight.Bold,
                            fontSize = LocalPalette.current.sp(16f),
                        ),
                )
                Spacer(modifier = GlanceModifier.defaultWeight())
                Text(
                    text =
                        LocalContext.current.getString(
                            R.string.widget_min_max,
                            state.chartMinStr ?: "--",
                            state.chartMaxStr ?: "--",
                        ),
                    style = TextStyle(color = LocalPalette.current.muted, fontSize = LocalPalette.current.sp(10f)),
                )
            }
            Spacer(modifier = GlanceModifier.height(4.dp))
            val points = state.chartNormalizedPoints ?: emptyList()
            val style = state.chartStyle
            val values = state.chartValues
            val size = LocalSize.current
            val (chartWidthDp, chartHeightDp) =
                WidgetSizing.chartAreaDp(size.width.value, size.height.value, LocalPalette.current.palette.fontScale)
            val (bitmapWidth, bitmapHeight) =
                WidgetSizing.chartBitmapSize(chartWidthDp, chartHeightDp, LocalContext.current.resources.displayMetrics.density)
            val bitmap =
                (
                    if (style != null && values != null) {
                        NativeChartBitmapRenderer.renderChart(values, style, bitmapWidth, bitmapHeight)
                    } else {
                        null
                    }
                ) ?: NativeChartBitmapRenderer.renderSparkline(points, bitmapWidth, bitmapHeight)
            Image(
                provider = ImageProvider(bitmap),
                contentDescription = "Chart",
                contentScale = ContentScale.FillBounds,
                modifier = GlanceModifier.fillMaxWidth().defaultWeight(),
            )
        }
    }

    @Composable
    private fun IndicatorLampView(state: WidgetUiState) {
        val active = state.isIndicatorActive == true
        val dotColor = if (active) ColorDotActive else ColorDotInactive

        Row(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier =
                    GlanceModifier
                        .size(18.dp)
                        .background(dotColor)
                        .cornerRadius(9.dp),
            ) {}
            Spacer(modifier = GlanceModifier.width(10.dp))
            Column {
                Text(
                    text = "${state.singleValue ?: "--"} ${state.unit ?: ""}",
                    style =
                        TextStyle(
                            color = LocalPalette.current.text,
                            fontWeight = FontWeight.Bold,
                            fontSize = LocalPalette.current.sp(20f * WidgetSizing.primaryValueScale(LocalSize.current.height.value)),
                        ),
                )
                Text(
                    text =
                        LocalContext.current.getString(
                            if (active) R.string.widget_status_active else R.string.widget_status_inactive,
                        ),
                    style = TextStyle(color = LocalPalette.current.muted, fontSize = LocalPalette.current.sp(10f)),
                )
            }
        }
    }

    @Composable
    private fun GaugeBarView(state: WidgetUiState) {
        val progress = (state.gaugeProgress ?: 0.0f).coerceIn(0.0f, 1.0f)
        Column(modifier = GlanceModifier.fillMaxSize()) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "${state.singleValue ?: "--"} ${state.unit ?: ""}",
                    style =
                        TextStyle(
                            color = LocalPalette.current.accent,
                            fontWeight = FontWeight.Bold,
                            fontSize = LocalPalette.current.sp(18f),
                        ),
                )
            }
            Spacer(modifier = GlanceModifier.height(8.dp))
            // Progress Track
            Box(
                modifier =
                    GlanceModifier
                        .fillMaxWidth()
                        .height(8.dp)
                        .background(ColorTrack)
                        .cornerRadius(4.dp),
            ) {
                if (progress > 0.05f) {
                    Box(
                        modifier =
                            GlanceModifier
                                .fillMaxWidth()
                                .height(8.dp)
                                .background(LocalPalette.current.accent)
                                .cornerRadius(4.dp),
                    ) {}
                }
            }
            Spacer(modifier = GlanceModifier.height(4.dp))
            Row(modifier = GlanceModifier.fillMaxWidth()) {
                Text(
                    text = "${state.gaugeMinStr ?: "0"} ${state.unit ?: ""}",
                    style = TextStyle(color = LocalPalette.current.muted, fontSize = LocalPalette.current.sp(9f)),
                )
                Spacer(modifier = GlanceModifier.defaultWeight())
                Text(
                    text = "${state.gaugeMaxStr ?: "100"} ${state.unit ?: ""}",
                    style = TextStyle(color = LocalPalette.current.muted, fontSize = LocalPalette.current.sp(9f)),
                )
            }
        }
    }

    @Composable
    private fun AggregateView(state: WidgetUiState) {
        val aggs = state.aggregates ?: emptyMap()
        Row(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            AggBox("MIN", aggs["min"], state.unit)
            Spacer(modifier = GlanceModifier.width(8.dp))
            AggBox("MEAN", aggs["mean"], state.unit)
            Spacer(modifier = GlanceModifier.width(8.dp))
            AggBox("MAX", aggs["max"], state.unit)
        }
    }

    @Composable
    private fun RowScope.AggBox(
        label: String,
        value: String?,
        unit: String?,
    ) {
        Column(
            modifier =
                GlanceModifier
                    .defaultWeight()
                    .background(ColorTrack)
                    .cornerRadius(8.dp)
                    .padding(6.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = label,
                style = TextStyle(color = LocalPalette.current.muted, fontSize = LocalPalette.current.sp(9f)),
            )
            Spacer(modifier = GlanceModifier.height(2.dp))
            Text(
                text = value ?: "--",
                style = TextStyle(color = LocalPalette.current.text, fontWeight = FontWeight.Bold, fontSize = LocalPalette.current.sp(12f)),
            )
        }
    }

    @Composable
    private fun MultiValueView(state: WidgetUiState) {
        val vals = state.multiValues ?: emptyMap()
        val rowCount = WidgetSizing.multiValueRowCount(LocalSize.current.height.value, LocalPalette.current.palette.fontScale)
        Column(modifier = GlanceModifier.fillMaxSize()) {
            for ((key, value) in vals.entries.take(rowCount)) {
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = key,
                        style = TextStyle(color = LocalPalette.current.muted, fontSize = LocalPalette.current.sp(11f)),
                        modifier = GlanceModifier.defaultWeight(),
                    )
                    Text(
                        text = value,
                        style =
                            TextStyle(
                                color = LocalPalette.current.text,
                                fontWeight = FontWeight.Bold,
                                fontSize = LocalPalette.current.sp(12f),
                            ),
                    )
                }
                Spacer(modifier = GlanceModifier.height(2.dp))
            }
        }
    }

    companion object {
        val REFRESH_VERSION_KEY = longPreferencesKey("refresh_version")

        /** Re-renders every placed widget with the data currently stored (called after each refresh). */
        suspend fun refreshAll(context: Context) {
            val widget = SensorGlanceAppWidget()
            GlanceAppWidgetManager(context).getGlanceIds(SensorGlanceAppWidget::class.java).forEach { glanceId ->
                updateAppWidgetState(context, glanceId) { prefs -> prefs[REFRESH_VERSION_KEY] = System.currentTimeMillis() }
                widget.update(context, glanceId)
            }
        }
    }
}

class RefreshActionCallback : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val widgetId = parameters[ActionParameters.Key<String>("widget_id")]
        WidgetRefreshWorker.enqueueOneTimeWork(context, widgetId)
        SensorGlanceAppWidget().update(context, glanceId)
    }
}
