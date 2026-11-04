package io.github.sphaerox.influx_sensor_widgets.alerts

import io.github.sphaerox.influx_sensor_widgets.R
import io.github.sphaerox.influx_sensor_widgets.l10n.WidgetTexts
import io.github.sphaerox.influx_sensor_widgets.model.AlertRule
import io.github.sphaerox.influx_sensor_widgets.model.ThresholdOperator
import io.github.sphaerox.influx_sensor_widgets.model.WidgetDefinition
import java.util.Locale

/** Notification texts in the device language, e.g. "Temperature: 17.2 °C (below 18.5 °C)". */
object AlertMessage {
    private val aggregateNames =
        mapOf("min" to R.string.alert_target_min, "max" to R.string.alert_target_max, "mean" to R.string.alert_target_mean)

    fun title(widget: WidgetDefinition): String = widget.title

    fun body(
        widget: WidgetDefinition,
        hit: AlertHit,
        texts: WidgetTexts,
    ): String {
        val target = hit.rule.target
        val item = widget.items?.firstOrNull { it.field == target }
        val label =
            when {
                target == AlertRule.TARGET_VALUE -> widget.title
                item != null -> item.label ?: item.field
                else -> aggregateNames[target]?.let { texts.get(it) } ?: target
            }
        val unit = (item?.unit ?: widget.unit)?.let { " $it" } ?: ""
        val decimals = (item?.decimalPlaces ?: widget.decimalPlaces ?: 1).coerceIn(0, 6)
        val direction =
            texts.get(if (hit.rule.operator == ThresholdOperator.GREATER_THAN) R.string.alert_above else R.string.alert_below)
        return texts.get(
            R.string.alert_body,
            label,
            format(hit.actualValue, decimals),
            unit,
            direction,
            format(hit.rule.value, decimals),
        )
    }

    private fun format(
        value: Double,
        decimals: Int,
    ): String = String.format(Locale.ROOT, "%.${decimals}f", value)
}
