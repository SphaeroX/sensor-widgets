package io.github.sphaerox.influx_sensor_widgets.glance.chart

import io.github.sphaerox.influx_sensor_widgets.glance.WidgetUiStateMapper
import io.github.sphaerox.influx_sensor_widgets.l10n.TestTexts
import io.github.sphaerox.influx_sensor_widgets.model.ChartStyle
import io.github.sphaerox.influx_sensor_widgets.model.ColorStop
import io.github.sphaerox.influx_sensor_widgets.model.WidgetDefinitionParser
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class ChartStyleTest {
    private fun fixtureText(relative: String): String {
        val candidates =
            listOf(
                File("../../fixtures/$relative"),
                File("../fixtures/$relative"),
                File("fixtures/$relative"),
            )
        return candidates.first { it.exists() }.readText()
    }

    private val stops =
        listOf(
            ColorStop(0.0, "#FF0000"),
            ColorStop(50.0, "#FFFF00"),
            ColorStop(100.0, "#00FF00"),
        )

    @Test
    fun interpolationMatchesSharedFixture() {
        val cases = JSONObject(fixtureText("chart/color_interpolation_cases.json")).getJSONArray("cases")
        assertTrue(cases.length() > 0)
        for (i in 0 until cases.length()) {
            val c = cases.getJSONObject(i)
            val stopArr = c.getJSONArray("stops")
            val caseStops =
                (0 until stopArr.length()).map {
                    val s = stopArr.getJSONObject(it)
                    ColorStop(s.getDouble("value"), s.getString("color"))
                }
            val result = ChartColor.interpolate(caseStops, c.getDouble("value"))
            val expected = if (c.isNull("expected")) null else c.getString("expected")
            assertEquals("case ${c.getString("name")}", expected, result?.let { ChartColor.formatHex(it) })
        }
    }

    @Test
    fun hexParsingAndFormatting() {
        assertEquals(0xFFFF8000.toInt(), ChartColor.parseHex("#FF8000"))
        assertEquals(0xFFFF8000.toInt(), ChartColor.parseHex("ff8000"))
        assertNull(ChartColor.parseHex("#12345"))
        assertNull(ChartColor.parseHex("red"))
        assertEquals("#66FF00", ChartColor.formatHex(0xFF66FF00.toInt()))
    }

    @Test
    fun gradientPositionsFollowVisibleRange() {
        val g = ChartColor.buildGradient(stops, 0.0, 100.0)!!
        assertEquals(listOf(0.0f, 0.5f, 1.0f), g.positions)
        assertEquals(listOf("#FF0000", "#FFFF00", "#00FF00"), g.colors.map { ChartColor.formatHex(it) })

        val inner = ChartColor.buildGradient(stops, 25.0, 75.0)!!
        assertEquals(0.0f, inner.positions.first(), 0f)
        assertEquals(1.0f, inner.positions.last(), 0f)
        assertTrue(inner.positions.contains(0.5f))
        assertEquals(inner.colors.size, inner.positions.size)
    }

    @Test
    fun gradientFallsBackForInvalidOrMissingStops() {
        assertNull(ChartColor.buildGradient(emptyList(), 0.0, 10.0))
        assertNull(ChartColor.buildGradient(listOf(ColorStop(0.0, "nope")), 0.0, 10.0))
        val flat = ChartColor.buildGradient(stops, 50.0, 50.0)!!
        assertEquals(1, flat.colors.toSet().size)
        assertEquals("#FFFF00", ChartColor.formatHex(flat.colors.first()))
    }

    @Test
    fun parserReadsChartStyleFromSharedFixture() {
        val widgets =
            WidgetDefinitionParser.parseDefinitionsList(fixtureText("widget_definitions/widget_definition_chart_style.json"))
        val style = widgets.first().chartStyle!!
        assertEquals(3, style.colorStops.size)
        assertEquals(ColorStop(50.0, "#FFFF00"), style.colorStops[1])
        assertTrue(style.fillArea && style.showGrid && style.showAxes && style.markMinMax)
        assertEquals(3.0f, style.lineWidth, 0f)
        assertNull(widgets.last().chartStyle)
    }

    @Test
    fun styleDefaultsWhenFieldsAreMissing() {
        val widget =
            WidgetDefinitionParser
                .parseDefinitionsList(
                    """[{"id":"w","type":"history_chart","title":"t","connectionId":"c","measurement":"m","chartStyle":{}}]""",
                ).single()
        val style = widget.chartStyle!!
        assertTrue(style.colorStops.isEmpty())
        assertFalse(style.fillArea)
        assertEquals(ChartStyle.DEFAULT_LINE_WIDTH, style.lineWidth, 0f)
    }

    @Test
    fun renderPlanInvertsYAndFindsExtremes() {
        val plan = ChartRenderPlan.create(listOf(10.0, 40.0, 30.0, 90.0, 60.0), ChartStyle(), 300, 120)!!
        assertEquals(5, plan.points.size)
        // The maximum is drawn at the top, the minimum at the bottom.
        assertEquals(plan.top, plan.points[3].second, 0.001f)
        assertEquals(plan.bottom, plan.points[0].second, 0.001f)
        assertEquals(0, plan.minIndex)
        assertEquals(3, plan.maxIndex)
        assertEquals(plan.left, plan.points.first().first, 0.001f)
        assertEquals(plan.right, plan.points.last().first, 0.001f)
    }

    @Test
    fun renderPlanHonorsGridAxesAndGradient() {
        val values = listOf(0.0, 100.0, 50.0)
        assertTrue(ChartRenderPlan.create(values, ChartStyle(), 300, 120)!!.gridYs.isEmpty())
        assertEquals(4, ChartRenderPlan.create(values, ChartStyle(showGrid = true), 300, 120)!!.gridYs.size)

        assertNull(ChartRenderPlan.create(values, ChartStyle(), 300, 120)!!.axisLabels)
        val labels = ChartRenderPlan.create(values, ChartStyle(showAxes = true), 300, 120)!!.axisLabels!!
        assertEquals("100.0", labels.first)
        assertEquals("0.0", labels.second)

        assertNull(ChartRenderPlan.create(values, ChartStyle(), 300, 120)!!.gradient)
        assertNotNull(ChartRenderPlan.create(values, ChartStyle(colorStops = stops), 300, 120)!!.gradient)
    }

    @Test
    fun renderPlanNeedsAtLeastTwoPointsAndSurvivesFlatSeries() {
        assertNull(ChartRenderPlan.create(listOf(5.0), ChartStyle(), 300, 120))
        val flat = ChartRenderPlan.create(listOf(5.0, 5.0, 5.0), ChartStyle(colorStops = stops), 300, 120)!!
        assertEquals(3, flat.points.size)
        assertFalse(flat.points.any { it.second.isNaN() })
    }

    @Test
    fun renderPlanClampsBitmapSize() {
        val plan = ChartRenderPlan.create(listOf(1.0, 2.0), ChartStyle(), 5000, 5000)!!
        assertTrue(plan.width <= ChartRenderPlan.MAX_WIDTH)
        assertTrue(plan.height <= ChartRenderPlan.MAX_HEIGHT)
    }

    @Test
    fun uiStateCarriesChartValuesAndStyle() {
        val widget =
            WidgetDefinitionParser
                .parseDefinitionsList(fixtureText("widget_definitions/widget_definition_chart_style.json"))
                .first()
        val state =
            WidgetUiStateMapper.mapToUiState(
                appWidgetId = 1,
                boundWidgetId = widget.id,
                widget = widget,
                cacheJson = """{"points":[{"t":1,"v":10.0},{"t":2,"v":20.0}],"timestamp":5}""",
                texts = TestTexts.german,
            )
        assertEquals(listOf(10.0, 20.0), state.chartValues)
        assertEquals(widget.chartStyle, state.chartStyle)
    }
}
