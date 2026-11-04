package io.github.sphaerox.influx_sensor_widgets.model

/**
 * Optional per-widget look (contract field `appearance`). Unset values keep the
 * platform default. Mirrors the Dart `WidgetAppearance`.
 */
data class WidgetAppearance(
    val backgroundColor: String? = null,
    val backgroundOpacity: Float? = null,
    val textColor: String? = null,
    val accentColor: String? = null,
    val fontScale: Float? = null,
    val cornerRadius: Float? = null,
)
