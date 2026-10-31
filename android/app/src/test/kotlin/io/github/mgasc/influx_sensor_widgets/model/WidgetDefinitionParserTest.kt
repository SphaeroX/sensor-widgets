package io.github.mgasc.influx_sensor_widgets.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class WidgetDefinitionParserTest {
    private fun loadFixturesFile(relativePath: String): String {
        val candidates =
            listOf(
                File("../../fixtures/$relativePath"),
                File("../fixtures/$relativePath"),
                File("fixtures/$relativePath"),
            )
        val file =
            candidates.firstOrNull { it.exists() }
                ?: throw IllegalArgumentException("Fixture file not found: $relativePath")
        return file.readText()
    }

    @Test
    fun testParseWidgetDefinitionsV1Fixture() {
        val jsonStr = loadFixturesFile("widget_definitions/widget_definitions_v1.json")
        val widgets = WidgetDefinitionParser.parseDefinitionsList(jsonStr)

        assertEquals(6, widgets.size)

        // 1. single_value
        val singleVal = widgets[0]
        assertEquals("widget-1-single-value", singleVal.id)
        assertEquals(WidgetType.SINGLE_VALUE, singleVal.type)
        assertEquals("Living Room Temp", singleVal.title)
        assertEquals("conn-home-1", singleVal.connectionId)
        assertEquals("temperature", singleVal.measurement)
        assertEquals("value", singleVal.field)
        assertEquals(mapOf("room" to "living_room"), singleVal.tagFilters)
        assertEquals("°C", singleVal.unit)
        assertEquals(1, singleVal.decimalPlaces)
        assertEquals(15, singleVal.refreshIntervalMinutes)

        // 2. history_chart
        val history = widgets[1]
        assertEquals("widget-2-history-chart", history.id)
        assertEquals(WidgetType.HISTORY_CHART, history.type)
        assertEquals("24h", history.timeRange)
        assertEquals("1h", history.aggregationInterval)

        // 3. indicator_lamp
        val lamp = widgets[2]
        assertEquals("widget-3-indicator-lamp", lamp.id)
        assertEquals(WidgetType.INDICATOR_LAMP, lamp.type)
        val threshold = lamp.threshold
        assertNotNull(threshold)
        assertEquals(ThresholdOperator.GREATER_THAN, threshold!!.operator)
        assertEquals(1000.0, threshold.value, 0.001)
        assertEquals("#FF0000", threshold.activeColor)
        assertEquals("#00FF00", threshold.inactiveColor)
        assertTrue(threshold.matches(1050.0))
        assertFalse(threshold.matches(950.0))

        // 4. multi_value
        val multi = widgets[3]
        assertEquals("widget-4-multi-value", multi.id)
        assertEquals(WidgetType.MULTI_VALUE, multi.type)
        assertEquals(3, multi.items?.size)
        assertEquals("temperature", multi.items?.get(0)?.field)
        assertEquals("Temp", multi.items?.get(0)?.label)

        // 5. aggregate
        val agg = widgets[4]
        assertEquals("widget-5-aggregate", agg.id)
        assertEquals(WidgetType.AGGREGATE, agg.type)
        assertEquals("max", agg.aggregateFunction)

        // 6. gauge_bar
        val gauge = widgets[5]
        assertEquals("widget-6-gauge-bar", gauge.id)
        assertEquals(WidgetType.GAUGE_BAR, gauge.type)
        assertEquals(0.0, gauge.min ?: -1.0, 0.001)
        assertEquals(100.0, gauge.max ?: -1.0, 0.001)
        assertEquals(3, gauge.thresholds?.size)
    }
}
