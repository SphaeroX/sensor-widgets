package io.github.mgasc.influx_sensor_widgets.model

enum class WidgetType(
    val wireName: String,
) {
    SINGLE_VALUE("single_value"),
    HISTORY_CHART("history_chart"),
    INDICATOR_LAMP("indicator_lamp"),
    MULTI_VALUE("multi_value"),
    AGGREGATE("aggregate"),
    GAUGE_BAR("gauge_bar"),
    ;

    companion object {
        fun fromWireName(value: String): WidgetType =
            entries.firstOrNull { it.wireName == value }
                ?: throw IllegalArgumentException("Unknown WidgetType wire name: $value")
    }
}
