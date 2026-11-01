package io.github.mgasc.influx_sensor_widgets.glance

import io.github.mgasc.influx_sensor_widgets.model.WidgetType

data class WidgetUiState(
    val widgetId: String,
    val title: String,
    val type: WidgetType,
    val unit: String? = null,
    val isConfigured: Boolean = true,
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val warningMessage: String? = null,
    val singleValue: String? = null,
    val timestampStr: String? = null,
    val isIndicatorActive: Boolean? = null,
    val gaugeProgress: Float? = null,
    val gaugeMinStr: String? = null,
    val gaugeMaxStr: String? = null,
    val chartNormalizedPoints: List<Float>? = null,
    val chartMinStr: String? = null,
    val chartMaxStr: String? = null,
    val aggregates: Map<String, String>? = null,
    val multiValues: Map<String, String>? = null,
)
