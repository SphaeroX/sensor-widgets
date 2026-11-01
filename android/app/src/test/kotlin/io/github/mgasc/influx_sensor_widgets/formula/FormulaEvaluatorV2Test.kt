package io.github.mgasc.influx_sensor_widgets.formula

import io.github.mgasc.influx_sensor_widgets.model.FormulaStep
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import java.io.File

class FormulaEvaluatorV2Test {
    private fun loadFixture(): JSONObject {
        val candidates =
            listOf(
                File("../../fixtures/formula/evaluator_cases.json"),
                File("../fixtures/formula/evaluator_cases.json"),
                File("fixtures/formula/evaluator_cases.json"),
            )
        val file =
            candidates.firstOrNull { it.exists() }
                ?: throw IllegalArgumentException("Fixture file not found")
        return JSONObject(file.readText())
    }

    private fun variablesOf(item: JSONObject): Map<String, Double> {
        val obj = item.getJSONObject("variables")
        val map = mutableMapOf<String, Double>()
        obj.keys().forEach { map[it] = obj.getDouble(it) }
        return map
    }

    private fun stepsOf(item: JSONObject): List<FormulaStep> {
        val arr: JSONArray = item.optJSONArray("steps") ?: return emptyList()
        return (0 until arr.length()).map {
            val s = arr.getJSONObject(it)
            FormulaStep(s.getString("name"), s.getString("expression"))
        }
    }

    @Test
    fun testV2ValidCasesFromFixture() {
        val cases = loadFixture().getJSONArray("v2_valid_cases")
        assertTrue(cases.length() > 0)
        for (i in 0 until cases.length()) {
            val item = cases.getJSONObject(i)
            val result =
                FormulaEvaluator.evaluate(
                    item.getString("formula"),
                    variablesOf(item),
                    stepsOf(item),
                )
            assertEquals(
                "Failed on case: ${item.getString("name")}",
                item.getDouble("expected"),
                result,
                1e-9,
            )
        }
    }

    @Test
    fun testV2ErrorCasesFromFixture() {
        val cases = loadFixture().getJSONArray("v2_error_cases")
        assertTrue(cases.length() > 0)
        for (i in 0 until cases.length()) {
            val item = cases.getJSONObject(i)
            val name = item.getString("name")
            try {
                FormulaEvaluator.evaluate(
                    item.getString("formula"),
                    variablesOf(item),
                    stepsOf(item),
                )
                fail("Expected ${item.getString("expected_error")} for case $name")
            } catch (e: FormulaException) {
                assertEquals("Wrong error on case $name (${e.message})", item.getString("expected_error"), e.code)
            }
        }
    }

    @Test
    fun testExtractVariablesIgnoresFunctionsAndConstants() {
        assertEquals(
            listOf("a", "b", "c"),
            FormulaEvaluator.extractVariables("min(a, pi * b) + e + max(a, c)"),
        )
    }

    @Test
    fun testValidateSyntaxReportsPosition() {
        val msg = FormulaEvaluator.validateSyntax("A + * B")
        assertNotNull(msg)
        assertTrue(msg!!.contains("Position 5"))
        assertNull(FormulaEvaluator.validateSyntax("if(A > 1, min(A, 2), 0)"))
        assertNotNull(FormulaEvaluator.validateSyntax("foo(A)"))
        assertNotNull(FormulaEvaluator.validateSyntax("sqrt(A, B)"))
    }

    @Test
    fun testValidateSteps() {
        assertNotNull(
            FormulaEvaluator.validateSteps(
                listOf(FormulaStep("s1", "s2 + 1"), FormulaStep("s2", "a")),
                "a",
                listOf("a"),
            ),
        )
        assertNull(
            FormulaEvaluator.validateSteps(listOf(FormulaStep("s1", "a * 2")), "s1", listOf("a")),
        )
    }
}
