package io.github.sphaerox.influx_sensor_widgets.model

data class SensorQueryItem(
    val field: String,
    val label: String? = null,
    val unit: String? = null,
    val decimalPlaces: Int? = null,
    val formula: String? = null,
    val formulaVariables: List<FormulaVariable>? = null,
    val formulaSteps: List<FormulaStep>? = null,
)
