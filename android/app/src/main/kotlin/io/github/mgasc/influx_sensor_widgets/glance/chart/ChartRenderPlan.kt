package io.github.mgasc.influx_sensor_widgets.glance.chart

import io.github.mgasc.influx_sensor_widgets.model.ChartStyle
import java.util.Locale

/**
 * Pure geometry of a styled history chart. The bitmap renderer only draws what
 * this plan describes, so the layout is unit-testable without Android classes.
 */
data class ChartRenderPlan(
    val width: Int,
    val height: Int,
    val left: Float,
    val top: Float,
    val right: Float,
    val bottom: Float,
    /** Pixel positions (x, y) of the data points; y grows downward. */
    val points: List<Pair<Float, Float>>,
    val gradient: ChartGradient?,
    val gridYs: List<Float>,
    val minIndex: Int,
    val maxIndex: Int,
    /** (top label, bottom label) when axis labels are enabled. */
    val axisLabels: Pair<String, String>?,
) {
    companion object {
        /** Dimension caps; the pixel budget itself is enforced by WidgetSizing.chartBitmapSize. */
        const val MAX_WIDTH = 800
        const val MAX_HEIGHT = 600

        private const val PADDING = 6f
        private const val AXIS_LEFT = 34f

        fun create(
            values: List<Double>,
            style: ChartStyle,
            width: Int,
            height: Int,
        ): ChartRenderPlan? {
            if (values.size < 2) return null
            val w = width.coerceIn(1, MAX_WIDTH)
            val h = height.coerceIn(1, MAX_HEIGHT)

            val dataMin = values.min()
            val dataMax = values.max()
            var minValue = dataMin
            var maxValue = dataMax
            if (maxValue == minValue) {
                minValue -= 1.0
                maxValue += 1.0
            }

            val left = if (style.showAxes) AXIS_LEFT else PADDING
            val top = PADDING
            val right = w - PADDING
            val bottom = h - PADDING
            val drawWidth = right - left
            val drawHeight = bottom - top

            val points =
                values.mapIndexed { i, v ->
                    val x = left + drawWidth * i / (values.size - 1)
                    val y = bottom - (drawHeight * (v - minValue) / (maxValue - minValue)).toFloat()
                    x to y
                }

            return ChartRenderPlan(
                width = w,
                height = h,
                left = left,
                top = top,
                right = right,
                bottom = bottom,
                points = points,
                gradient = ChartColor.buildGradient(style.colorStops, minValue, maxValue),
                gridYs = if (style.showGrid) (0..3).map { top + drawHeight * it / 3 } else emptyList(),
                minIndex = values.indexOf(dataMin),
                maxIndex = values.indexOf(dataMax),
                axisLabels =
                    if (style.showAxes) {
                        String.format(Locale.US, "%.1f", dataMax) to String.format(Locale.US, "%.1f", dataMin)
                    } else {
                        null
                    },
            )
        }
    }
}
