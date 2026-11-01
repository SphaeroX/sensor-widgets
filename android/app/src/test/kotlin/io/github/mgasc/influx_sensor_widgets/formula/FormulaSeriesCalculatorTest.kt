package io.github.mgasc.influx_sensor_widgets.formula

import io.github.mgasc.influx_sensor_widgets.model.FormulaStep
import io.github.mgasc.influx_sensor_widgets.model.FormulaVariable
import io.github.mgasc.influx_sensor_widgets.model.WidgetDefinition
import io.github.mgasc.influx_sensor_widgets.model.WidgetType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class FormulaSeriesCalculatorTest {
    private fun iaq(gapPolicy: String? = null) =
        WidgetDefinition(
            id = "w",
            type = WidgetType.HISTORY_CHART,
            title = "IAQ",
            connectionId = "c",
            measurement = "sen66",
            formula = "min(vocIdx, co2Idx)",
            formulaVariables =
                listOf(
                    FormulaVariable(name = "v", field = "voc"),
                    FormulaVariable(name = "c", field = "co2"),
                ),
            formulaSteps =
                listOf(
                    FormulaStep("vocIdx", "100 - v * 0.6"),
                    FormulaStep("co2Idx", "clamp(100 - (c - 400) / 10, 0, 100)"),
                ),
            gapPolicy = gapPolicy,
        )

    // Same data as fixtures/influx/bucketed_multi_field_response.json
    private val byVariable =
        mapOf(
            "v" to mapOf(2000L to 100.0, 3000L to 50.0, 4000L to 0.0),
            "c" to mapOf(1000L to 800.0, 2000L to 900.0, 4000L to 400.0),
        )

    @Test
    fun skipPolicyDropsIncompleteBuckets() {
        val result = FormulaSeriesCalculator.combine(iaq(), byVariable)
        assertEquals(listOf(40.0, 100.0), result.points.map { it.value })
        assertEquals(listOf(2000L, 4000L), result.points.map { it.timestamp })
        assertTrue(result.errors.isEmpty())
    }

    @Test
    fun previousPolicyCarriesLastValueForward() {
        val result = FormulaSeriesCalculator.combine(iaq("previous"), byVariable)
        assertEquals(listOf(40.0, 50.0, 100.0), result.points.map { it.value })
    }

    private val ratio =
        WidgetDefinition(
            id = "w",
            type = WidgetType.HISTORY_CHART,
            title = "ratio",
            connectionId = "c",
            measurement = "m",
            formula = "a / b",
            formulaVariables =
                listOf(
                    FormulaVariable(name = "a", field = "a"),
                    FormulaVariable(name = "b", field = "b"),
                ),
        )

    @Test
    fun recordsPerBucketErrorsAndKeepsGoodBuckets() {
        val result =
            FormulaSeriesCalculator.combine(
                ratio,
                mapOf(
                    "a" to mapOf(1000L to 10.0, 2000L to 10.0, 3000L to 9.0),
                    "b" to mapOf(1000L to 2.0, 2000L to 0.0, 3000L to 3.0),
                ),
            )
        assertEquals(listOf(5.0, 3.0), result.points.map { it.value })
        assertEquals(1, result.errors.size)
        assertTrue(result.errors.single().exception is DivisionByZeroException)
        assertEquals(2000L, result.errors.single().timestamp)
    }

    @Test
    fun throwsWhenEveryBucketFails() {
        assertThrows(DivisionByZeroException::class.java) {
            FormulaSeriesCalculator.combine(
                ratio,
                mapOf("a" to mapOf(1000L to 10.0), "b" to mapOf(1000L to 0.0)),
            )
        }
    }

    @Test
    fun throwsMissingVariableWhenVariableHasNoData() {
        val e =
            assertThrows(MissingVariableException::class.java) {
                FormulaSeriesCalculator.combine(
                    ratio,
                    mapOf("a" to mapOf(1000L to 10.0), "b" to emptyMap()),
                )
            }
        assertEquals("b", e.variableName)
    }

    @Test
    fun aggregateAppliesFormulaBeforeMinMaxMean() {
        val series = FormulaSeriesCalculator.combine(iaq(), byVariable)
        val agg = FormulaSeriesCalculator.aggregate(series, iaq())
        assertEquals(40.0, agg.getValue("min"), 1e-9)
        assertEquals(100.0, agg.getValue("max"), 1e-9)
        assertEquals(70.0, agg.getValue("mean"), 1e-9)
    }

    @Test
    fun aggregateOfEmptySeriesIsEmpty() {
        assertTrue(
            FormulaSeriesCalculator
                .aggregate(FormulaSeriesCalculator.SeriesResult(emptyList(), emptyList()), iaq())
                .isEmpty(),
        )
    }
}
