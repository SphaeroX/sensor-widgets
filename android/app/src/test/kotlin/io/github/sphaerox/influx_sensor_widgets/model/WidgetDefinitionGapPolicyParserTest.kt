package io.github.sphaerox.influx_sensor_widgets.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WidgetDefinitionGapPolicyParserTest {
    private fun parse(extra: String) =
        WidgetDefinitionParser
            .parseDefinitionsList(
                """[{"id":"w","type":"history_chart","title":"t","connectionId":"c","measurement":"m"$extra}]""",
            ).single()

    @Test
    fun parsesGapPolicy() {
        assertEquals("previous", parse(""","gapPolicy":"previous"""").gapPolicy)
    }

    @Test
    fun gapPolicyDefaultsToNull() {
        assertNull(parse("").gapPolicy)
    }
}
