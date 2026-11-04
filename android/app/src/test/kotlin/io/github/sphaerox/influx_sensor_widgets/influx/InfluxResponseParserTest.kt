package io.github.sphaerox.influx_sensor_widgets.influx

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class InfluxResponseParserTest {
    private val parser = InfluxResponseParser

    private fun loadFixture(filename: String): JSONObject {
        val candidates =
            listOf(
                File("../../fixtures/influx/$filename"),
                File("../fixtures/influx/$filename"),
                File("fixtures/influx/$filename"),
            )
        val file =
            candidates.firstOrNull { it.exists() }
                ?: throw IllegalArgumentException("Fixture not found: $filename")
        return JSONObject(file.readText())
    }

    @Test
    fun testParseSingleValueResponse() {
        val json = loadFixture("single_value_response.json")
        val point = parser.parseSingleValue(json, "value")

        assertNotNull(point)
        assertEquals(21.5, point!!.value, 0.001)
        assertEquals("value", point.field)
        assertEquals(1730370000000L, point.timestamp)
    }

    @Test
    fun testParseHistorySeriesResponse() {
        val json = loadFixture("history_series_response.json")
        val series = parser.parseTimeSeries(json, "mean")

        assertEquals(6, series.size)
        assertEquals(19.8, series.first().value, 0.001)
        assertEquals(1730352000000L, series.first().timestamp)
        assertEquals(21.5, series.last().value, 0.001)
        assertEquals(1730370000000L, series.last().timestamp)
    }

    @Test
    fun testParseMultiSeriesRoomResponse() {
        val json = loadFixture("multi_series_room_response.json")
        val map = parser.parseMultiValues(json, listOf("temperature", "humidity", "co2"))

        assertEquals(3, map.size)
        assertEquals(22.3, map["temperature"]?.value ?: 0.0, 0.001)
        assertEquals(48.5, map["humidity"]?.value ?: 0.0, 0.001)
        assertEquals(620.0, map["co2"]?.value ?: 0.0, 0.001)
    }

    @Test
    fun testParseAggregateMinMaxMeanResponse() {
        val json = loadFixture("aggregate_min_max_mean_response.json")
        val agg = parser.parseAggregate(json)

        assertEquals(18.2, agg["min"] ?: 0.0, 0.001)
        assertEquals(23.9, agg["max"] ?: 0.0, 0.001)
        assertEquals(21.1, agg["mean"] ?: 0.0, 0.001)
    }

    @Test
    fun testParseSchemaDiscoveryFixtures() {
        val measurements = parser.parseMeasurements(loadFixture("show_measurements_response.json"))
        assertEquals(listOf("climate", "power", "temperature"), measurements)

        val fieldKeys = parser.parseFieldKeys(loadFixture("show_field_keys_response.json"))
        assertEquals(listOf("co2", "humidity", "pressure", "temperature"), fieldKeys)

        val tagKeys = parser.parseTagKeys(loadFixture("show_tag_keys_response.json"))
        assertEquals(listOf("building", "device", "room"), tagKeys)

        val tagValues = parser.parseTagValues(loadFixture("show_tag_values_response.json"))
        assertEquals(listOf("bedroom", "kitchen", "living_room", "office"), tagValues)
    }

    @Test
    fun testParseEmptyResultResponseSafely() {
        val json = loadFixture("empty_result_response.json")
        assertNull(parser.parseSingleValue(json, "value"))
        assertTrue(parser.parseTimeSeries(json, "mean").isEmpty())
        assertTrue(parser.parseMultiValues(json, listOf("temp")).isEmpty())
        assertTrue(parser.parseAggregate(json).isEmpty())
        assertTrue(parser.parseMeasurements(json).isEmpty())
    }

    @Test(expected = InfluxQueryException::class)
    fun testThrowsInfluxQueryExceptionOnErrorResponse() {
        val json = loadFixture("error_query_response.json")
        parser.parseSingleValue(json, "value")
    }
}
