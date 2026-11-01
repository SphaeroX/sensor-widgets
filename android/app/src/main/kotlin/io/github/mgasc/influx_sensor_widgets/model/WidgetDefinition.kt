package io.github.mgasc.influx_sensor_widgets.model

data class WidgetDefinition(
    val id: String,
    val type: WidgetType,
    val title: String,
    val connectionId: String,
    val measurement: String,
    val field: String? = null,
    val tagFilters: Map<String, String>? = null,
    val unit: String? = null,
    val decimalPlaces: Int? = null,
    val refreshIntervalMinutes: Int = 15,
    val timeRange: String? = null,
    val aggregationInterval: String? = null,
    val aggregateFunction: String? = null,
    val threshold: ThresholdRule? = null,
    val min: Double? = null,
    val max: Double? = null,
    val thresholds: List<ThresholdRule>? = null,
    val items: List<SensorQueryItem>? = null,
    val formula: String? = null,
    val formulaVariables: List<FormulaVariable>? = null,
)
