package io.github.mgasc.influx_sensor_widgets.influx

import org.junit.Assert.assertEquals
import org.junit.Test

class InfluxQlBuilderTest {
    private val builder = InfluxQlBuilder

    @Test
    fun testBuildSingleValueQueryWithoutTagFilters() {
        val query =
            builder.buildSingleValueQuery(
                measurement = "temperature",
                field = "value",
            )
        assertEquals(
            "SELECT \"value\" FROM \"temperature\" ORDER BY time DESC LIMIT 1",
            query,
        )
    }

    @Test
    fun testBuildSingleValueQueryWithTagFiltersAndEscaping() {
        val query =
            builder.buildSingleValueQuery(
                measurement = "temp\"erature",
                field = "val\"ue",
                tagFilters = mapOf("ro'om" to "living'room", "device" to "sensor1"),
            )
        assertEquals(
            "SELECT \"val\\\"ue\" FROM \"temp\\\"erature\" WHERE \"device\" = 'sensor1' AND \"ro'om\" = 'living\\'room' ORDER BY time DESC LIMIT 1",
            query,
        )
    }

    @Test
    fun testBuildHistoryQueryWithGroupByAndTimeRange() {
        val query =
            builder.buildHistoryQuery(
                measurement = "temperature",
                field = "value",
                timeRange = "24h",
                bucketInterval = "1h",
                tagFilters = mapOf("room" to "living_room"),
            )
        assertEquals(
            "SELECT MEAN(\"value\") AS \"mean\" FROM \"temperature\" WHERE time > now() - 24h AND \"room\" = 'living_room' GROUP BY time(1h) fill(none)",
            query,
        )
    }

    @Test
    fun testBuildAggregateQueryWithMinMaxMean() {
        val query =
            builder.buildAggregateQuery(
                measurement = "power",
                field = "watts",
                timeRange = "24h",
                tagFilters = mapOf("device" to "main_grid"),
            )
        assertEquals(
            "SELECT MIN(\"watts\") AS \"min\", MAX(\"watts\") AS \"max\", MEAN(\"watts\") AS \"mean\" FROM \"power\" WHERE time > now() - 24h AND \"device\" = 'main_grid'",
            query,
        )
    }

    @Test
    fun testBuildMultiValueQuery() {
        val query =
            builder.buildMultiValueQuery(
                measurement = "climate",
                fields = listOf("temperature", "humidity", "co2"),
                tagFilters = mapOf("room" to "office"),
            )
        assertEquals(
            "SELECT \"temperature\", \"humidity\", \"co2\" FROM \"climate\" WHERE \"room\" = 'office' ORDER BY time DESC LIMIT 1",
            query,
        )
    }

    @Test
    fun testBuildSchemaDiscoveryQueries() {
        assertEquals("SHOW MEASUREMENTS", builder.buildShowMeasurementsQuery())
        assertEquals("SHOW FIELD KEYS FROM \"climate\"", builder.buildShowFieldKeysQuery("climate"))
        assertEquals("SHOW TAG KEYS FROM \"climate\"", builder.buildShowTagKeysQuery("climate"))
        assertEquals(
            "SHOW TAG VALUES FROM \"climate\" WITH KEY = \"room\"",
            builder.buildShowTagValuesQuery("climate", "room"),
        )
    }
}
