package io.github.sphaerox.influx_sensor_widgets.l10n

import io.github.sphaerox.influx_sensor_widgets.R
import io.github.sphaerox.influx_sensor_widgets.alerts.AlertHit
import io.github.sphaerox.influx_sensor_widgets.alerts.AlertMessage
import io.github.sphaerox.influx_sensor_widgets.formula.FormulaErrorKind
import io.github.sphaerox.influx_sensor_widgets.formula.FormulaEvaluator
import io.github.sphaerox.influx_sensor_widgets.formula.FormulaException
import io.github.sphaerox.influx_sensor_widgets.formula.FormulaSyntaxException
import io.github.sphaerox.influx_sensor_widgets.model.AlertRule
import io.github.sphaerox.influx_sensor_widgets.model.ThresholdOperator
import io.github.sphaerox.influx_sensor_widgets.model.WidgetDefinitionParser
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetTextsTest {
    private fun caught(run: () -> Unit): FormulaException =
        try {
            run()
            throw AssertionError("no FormulaException")
        } catch (e: FormulaException) {
            e
        }

    @Test
    fun germanFileTranslatesEveryText() {
        val english = TestTexts.englishStrings.keys - "app_name"
        val german = TestTexts.strings("values-de").keys
        assertEquals("missing in values-de", emptySet<String>(), english - german)
        assertEquals("unknown in values-de", emptySet<String>(), german - english)
    }

    @Test
    fun formulaErrorsInBothLanguages() {
        val e = caught { FormulaEvaluator.evaluate("1 / 0", emptyMap()) }
        assertEquals("Division by zero", TestTexts.english.formulaError(e))
        assertEquals("Division durch Null", TestTexts.german.formulaError(e))
        assertEquals("Division by zero", e.message)
    }

    @Test
    fun wrongArgumentCountSpellsArityPerLanguage() {
        val e = FormulaEvaluator.syntaxError("min()")!!
        assertTrue(TestTexts.english.formulaError(e).contains("at least 1"))
        assertTrue(TestTexts.german.formulaError(e).contains("mindestens 1"))
    }

    @Test
    fun everyErrorKindHasAText() {
        for (texts in listOf(TestTexts.english, TestTexts.german)) {
            for (kind in FormulaErrorKind.entries) {
                val text = texts.formulaError(FormulaSyntaxException(kind, listOf("x", "1", "2", "3")))
                assertTrue("$kind", text.isNotBlank())
            }
        }
    }

    @Test
    fun alertBodyIsEnglish() {
        val widget =
            WidgetDefinitionParser
                .parseDefinitionsList(
                    """[{"id":"w","type":"aggregate","title":"Room","connectionId":"c","measurement":"m","field":"t","unit":"°C"}]""",
                ).single()
        val hit = AlertHit(AlertRule("max", ThresholdOperator.GREATER_THAN, 30.0), 31.0)
        assertEquals("Maximum: 31.0 °C (above 30.0 °C)", AlertMessage.body(widget, hit, TestTexts.english))
    }

    @Test
    fun bucketSummaryUsesCount() {
        assertEquals(
            "3 time buckets could not be calculated: x",
            TestTexts.english.get(R.string.formula_bucket_errors, 3, "x"),
        )
    }
}
