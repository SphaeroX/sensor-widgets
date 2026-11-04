package io.github.sphaerox.influx_sensor_widgets.formula

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Test
import java.io.File

class FormulaEvaluatorTest {
    private fun loadFixturesFile(relativePath: String): String {
        val candidates =
            listOf(
                File("../../fixtures/$relativePath"),
                File("../fixtures/$relativePath"),
                File("fixtures/$relativePath"),
            )
        val file =
            candidates.firstOrNull { it.exists() }
                ?: throw IllegalArgumentException("Fixture file not found: $relativePath")
        return file.readText()
    }

    @Test
    fun testValidCasesFromFixture() {
        val jsonStr = loadFixturesFile("formula/evaluator_cases.json")
        val root = JSONObject(jsonStr)
        val validCases = root.getJSONArray("valid_cases")

        for (i in 0 until validCases.length()) {
            val item = validCases.getJSONObject(i)
            val name = item.getString("name")
            val formula = item.getString("formula")
            val varsObj = item.getJSONObject("variables")
            val expected = item.getDouble("expected")

            val variables = mutableMapOf<String, Double>()
            varsObj.keys().forEach { k ->
                variables[k] = varsObj.getDouble(k)
            }

            val result = FormulaEvaluator.evaluate(formula, variables)
            assertEquals("Failed on case: $name", expected, result, 0.0001)
        }
    }

    @Test
    fun testExtractVariables() {
        val vars = FormulaEvaluator.extractVariables("(A + B * 2) / C - temp_out")
        assertEquals(listOf("A", "B", "C", "temp_out"), vars)
    }

    @Test
    fun testValidateSyntax() {
        assertNull(FormulaEvaluator.validateSyntax("A + B"))
        assertNull(FormulaEvaluator.validateSyntax("(A + B) / 3"))
        assertNotNull(FormulaEvaluator.validateSyntax("A +"))
        assertNotNull(FormulaEvaluator.validateSyntax("(A + B"))
        assertNotNull(FormulaEvaluator.validateSyntax(""))
    }

    @Test
    fun testDivisionByZeroThrows() {
        assertThrows(DivisionByZeroException::class.java) {
            FormulaEvaluator.evaluate("A / B", mapOf("A" to 10.0, "B" to 0.0))
        }
    }

    @Test
    fun testSyntaxErrorThrows() {
        assertThrows(FormulaSyntaxException::class.java) {
            FormulaEvaluator.evaluate("(A + B", mapOf("A" to 1.0, "B" to 2.0))
        }
        assertThrows(FormulaSyntaxException::class.java) {
            FormulaEvaluator.evaluate("A ++ B", mapOf("A" to 1.0, "B" to 2.0))
        }
    }

    @Test
    fun testMissingVariableThrows() {
        assertThrows(MissingVariableException::class.java) {
            FormulaEvaluator.evaluate("A + B", mapOf("A" to 1.0))
        }
    }
}
