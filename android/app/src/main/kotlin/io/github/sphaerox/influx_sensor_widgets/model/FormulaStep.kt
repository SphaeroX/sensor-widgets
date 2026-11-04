package io.github.sphaerox.influx_sensor_widgets.model

data class FormulaStep(
    val name: String,
    val expression: String,
    val label: String? = null,
)
