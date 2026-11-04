package io.github.sphaerox.influx_sensor_widgets.glance.chart

import io.github.sphaerox.influx_sensor_widgets.model.ColorStop
import kotlin.math.floor

/** Colors (ARGB) and 0..1 positions of a vertical gradient; position 0 is the bottom of the chart. */
data class ChartGradient(
    val colors: List<Int>,
    val positions: List<Float>,
)

/**
 * Color gradient helpers shared with Dart and Swift
 * (contract: `fixtures/chart/color_interpolation_cases.json`).
 */
object ChartColor {
    private val hexPattern = Regex("^#?([0-9a-fA-F]{6})$")

    fun parseHex(text: String): Int? {
        val match = hexPattern.matchEntire(text.trim()) ?: return null
        return (0xFF000000L or match.groupValues[1].toLong(16)).toInt()
    }

    fun formatHex(argb: Int): String = "#" + "%06X".format(argb and 0xFFFFFF)

    private fun validSorted(stops: List<ColorStop>): List<ColorStop> = stops.filter { parseHex(it.color) != null }.sortedBy { it.value }

    private fun lerp(
        a: Int,
        b: Int,
        t: Double,
    ): Int = floor(a + (b - a) * t + 0.5).toInt()

    /** Color for [value]; channels are interpolated linearly and rounded half up (values are non-negative). */
    fun interpolate(
        stops: List<ColorStop>,
        value: Double,
    ): Int? {
        val sorted = validSorted(stops)
        if (sorted.isEmpty()) return null
        if (value <= sorted.first().value) return parseHex(sorted.first().color)
        if (value >= sorted.last().value) return parseHex(sorted.last().color)

        for (i in 0 until sorted.size - 1) {
            val lo = sorted[i]
            val hi = sorted[i + 1]
            if (value >= lo.value && value <= hi.value) {
                val span = hi.value - lo.value
                val t = if (span == 0.0) 0.0 else (value - lo.value) / span
                val a = parseHex(lo.color)!!
                val b = parseHex(hi.color)!!
                val r = lerp((a shr 16) and 0xFF, (b shr 16) and 0xFF, t)
                val g = lerp((a shr 8) and 0xFF, (b shr 8) and 0xFF, t)
                val bl = lerp(a and 0xFF, b and 0xFF, t)
                return (0xFF shl 24) or (r shl 16) or (g shl 8) or bl
            }
        }
        return parseHex(sorted.last().color)
    }

    fun buildGradient(
        stops: List<ColorStop>,
        minValue: Double,
        maxValue: Double,
    ): ChartGradient? {
        val sorted = validSorted(stops)
        if (sorted.isEmpty()) return null

        if (maxValue <= minValue) {
            val c = interpolate(sorted, minValue)!!
            return ChartGradient(listOf(c, c), listOf(0f, 1f))
        }

        val span = maxValue - minValue
        val colors = mutableListOf(interpolate(sorted, minValue)!!)
        val positions = mutableListOf(0f)
        for (stop in sorted) {
            if (stop.value > minValue && stop.value < maxValue) {
                positions.add(((stop.value - minValue) / span).toFloat())
                colors.add(parseHex(stop.color)!!)
            }
        }
        colors.add(interpolate(sorted, maxValue)!!)
        positions.add(1f)
        return ChartGradient(colors, positions)
    }
}
