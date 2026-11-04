package io.github.sphaerox.influx_sensor_widgets.glance

import io.github.sphaerox.influx_sensor_widgets.model.WidgetDefinition
import io.github.sphaerox.influx_sensor_widgets.model.WidgetType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WidgetUiStateWarningTest {
    private val widget =
        WidgetDefinition(
            id = "w1",
            type = WidgetType.HISTORY_CHART,
            title = "IAQ",
            connectionId = "c",
            measurement = "m",
        )

    private fun map(cache: String) =
        WidgetUiStateMapper.mapToUiState(
            appWidgetId = 1,
            boundWidgetId = "w1",
            widget = widget,
            cacheJson = cache,
        )

    @Test
    fun mapsWarningFromCache() {
        val state =
            map("""{"points":[{"t":1,"v":2.0}],"warning":"1 Zeit-Bucket nicht berechenbar: Division durch Null","timestamp":5}""")
        assertEquals("1 Zeit-Bucket nicht berechenbar: Division durch Null", state.warningMessage)
        assertNull(state.errorMessage)
    }

    @Test
    fun noWarningWhenCacheHasNone() {
        assertNull(map("""{"points":[],"timestamp":5}""").warningMessage)
    }
}
