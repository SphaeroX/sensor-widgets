package io.github.mgasc.influx_sensor_widgets.glance

import io.github.mgasc.influx_sensor_widgets.glance.chart.ChartRenderPlan
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetSizingTest {
    @Test
    fun chartAreaGrowsWithWidgetHeight() {
        val small = WidgetSizing.chartAreaDp(widthDp = 250f, heightDp = 110f, fontScale = 1f)
        val large = WidgetSizing.chartAreaDp(widthDp = 250f, heightDp = 300f, fontScale = 1f)

        assertTrue(large.second > small.second)
        assertEquals(190f, large.second - small.second, 0.01f)
    }

    @Test
    fun chartAreaGrowsWithWidgetWidth() {
        val narrow = WidgetSizing.chartAreaDp(widthDp = 150f, heightDp = 200f, fontScale = 1f)
        val wide = WidgetSizing.chartAreaDp(widthDp = 350f, heightDp = 200f, fontScale = 1f)

        assertEquals(200f, wide.first - narrow.first, 0.01f)
    }

    @Test
    fun chartAreaNeverCollapsesOnTinyWidgets() {
        val area = WidgetSizing.chartAreaDp(widthDp = 40f, heightDp = 40f, fontScale = 1.4f)

        assertTrue(area.first >= WidgetSizing.MIN_CHART_DP)
        assertTrue(area.second >= WidgetSizing.MIN_CHART_DP)
    }

    @Test
    fun largerFontScaleLeavesLessRoomForChart() {
        val normal = WidgetSizing.chartAreaDp(widthDp = 250f, heightDp = 250f, fontScale = 1f)
        val big = WidgetSizing.chartAreaDp(widthDp = 250f, heightDp = 250f, fontScale = 1.4f)

        assertTrue(big.second < normal.second)
    }

    @Test
    fun bitmapSizeUsesDensityWhenWithinBudget() {
        val (w, h) = WidgetSizing.chartBitmapSize(widthDp = 200f, heightDp = 100f, density = 2f)

        assertEquals(400, w)
        assertEquals(200, h)
    }

    @Test
    fun bitmapSizeScalesDownUniformlyToKeepAspectRatio() {
        val (w, h) = WidgetSizing.chartBitmapSize(widthDp = 330f, heightDp = 220f, density = 3f)

        assertTrue(w <= ChartRenderPlan.MAX_WIDTH)
        assertTrue(h <= ChartRenderPlan.MAX_HEIGHT)
        assertEquals(330f / 220f, w.toFloat() / h, 0.02f)
    }

    @Test
    fun bitmapSizeForTallChartIsNotSquashedToOldFixedHeight() {
        val (_, h) = WidgetSizing.chartBitmapSize(widthDp = 300f, heightDp = 250f, density = 2.75f)

        assertTrue("height was $h", h > 240)
    }

    @Test
    fun multiValueShowsMoreRowsOnTallerWidgets() {
        val small = WidgetSizing.multiValueRowCount(heightDp = 110f, fontScale = 1f)
        val tall = WidgetSizing.multiValueRowCount(heightDp = 300f, fontScale = 1f)

        assertTrue(tall > small)
        assertTrue(small >= 1)
    }

    @Test
    fun multiValueAlwaysShowsAtLeastOneRow() {
        assertEquals(1, WidgetSizing.multiValueRowCount(heightDp = 20f, fontScale = 1.4f))
    }

    @Test
    fun primaryValueScaleGrowsWithHeightButStaysBounded() {
        assertEquals(1f, WidgetSizing.primaryValueScale(heightDp = 100f), 0.001f)
        assertTrue(WidgetSizing.primaryValueScale(heightDp = 250f) > 1f)
        assertEquals(WidgetSizing.MAX_PRIMARY_SCALE, WidgetSizing.primaryValueScale(heightDp = 2000f), 0.001f)
    }
}
