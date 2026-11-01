package io.github.mgasc.influx_sensor_widgets.glance

import io.github.mgasc.influx_sensor_widgets.glance.chart.ChartColor
import io.github.mgasc.influx_sensor_widgets.model.WidgetAppearance
import kotlin.math.floor

/**
 * Resolved look of an Android widget. Without an `appearance` the values equal the
 * original hard-coded colors, so existing widgets look unchanged. Colors are ARGB ints.
 *
 * Platform limit: `cornerRadius` is only honored on Android 12+ (Glance `cornerRadius`).
 */
data class AppearancePalette(
    val background: Int,
    val text: Int,
    val muted: Int,
    val accent: Int,
    val fontScale: Float,
    val cornerRadiusDp: Float,
) {
    companion object {
        const val MIN_FONT_SCALE = 0.8f
        const val MAX_FONT_SCALE = 1.4f
        const val MAX_CORNER_RADIUS = 32f
        private const val MUTED_ALPHA = 0xB3

        val DEFAULT_BACKGROUND = 0xFF1E1E2E.toInt()
        val DEFAULT_TEXT = 0xFFFFFFFF.toInt()
        val DEFAULT_MUTED = 0xFFA6ADC8.toInt()
        val DEFAULT_ACCENT = 0xFF89B4FA.toInt()
        const val DEFAULT_CORNER_RADIUS = 16f

        fun resolve(appearance: WidgetAppearance?): AppearancePalette {
            val a = appearance ?: WidgetAppearance()
            val background = a.backgroundColor?.let { ChartColor.parseHex(it) } ?: DEFAULT_BACKGROUND
            val opacity = a.backgroundOpacity?.coerceIn(0f, 1f)
            val alpha = opacity?.let { floor(it * 255f + 0.5f).toInt() } ?: 0xFF
            val text = a.textColor?.let { ChartColor.parseHex(it) }

            return AppearancePalette(
                background = (background and 0x00FFFFFF) or (alpha shl 24),
                text = text ?: DEFAULT_TEXT,
                muted = text?.let { (it and 0x00FFFFFF) or (MUTED_ALPHA shl 24) } ?: DEFAULT_MUTED,
                accent = a.accentColor?.let { ChartColor.parseHex(it) } ?: DEFAULT_ACCENT,
                fontScale = (a.fontScale ?: 1f).coerceIn(MIN_FONT_SCALE, MAX_FONT_SCALE),
                cornerRadiusDp = (a.cornerRadius ?: DEFAULT_CORNER_RADIUS).coerceIn(0f, MAX_CORNER_RADIUS),
            )
        }
    }
}
