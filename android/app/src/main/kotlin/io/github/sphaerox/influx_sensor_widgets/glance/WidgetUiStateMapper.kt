package io.github.sphaerox.influx_sensor_widgets.glance

import io.github.sphaerox.influx_sensor_widgets.glance.chart.ChartMathAndFormatter
import io.github.sphaerox.influx_sensor_widgets.model.WidgetDefinition
import io.github.sphaerox.influx_sensor_widgets.model.WidgetType
import org.json.JSONObject

object WidgetUiStateMapper {
    fun mapToUiState(
        appWidgetId: Int,
        boundWidgetId: String?,
        widget: WidgetDefinition?,
        cacheJson: String?,
    ): WidgetUiState {
        if (boundWidgetId == null || widget == null) {
            return WidgetUiState(
                widgetId = boundWidgetId ?: "",
                title = "Widget konfigurieren",
                type = WidgetType.SINGLE_VALUE,
                isConfigured = false,
            )
        }

        if (cacheJson == null) {
            return WidgetUiState(
                widgetId = widget.id,
                title = widget.title,
                type = widget.type,
                unit = widget.unit,
                isConfigured = true,
                isLoading = true,
            )
        }

        val cacheObj =
            try {
                JSONObject(cacheJson)
            } catch (e: Exception) {
                return WidgetUiState(
                    widgetId = widget.id,
                    title = widget.title,
                    type = widget.type,
                    unit = widget.unit,
                    isConfigured = true,
                    errorMessage = "Fehler beim Lesen der Cache-Daten",
                )
            }

        if (cacheObj.has("error")) {
            return WidgetUiState(
                widgetId = widget.id,
                title = widget.title,
                type = widget.type,
                unit = widget.unit,
                isConfigured = true,
                errorMessage = cacheObj.getString("error"),
            )
        }

        val timestamp = cacheObj.optLong("timestamp", 0L)
        val timestampStr = if (timestamp > 0L) ChartMathAndFormatter.formatTimestamp(timestamp) else null

        val state =
            mapTypeState(widget, cacheObj, timestampStr)
        val warning = cacheObj.optString("warning").takeIf { it.isNotEmpty() }
        return state.copy(warningMessage = warning, appearance = widget.appearance)
    }

    private fun mapTypeState(
        widget: WidgetDefinition,
        cacheObj: JSONObject,
        timestampStr: String?,
    ): WidgetUiState =
        when (widget.type) {
            WidgetType.SINGLE_VALUE -> {
                val value =
                    if (cacheObj.has("value") && !cacheObj.isNull("value")) {
                        cacheObj.getDouble("value")
                    } else {
                        null
                    }
                WidgetUiState(
                    widgetId = widget.id,
                    title = widget.title,
                    type = widget.type,
                    unit = widget.unit,
                    isConfigured = true,
                    singleValue = ChartMathAndFormatter.formatValue(value, widget.decimalPlaces),
                    timestampStr = timestampStr,
                )
            }

            WidgetType.INDICATOR_LAMP -> {
                val value =
                    if (cacheObj.has("value") && !cacheObj.isNull("value")) {
                        cacheObj.getDouble("value")
                    } else {
                        null
                    }
                val isActive = cacheObj.optBoolean("isActive", false)
                WidgetUiState(
                    widgetId = widget.id,
                    title = widget.title,
                    type = widget.type,
                    unit = widget.unit,
                    isConfigured = true,
                    singleValue = ChartMathAndFormatter.formatValue(value, widget.decimalPlaces),
                    isIndicatorActive = isActive,
                    timestampStr = timestampStr,
                )
            }

            WidgetType.GAUGE_BAR -> {
                val value =
                    if (cacheObj.has("value") && !cacheObj.isNull("value")) {
                        cacheObj.getDouble("value")
                    } else {
                        0.0
                    }
                val minVal = widget.min ?: 0.0
                val maxVal = widget.max ?: 100.0
                val progress = ChartMathAndFormatter.calculateGaugeProgress(value, minVal, maxVal)

                WidgetUiState(
                    widgetId = widget.id,
                    title = widget.title,
                    type = widget.type,
                    unit = widget.unit,
                    isConfigured = true,
                    singleValue = ChartMathAndFormatter.formatValue(value, widget.decimalPlaces),
                    gaugeProgress = progress,
                    gaugeMinStr = ChartMathAndFormatter.formatValue(minVal, 0),
                    gaugeMaxStr = ChartMathAndFormatter.formatValue(maxVal, 0),
                    timestampStr = timestampStr,
                )
            }

            WidgetType.HISTORY_CHART -> {
                val pointsArr = cacheObj.optJSONArray("points")
                val pointValues = mutableListOf<Double>()
                if (pointsArr != null) {
                    for (i in 0 until pointsArr.length()) {
                        val p = pointsArr.getJSONObject(i)
                        pointValues.add(p.getDouble("v"))
                    }
                }
                val normalized = ChartMathAndFormatter.normalizePoints(pointValues)
                val minVal = pointValues.minOrNull()
                val maxVal = pointValues.maxOrNull()
                val latest = pointValues.lastOrNull()

                WidgetUiState(
                    widgetId = widget.id,
                    title = widget.title,
                    type = widget.type,
                    unit = widget.unit,
                    isConfigured = true,
                    singleValue = ChartMathAndFormatter.formatValue(latest, widget.decimalPlaces),
                    chartNormalizedPoints = normalized,
                    chartValues = pointValues,
                    chartStyle = widget.chartStyle,
                    chartMinStr = ChartMathAndFormatter.formatValue(minVal, widget.decimalPlaces),
                    chartMaxStr = ChartMathAndFormatter.formatValue(maxVal, widget.decimalPlaces),
                    timestampStr = timestampStr,
                )
            }

            WidgetType.AGGREGATE -> {
                val aggObj = cacheObj.optJSONObject("aggregates")
                val map = mutableMapOf<String, String>()
                if (aggObj != null) {
                    aggObj.keys().forEach { k ->
                        val v = aggObj.getDouble(k)
                        map[k] = ChartMathAndFormatter.formatValue(v, widget.decimalPlaces)
                    }
                }
                WidgetUiState(
                    widgetId = widget.id,
                    title = widget.title,
                    type = widget.type,
                    unit = widget.unit,
                    isConfigured = true,
                    aggregates = map,
                    timestampStr = timestampStr,
                )
            }

            WidgetType.MULTI_VALUE -> {
                val valObj = cacheObj.optJSONObject("values")
                val map = mutableMapOf<String, String>()
                if (valObj != null) {
                    valObj.keys().forEach { f ->
                        val item = valObj.getJSONObject(f)
                        val v = item.getDouble("value")
                        map[f] = ChartMathAndFormatter.formatValue(v, null)
                    }
                }
                val errObj = cacheObj.optJSONObject("valueErrors")
                errObj?.keys()?.forEach { f -> map[f] = "Fehler: " + errObj.getString(f) }
                WidgetUiState(
                    widgetId = widget.id,
                    title = widget.title,
                    type = widget.type,
                    unit = widget.unit,
                    isConfigured = true,
                    multiValues = map,
                    timestampStr = timestampStr,
                )
            }
        }
}
