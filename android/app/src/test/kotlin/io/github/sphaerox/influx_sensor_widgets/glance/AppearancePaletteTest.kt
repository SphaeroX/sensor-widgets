package io.github.sphaerox.influx_sensor_widgets.glance

import io.github.sphaerox.influx_sensor_widgets.model.WidgetAppearance
import io.github.sphaerox.influx_sensor_widgets.model.WidgetDefinitionParser
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.io.File

class AppearancePaletteTest {
    private fun fixtureText(relative: String): String {
        val candidates =
            listOf(
                File("../../fixtures/$relative"),
                File("../fixtures/$relative"),
                File("fixtures/$relative"),
            )
        return candidates.first { it.exists() }.readText()
    }

    @Test
    fun parserReadsAppearanceFromSharedFixture() {
        val widgets =
            WidgetDefinitionParser.parseDefinitionsList(fixtureText("widget_definitions/widget_definition_appearance.json"))
        val a = widgets[0].appearance!!
        assertEquals("#102030", a.backgroundColor)
        assertEquals(0.5f, a.backgroundOpacity!!, 0f)
        assertEquals("#FFEEAA", a.textColor)
        assertEquals("#33CC99", a.accentColor)
        assertEquals(1.2f, a.fontScale!!, 0f)
        assertEquals(24f, a.cornerRadius!!, 0f)

        assertNull(widgets[1].appearance)
        assertEquals("#FF5722", widgets[2].appearance!!.accentColor)
        assertNull(widgets[2].appearance!!.backgroundColor)
    }

    @Test
    fun widgetsWithoutAppearanceKeepTheOriginalLook() {
        val p = AppearancePalette.resolve(null)
        assertEquals(0xFF1E1E2E.toInt(), p.background)
        assertEquals(0xFFFFFFFF.toInt(), p.text)
        assertEquals(0xFFA6ADC8.toInt(), p.muted)
        assertEquals(0xFF89B4FA.toInt(), p.accent)
        assertEquals(1.0f, p.fontScale, 0f)
        assertEquals(16f, p.cornerRadiusDp, 0f)
        assertEquals(p, AppearancePalette.resolve(WidgetAppearance()))
    }

    @Test
    fun customValuesAreApplied() {
        val p =
            AppearancePalette.resolve(
                WidgetAppearance(
                    backgroundColor = "#102030",
                    backgroundOpacity = 0.5f,
                    textColor = "#FFEEAA",
                    accentColor = "#33CC99",
                    fontScale = 1.2f,
                    cornerRadius = 24f,
                ),
            )
        // 50 % opacity -> alpha 0x80 (127.5 rounded half up).
        assertEquals(0x80102030.toInt(), p.background)
        assertEquals(0xFFFFEEAA.toInt(), p.text)
        // Muted text is the text color at alpha 0xB3 when a custom text color is set.
        assertEquals(0xB3FFEEAA.toInt(), p.muted)
        assertEquals(0xFF33CC99.toInt(), p.accent)
        assertEquals(1.2f, p.fontScale, 0f)
        assertEquals(24f, p.cornerRadiusDp, 0f)
    }

    @Test
    fun opacityWithoutBackgroundColorKeepsTheDefaultColor() {
        val p = AppearancePalette.resolve(WidgetAppearance(backgroundOpacity = 0.0f))
        assertEquals(0x001E1E2E, p.background)
    }

    @Test
    fun invalidAndOutOfRangeValuesFallBackOrClamp() {
        val invalid =
            AppearancePalette.resolve(
                WidgetAppearance(backgroundColor = "nope", textColor = "x", accentColor = "#12"),
            )
        assertEquals(AppearancePalette.resolve(null), invalid)

        val clamped =
            AppearancePalette.resolve(
                WidgetAppearance(backgroundOpacity = 5f, fontScale = 9f, cornerRadius = 500f),
            )
        assertEquals(0xFF1E1E2E.toInt(), clamped.background)
        assertEquals(1.4f, clamped.fontScale, 0f)
        assertEquals(32f, clamped.cornerRadiusDp, 0f)

        val low = AppearancePalette.resolve(WidgetAppearance(fontScale = 0.1f, cornerRadius = -3f))
        assertEquals(0.8f, low.fontScale, 0f)
        assertEquals(0f, low.cornerRadiusDp, 0f)
    }

    @Test
    fun uiStateCarriesTheAppearance() {
        val widget =
            WidgetDefinitionParser
                .parseDefinitionsList(fixtureText("widget_definitions/widget_definition_appearance.json"))
                .first()
        val state =
            WidgetUiStateMapper.mapToUiState(
                appWidgetId = 1,
                boundWidgetId = widget.id,
                widget = widget,
                cacheJson = """{"value":21.5,"timestamp":5}""",
            )
        assertEquals(widget.appearance, state.appearance)
    }
}
