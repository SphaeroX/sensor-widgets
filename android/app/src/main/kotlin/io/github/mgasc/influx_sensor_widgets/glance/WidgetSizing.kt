package io.github.mgasc.influx_sensor_widgets.glance

import io.github.mgasc.influx_sensor_widgets.glance.chart.ChartRenderPlan
import kotlin.math.floor
import kotlin.math.roundToInt
import kotlin.math.sqrt

/**
 * Pure layout math that lets the Glance content follow the real widget size
 * (`SizeMode.Exact` + `LocalSize`). Heights mirror the fixed parts of the layout in
 * [SensorGlanceAppWidget]: 12 dp root padding per side, header row, spacers, value row.
 */
object WidgetSizing {
    const val MIN_CHART_DP = 24f
    const val MAX_PRIMARY_SCALE = 2f

    /** Pixel budget of one chart bitmap (about 720 KB ARGB_8888), keeps RemoteViews updates small. */
    const val MAX_CHART_PIXELS = 180_000

    /** Tap area of the ↻ button in the top-end corner; the glyph itself stays small. */
    const val REFRESH_TOUCH_TARGET_DP = 56f

    /** Width the header row keeps free for the ↻ glyph (gap plus glyph), drawn by the overlay. */
    const val REFRESH_GLYPH_SLOT_DP = 20f

    /** Root padding of both sides together (12 dp per side). */
    const val ROOT_PADDING_DP = 24f
    private const val HEADER_DP = 20f
    private const val HEADER_GAP_DP = 6f
    private const val VALUE_ROW_DP = 22f
    private const val VALUE_GAP_DP = 4f
    private const val MULTI_ROW_DP = 18f
    private const val PRIMARY_BASE_HEIGHT_DP = 120f

    /** Width and height (dp) left for the history chart below header and value row. */
    fun chartAreaDp(
        widthDp: Float,
        heightDp: Float,
        fontScale: Float,
    ): Pair<Float, Float> {
        val width = widthDp - ROOT_PADDING_DP
        val height = heightDp - ROOT_PADDING_DP - HEADER_GAP_DP - VALUE_GAP_DP - (HEADER_DP + VALUE_ROW_DP) * fontScale
        return width.coerceAtLeast(MIN_CHART_DP) to height.coerceAtLeast(MIN_CHART_DP)
    }

    /**
     * Bitmap size in pixels for a chart area, scaled down uniformly (aspect ratio kept)
     * when it exceeds [MAX_CHART_PIXELS] or the [ChartRenderPlan] dimension limits.
     */
    fun chartBitmapSize(
        widthDp: Float,
        heightDp: Float,
        density: Float,
    ): Pair<Int, Int> {
        val w = widthDp * density
        val h = heightDp * density
        val scale =
            minOf(
                1f,
                sqrt(MAX_CHART_PIXELS / (w * h)),
                ChartRenderPlan.MAX_WIDTH / w,
                ChartRenderPlan.MAX_HEIGHT / h,
            )
        return (w * scale).roundToInt().coerceAtLeast(1) to (h * scale).roundToInt().coerceAtLeast(1)
    }

    /** Number of multi-value rows that fit below the header (at least one). */
    fun multiValueRowCount(
        heightDp: Float,
        fontScale: Float,
    ): Int {
        val available = heightDp - ROOT_PADDING_DP - HEADER_GAP_DP - HEADER_DP * fontScale
        return floor(available / (MULTI_ROW_DP * fontScale)).toInt().coerceAtLeast(1)
    }

    /** Extra scale for the big primary value on taller widgets, between 1 and [MAX_PRIMARY_SCALE]. */
    fun primaryValueScale(heightDp: Float): Float = (heightDp / PRIMARY_BASE_HEIGHT_DP).coerceIn(1f, MAX_PRIMARY_SCALE)
}
