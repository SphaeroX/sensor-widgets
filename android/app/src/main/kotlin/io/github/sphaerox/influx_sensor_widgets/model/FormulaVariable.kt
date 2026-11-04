package io.github.sphaerox.influx_sensor_widgets.model

data class FormulaVariable(
    val name: String,
    val field: String,
    val measurement: String? = null,
    val tagFilters: Map<String, String>? = null,
    val label: String? = null,
)
