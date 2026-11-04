package io.github.sphaerox.influx_sensor_widgets.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.io.File

class WidgetDefinitionStepsParserTest {
    private fun loadFixturesFile(relativePath: String): String {
        val candidates =
            listOf(
                File("../../fixtures/$relativePath"),
                File("../fixtures/$relativePath"),
                File("fixtures/$relativePath"),
            )
        return (
            candidates.firstOrNull { it.exists() }
                ?: throw IllegalArgumentException("Fixture file not found: $relativePath")
        ).readText()
    }

    @Test
    fun parsesFormulaStepsFromFixture() {
        val widgets =
            WidgetDefinitionParser.parseDefinitionsList(
                loadFixturesFile("widget_definitions/widget_definition_formula_steps.json"),
            )
        val steps = widgets.single().formulaSteps!!
        assertEquals(2, steps.size)
        assertEquals(FormulaStep("voc", "100 - v * 0.6", "VOC-Index"), steps[0])
        assertEquals(FormulaStep("co2", "clamp(100 - (c - 400) / 10, 0, 100)", null), steps[1])
    }

    @Test
    fun oldDefinitionsHaveNoSteps() {
        val widgets =
            WidgetDefinitionParser.parseDefinitionsList(
                loadFixturesFile("widget_definitions/widget_definitions_v1.json"),
            )
        widgets.forEach { assertNull(it.formulaSteps) }
    }
}
