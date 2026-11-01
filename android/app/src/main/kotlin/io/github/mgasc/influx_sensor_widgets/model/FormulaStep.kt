package io.github.mgasc.influx_sensor_widgets.model

data class FormulaStep(
    val name: String,
    val expression: String,
    val label: String? = null,
)
