package io.github.mgasc.influx_sensor_widgets.model

data class SensorQueryItem(
    val field: String,
    val label: String? = null,
    val unit: String? = null,
    val decimalPlaces: Int? = null,
)
