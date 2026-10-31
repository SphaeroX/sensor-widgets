package io.github.mgasc.influx_sensor_widgets.glance.chart

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ChartMathAndFormatterTest {
    @Test
    fun testNormalizePointsEmptyAndSingle() {
        assertTrue(ChartMathAndFormatter.normalizePoints(emptyList()).isEmpty())

        val single = ChartMathAndFormatter.normalizePoints(listOf(42.0))
        assertEquals(1, single.size)
        assertEquals(0.5f, single[0], 0.001f)
    }

    @Test
    fun testNormalizePointsIdenticalValues() {
        val identical = ChartMathAndFormatter.normalizePoints(listOf(20.0, 20.0, 20.0))
        assertEquals(3, identical.size)
        assertEquals(0.5f, identical[0], 0.001f)
        assertEquals(0.5f, identical[1], 0.001f)
        assertEquals(0.5f, identical[2], 0.001f)
    }

    @Test
    fun testNormalizePointsStandardAndNegative() {
        val points = listOf(-10.0, 0.0, 10.0)
        val normalized = ChartMathAndFormatter.normalizePoints(points)

        assertEquals(3, normalized.size)
        assertEquals(0.0f, normalized[0], 0.001f)
        assertEquals(0.5f, normalized[1], 0.001f)
        assertEquals(1.0f, normalized[2], 0.001f)
    }

    @Test
    fun testCalculateGaugeProgress() {
        assertEquals(0.5f, ChartMathAndFormatter.calculateGaugeProgress(50.0, 0.0, 100.0), 0.001f)
        assertEquals(0.0f, ChartMathAndFormatter.calculateGaugeProgress(-10.0, 0.0, 100.0), 0.001f) // clamped to 0
        assertEquals(1.0f, ChartMathAndFormatter.calculateGaugeProgress(150.0, 0.0, 100.0), 0.001f) // clamped to 1
        assertEquals(0.0f, ChartMathAndFormatter.calculateGaugeProgress(10.0, 50.0, 50.0), 0.001f) // min == max edge case
    }

    @Test
    fun testFormatValue() {
        assertEquals("--", ChartMathAndFormatter.formatValue(null, null))
        assertEquals("22.4", ChartMathAndFormatter.formatValue(22.44, 1))
        assertEquals("22", ChartMathAndFormatter.formatValue(22.44, 0))
    }

    @Test
    fun testFormatWithUnit() {
        assertEquals("22.4 °C", ChartMathAndFormatter.formatWithUnit("22.4", "°C"))
        assertEquals("22.4", ChartMathAndFormatter.formatWithUnit("22.4", null))
        assertEquals("22.4", ChartMathAndFormatter.formatWithUnit("22.4", ""))
    }
}
