package io.github.sphaerox.influx_sensor_widgets.model

/** One color anchor of a value gradient; [color] is `#RRGGBB`. */
data class ColorStop(
    val value: Double,
    val color: String,
)

/** Optional history chart styling (contract field `chartStyle`). Mirrors the Dart `ChartStyle`. */
data class ChartStyle(
    val colorStops: List<ColorStop> = emptyList(),
    val fillArea: Boolean = false,
    val showGrid: Boolean = false,
    val showAxes: Boolean = false,
    val markMinMax: Boolean = false,
    val lineWidth: Float = DEFAULT_LINE_WIDTH,
) {
    companion object {
        const val DEFAULT_LINE_WIDTH = 2.0f
    }
}
