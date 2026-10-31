package io.github.mgasc.influx_sensor_widgets.model

data class SensorDataPoint(
    val timestamp: Long,
    val value: Double,
    val field: String,
)
