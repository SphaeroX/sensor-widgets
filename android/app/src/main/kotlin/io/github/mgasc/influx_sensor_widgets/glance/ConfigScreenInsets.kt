package io.github.mgasc.influx_sensor_widgets.glance

/**
 * Padding for the edge-to-edge widget picker: base padding plus system bar and cutout
 * insets, so the status bar never covers the title or the first list entry.
 */
object ConfigScreenInsets {
    /** Returns (left, top, right, bottom) in pixels. */
    fun padding(
        basePx: Int,
        left: Int,
        top: Int,
        right: Int,
        bottom: Int,
    ): IntArray = intArrayOf(basePx + left, basePx + top, basePx + right, basePx + bottom)
}
