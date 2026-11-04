package io.github.sphaerox.influx_sensor_widgets.alerts

import io.github.sphaerox.influx_sensor_widgets.model.AlertRule
import io.github.sphaerox.influx_sensor_widgets.model.ThresholdOperator
import io.github.sphaerox.influx_sensor_widgets.model.WidgetDefinition
import java.util.Locale

/** German notification texts, e.g. "Temperatur: 17.2 °C (unter 18.5 °C)". */
object AlertMessage {
    private val aggregateNames = mapOf("min" to "Minimum", "max" to "Maximum", "mean" to "Mittelwert")

    fun title(widget: WidgetDefinition): String = widget.title

    fun body(
        widget: WidgetDefinition,
        hit: AlertHit,
    ): String {
        val target = hit.rule.target
        val item = widget.items?.firstOrNull { it.field == target }
        val label =
            when {
                target == AlertRule.TARGET_VALUE -> widget.title
                item != null -> item.label ?: item.field
                else -> aggregateNames[target] ?: target
            }
        val unit = (item?.unit ?: widget.unit)?.let { " $it" } ?: ""
        val decimals = (item?.decimalPlaces ?: widget.decimalPlaces ?: 1).coerceIn(0, 6)
        val direction = if (hit.rule.operator == ThresholdOperator.GREATER_THAN) "über" else "unter"
        return "$label: ${format(hit.actualValue, decimals)}$unit ($direction ${format(hit.rule.value, decimals)}$unit)"
    }

    private fun format(
        value: Double,
        decimals: Int,
    ): String = String.format(Locale.ROOT, "%.${decimals}f", value)
}
