package io.github.sphaerox.influx_sensor_widgets.glance

import io.github.sphaerox.influx_sensor_widgets.l10n.TestTexts
import io.github.sphaerox.influx_sensor_widgets.model.WidgetDefinition
import io.github.sphaerox.influx_sensor_widgets.model.WidgetType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetUiStateMapperTest {
    private val testWidget =
        WidgetDefinition(
            id = "w1",
            type = WidgetType.SINGLE_VALUE,
            title = "Office Temperature",
            connectionId = "c1",
            measurement = "climate",
            field = "temp",
            unit = "°C",
            decimalPlaces = 1,
        )

    @Test
    fun testUnconfiguredState() {
        val state =
            WidgetUiStateMapper.mapToUiState(
                appWidgetId = 101,
                boundWidgetId = null,
                widget = null,
                cacheJson = null,
                texts = TestTexts.german,
            )
        assertFalse(state.isConfigured)
        assertEquals("Widget konfigurieren", state.title)
    }

    @Test
    fun testLoadingState() {
        val state =
            WidgetUiStateMapper.mapToUiState(
                appWidgetId = 101,
                boundWidgetId = "w1",
                widget = testWidget,
                cacheJson = null,
                texts = TestTexts.german,
            )
        assertTrue(state.isConfigured)
        assertTrue(state.isLoading)
        assertEquals("Office Temperature", state.title)
    }

    @Test
    fun testErrorState() {
        val cacheJson = """{"error": "Verbindungsfehler"}"""
        val state =
            WidgetUiStateMapper.mapToUiState(
                appWidgetId = 101,
                boundWidgetId = "w1",
                widget = testWidget,
                cacheJson = cacheJson,
                texts = TestTexts.german,
            )
        assertTrue(state.isConfigured)
        assertFalse(state.isLoading)
        assertEquals("Verbindungsfehler", state.errorMessage)
    }

    @Test
    fun testSingleValueSuccess() {
        val cacheJson = """{"value": 22.4, "timestamp": 1730370000000}"""
        val state =
            WidgetUiStateMapper.mapToUiState(
                appWidgetId = 101,
                boundWidgetId = "w1",
                widget = testWidget,
                cacheJson = cacheJson,
                texts = TestTexts.german,
            )
        assertTrue(state.isConfigured)
        assertNull(state.errorMessage)
        assertEquals("22.4", state.singleValue)
        assertEquals("°C", state.unit)
        assertNotNull(state.timestampStr)
    }

    @Test
    fun testHistoryChartSuccess() {
        val chartWidget = testWidget.copy(type = WidgetType.HISTORY_CHART)
        val cacheJson = """{"points": [{"t": 1730352000000, "v": 19.8}, {"t": 1730370000000, "v": 21.5}]}"""
        val state =
            WidgetUiStateMapper.mapToUiState(
                appWidgetId = 101,
                boundWidgetId = "w1",
                widget = chartWidget,
                cacheJson = cacheJson,
                texts = TestTexts.german,
            )
        assertTrue(state.isConfigured)
        assertEquals(2, state.chartNormalizedPoints?.size)
        assertEquals("21.5", state.singleValue)
    }

    @Test
    fun testAggregateSuccess() {
        val aggWidget = testWidget.copy(type = WidgetType.AGGREGATE)
        val cacheJson = """{"aggregates": {"min": 18.2, "mean": 21.1, "max": 23.9}}"""
        val state =
            WidgetUiStateMapper.mapToUiState(
                appWidgetId = 101,
                boundWidgetId = "w1",
                widget = aggWidget,
                cacheJson = cacheJson,
                texts = TestTexts.german,
            )
        assertTrue(state.isConfigured)
        assertEquals("18.2", state.aggregates?.get("min"))
        assertEquals("21.1", state.aggregates?.get("mean"))
        assertEquals("23.9", state.aggregates?.get("max"))
    }

    @Test
    fun testFormulaDivisionByZeroErrorState() {
        val cacheJson = """{"error": "Division durch Null", "timestamp": 1730370000000}"""
        val state =
            WidgetUiStateMapper.mapToUiState(
                appWidgetId = 101,
                boundWidgetId = "w1",
                widget = testWidget,
                cacheJson = cacheJson,
                texts = TestTexts.german,
            )
        assertTrue(state.isConfigured)
        assertFalse(state.isLoading)
        assertEquals("Division durch Null", state.errorMessage)
    }

    @Test
    fun testFormulaMissingVariableErrorState() {
        val cacheJson = """{"error": "Fehlende Variable: B", "timestamp": 1730370000000}"""
        val state =
            WidgetUiStateMapper.mapToUiState(
                appWidgetId = 101,
                boundWidgetId = "w1",
                widget = testWidget,
                cacheJson = cacheJson,
                texts = TestTexts.german,
            )
        assertTrue(state.isConfigured)
        assertFalse(state.isLoading)
        assertEquals("Fehlende Variable: B", state.errorMessage)
    }

    @Test
    fun testFormulaIndicatorLampActiveState() {
        val lampWidget = testWidget.copy(type = WidgetType.INDICATOR_LAMP)
        val cacheJson = """{"value": 35.0, "isActive": true, "timestamp": 1730370000000}"""
        val state =
            WidgetUiStateMapper.mapToUiState(
                appWidgetId = 101,
                boundWidgetId = "w1",
                widget = lampWidget,
                cacheJson = cacheJson,
                texts = TestTexts.german,
            )
        assertTrue(state.isConfigured)
        assertNull(state.errorMessage)
        assertEquals("35.0", state.singleValue)
        assertEquals(true, state.isIndicatorActive)
    }
}
