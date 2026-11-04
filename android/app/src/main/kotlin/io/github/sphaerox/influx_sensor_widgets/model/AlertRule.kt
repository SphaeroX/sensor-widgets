package io.github.sphaerox.influx_sensor_widgets.model

/**
 * Push notification rule (contract field `alerts`). [target] is `value` for the primary
 * value (single value, lamp, gauge, latest chart point; with a formula the calculated
 * value), a row `field` of a multi-value widget, or `min`/`max`/`mean` of an aggregate.
 */
data class AlertRule(
    val target: String,
    val operator: ThresholdOperator,
    val value: Double,
) {
    fun matches(actualValue: Double): Boolean =
        when (operator) {
            ThresholdOperator.GREATER_THAN -> actualValue > value
            ThresholdOperator.LESS_THAN -> actualValue < value
        }

    companion object {
        const val TARGET_VALUE = "value"
    }
}
