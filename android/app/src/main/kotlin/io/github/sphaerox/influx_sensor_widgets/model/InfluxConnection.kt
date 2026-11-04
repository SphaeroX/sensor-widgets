package io.github.sphaerox.influx_sensor_widgets.model

data class InfluxConnection(
    val id: String,
    val name: String,
    val url: String,
    val database: String,
)
