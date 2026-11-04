package io.github.mgasc.influx_sensor_widgets.alerts

import io.github.mgasc.influx_sensor_widgets.model.AlertRule
import io.github.mgasc.influx_sensor_widgets.model.ThresholdOperator
import io.github.mgasc.influx_sensor_widgets.model.WidgetDefinitionParser
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.io.File

class AlertEvaluatorTest {
    private fun fixtureText(relative: String): String {
        val file =
            listOf(
                File("../../fixtures/$relative"),
                File("../fixtures/$relative"),
                File("fixtures/$relative"),
            ).first { it.exists() }
        return file.readText()
    }

    private fun rules(array: JSONArray): List<AlertRule> =
        (0 until array.length()).map {
            val o = array.getJSONObject(it)
            AlertRule(o.getString("target"), ThresholdOperator.fromWireName(o.getString("operator")), o.getDouble("value"))
        }

    private fun indices(array: JSONArray): List<Int> = (0 until array.length()).map { array.getInt(it) }

    @Test
    fun sharedEvaluationCases() {
        val cases = JSONObject(fixtureText("alerts/evaluation_cases.json")).getJSONArray("cases")
        for (i in 0 until cases.length()) {
            val c = cases.getJSONObject(i)
            val name = c.getString("name")
            val alerts = rules(c.getJSONArray("alerts"))

            val result =
                AlertEvaluator.evaluate(
                    rules = alerts,
                    cacheJson = c.getJSONObject("cache").toString(),
                    previouslyActive = rules(c.getJSONArray("previouslyActive")),
                )

            assertEquals(name, indices(c.getJSONArray("expectTriggered")).map { alerts[it] }, result.triggered.map { it.rule })
            assertEquals(name, indices(c.getJSONArray("expectActive")).map { alerts[it] }, result.active)
        }
    }

    @Test
    fun triggeredHitCarriesTheActualValue() {
        val rule = AlertRule("value", ThresholdOperator.GREATER_THAN, 150.0)

        val result = AlertEvaluator.evaluate(listOf(rule), """{"value":163.5}""", emptyList())

        assertEquals(163.5, result.triggered.single().actualValue, 0.001)
    }

    @Test
    fun stateRoundTripsThroughJson() {
        val active =
            listOf(
                AlertRule("co2", ThresholdOperator.GREATER_THAN, 1000.0),
                AlertRule("temp", ThresholdOperator.LESS_THAN, 18.5),
            )

        assertEquals(active, AlertEvaluator.decodeState(AlertEvaluator.encodeState(active)))
    }

    @Test
    fun missingOrBrokenStateIsEmpty() {
        assertEquals(emptyList<AlertRule>(), AlertEvaluator.decodeState(null))
        assertEquals(emptyList<AlertRule>(), AlertEvaluator.decodeState("{broken"))
    }

    @Test
    fun parserReadsAlertsFromSharedFixture() {
        val widgets =
            WidgetDefinitionParser.parseDefinitionsList(fixtureText("widget_definitions/widget_definition_alerts.json"))

        assertEquals(listOf(AlertRule("value", ThresholdOperator.GREATER_THAN, 150.0)), widgets[0].alerts)
        assertEquals(
            listOf(
                AlertRule("co2", ThresholdOperator.GREATER_THAN, 1000.0),
                AlertRule("temp", ThresholdOperator.LESS_THAN, 18.5),
            ),
            widgets[1].alerts,
        )
        assertNull(widgets[2].alerts)
    }
}
