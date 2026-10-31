package io.github.mgasc.influx_sensor_widgets.glance.chart

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object ChartMathAndFormatter {
    fun normalizePoints(points: List<Double>): List<Float> {
        if (points.isEmpty()) return emptyList()
        if (points.size == 1) return listOf(0.5f)

        val min = points.minOrNull() ?: 0.0
        val max = points.maxOrNull() ?: 0.0
        val range = max - min

        if (range <= 0.000001) {
            return points.map { 0.5f }
        }

        return points.map { ((it - min) / range).toFloat() }
    }

    fun calculateGaugeProgress(
        value: Double,
        min: Double,
        max: Double,
    ): Float {
        if (max <= min) return 0.0f
        val clamped = value.coerceIn(min, max)
        return ((clamped - min) / (max - min)).toFloat()
    }

    fun formatValue(
        value: Double?,
        decimalPlaces: Int?,
    ): String {
        if (value == null) return "--"
        return if (decimalPlaces != null) {
            String.format(Locale.US, "%.${decimalPlaces}f", value)
        } else {
            if (value == value.toLong().toDouble()) {
                value.toLong().toString()
            } else {
                String.format(Locale.US, "%.1f", value)
            }
        }
    }

    fun formatTimestamp(epochMs: Long): String {
        if (epochMs <= 0L) return "--:--"
        val sdf = SimpleDateFormat("HH:mm", Locale.getDefault())
        return sdf.format(Date(epochMs))
    }

    fun formatWithUnit(
        valueStr: String,
        unit: String?,
    ): String =
        if (unit.isNullOrBlank()) {
            valueStr
        } else {
            "$valueStr $unit"
        }
}
