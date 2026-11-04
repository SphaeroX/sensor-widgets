package io.github.sphaerox.influx_sensor_widgets.model

enum class ThresholdOperator(
    val wireName: String,
) {
    GREATER_THAN("greaterThan"),
    LESS_THAN("lessThan"),
    ;

    companion object {
        fun fromWireName(value: String): ThresholdOperator =
            entries.firstOrNull { it.wireName == value }
                ?: throw IllegalArgumentException("Unknown ThresholdOperator: $value")
    }
}

data class ThresholdRule(
    val operator: ThresholdOperator,
    val value: Double,
    val color: String? = null,
    val activeColor: String? = null,
    val inactiveColor: String? = null,
) {
    fun matches(actualValue: Double): Boolean =
        when (operator) {
            ThresholdOperator.GREATER_THAN -> actualValue > value
            ThresholdOperator.LESS_THAN -> actualValue < value
        }
}
