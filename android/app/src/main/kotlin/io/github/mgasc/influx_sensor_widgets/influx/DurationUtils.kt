package io.github.mgasc.influx_sensor_widgets.influx

import kotlin.math.ceil

/** Helpers for InfluxQL duration literals (`30m`, `24h`, `7d`). Mirrors the Dart `DurationUtils`. */
object DurationUtils {
    const val MAX_BUCKETS = 300
    const val DEFAULT_TARGET_BUCKETS = 60

    private val unitSeconds = mapOf('s' to 1L, 'm' to 60L, 'h' to 3600L, 'd' to 86400L, 'w' to 604800L)
    private val ladder = listOf("1m", "5m", "10m", "15m", "30m", "1h", "3h", "6h", "12h", "1d", "7d")
    private val pattern = Regex("^(\\d+)([smhdw])$")

    fun parseSeconds(duration: String): Long? {
        val match = pattern.matchEntire(duration.trim()) ?: return null
        val unit = unitSeconds.getValue(match.groupValues[2][0])
        return match.groupValues[1].toLong() * unit
    }

    fun effectiveBucketInterval(
        timeRange: String,
        requested: String?,
    ): String {
        val range = parseSeconds(timeRange) ?: return "1h"
        val requestedSeconds = requested?.let { parseSeconds(it) }
        if (requested != null && requestedSeconds != null && requestedSeconds > 0) {
            return if (range.toDouble() / requestedSeconds <= MAX_BUCKETS) {
                requested
            } else {
                coarsest(range, MAX_BUCKETS)
            }
        }
        return coarsest(range, DEFAULT_TARGET_BUCKETS)
    }

    private fun coarsest(
        range: Long,
        maxCount: Int,
    ): String {
        for (candidate in ladder) {
            if (range.toDouble() / parseSeconds(candidate)!! <= maxCount) return candidate
        }
        return "${ceil(range.toDouble() / maxCount).toLong()}s"
    }
}
