package io.github.sphaerox.influx_sensor_widgets.alerts

import io.github.sphaerox.influx_sensor_widgets.l10n.TestTexts
import io.github.sphaerox.influx_sensor_widgets.model.AlertRule
import io.github.sphaerox.influx_sensor_widgets.model.SensorQueryItem
import io.github.sphaerox.influx_sensor_widgets.model.ThresholdOperator
import io.github.sphaerox.influx_sensor_widgets.model.WidgetDefinition
import io.github.sphaerox.influx_sensor_widgets.model.WidgetType
import org.junit.Assert.assertEquals
import org.junit.Test

class AlertMessageTest {
    private val iaq =
        WidgetDefinition(
            id = "w-iaq",
            type = WidgetType.SINGLE_VALUE,
            title = "IAQ Index",
            connectionId = "c",
            measurement = "sen66",
            decimalPlaces = 0,
        )

    @Test
    fun primaryValueUsesWidgetTitle() {
        val hit = AlertHit(AlertRule("value", ThresholdOperator.GREATER_THAN, 150.0), 163.4)

        assertEquals("IAQ Index", AlertMessage.title(iaq))
        assertEquals("IAQ Index: 163 (über 150)", AlertMessage.body(iaq, hit, TestTexts.german))
    }

    @Test
    fun multiValueRowUsesLabelAndUnit() {
        val widget =
            iaq.copy(
                type = WidgetType.MULTI_VALUE,
                title = "sen66",
                decimalPlaces = null,
                items = listOf(SensorQueryItem(field = "temp", label = "Temperatur", unit = "°C", decimalPlaces = 1)),
            )
        val hit = AlertHit(AlertRule("temp", ThresholdOperator.LESS_THAN, 18.5), 17.24)

        assertEquals("Temperatur: 17.2 °C (unter 18.5 °C)", AlertMessage.body(widget, hit, TestTexts.german))
    }

    @Test
    fun aggregateTargetIsNamed() {
        val widget = iaq.copy(type = WidgetType.AGGREGATE, unit = "°C", decimalPlaces = 1)
        val hit = AlertHit(AlertRule("max", ThresholdOperator.GREATER_THAN, 30.0), 31.0)

        assertEquals("Maximum: 31.0 °C (über 30.0 °C)", AlertMessage.body(widget, hit, TestTexts.german))
    }
}
