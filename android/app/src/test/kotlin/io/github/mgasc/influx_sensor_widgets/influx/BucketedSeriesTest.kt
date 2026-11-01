package io.github.mgasc.influx_sensor_widgets.influx

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class BucketedSeriesTest {
    private fun loadFixture(name: String): JSONObject {
        val candidates =
            listOf(
                File("../../fixtures/influx/$name"),
                File("../fixtures/influx/$name"),
                File("fixtures/influx/$name"),
            )
        return JSONObject(
            (
                candidates.firstOrNull { it.exists() }
                    ?: throw IllegalArgumentException("Fixture not found: $name")
            ).readText(),
        )
    }

    @Test
    fun builderCreatesBucketedMultiFieldQuery() {
        val q =
            InfluxQlBuilder.buildBucketedMultiFieldQuery(
                measurement = "sen66",
                fields = listOf("voc", "co2"),
                timeRange = "24h",
                bucketInterval = "1h",
            )
        assertEquals(
            "SELECT MEAN(\"voc\") AS \"voc\", MEAN(\"co2\") AS \"co2\" FROM \"sen66\" " +
                "WHERE time > now() - 24h GROUP BY time(1h) fill(null)",
            q,
        )
    }

    @Test
    fun builderAddsSortedTagFilters() {
        val q =
            InfluxQlBuilder.buildBucketedMultiFieldQuery(
                measurement = "m",
                fields = listOf("a"),
                timeRange = "6h",
                bucketInterval = "10m",
                tagFilters = mapOf("room" to "kitchen", "floor" to "1"),
            )
        assertEquals(
            "SELECT MEAN(\"a\") AS \"a\" FROM \"m\" WHERE time > now() - 6h AND " +
                "\"floor\" = '1' AND \"room\" = 'kitchen' GROUP BY time(10m) fill(null)",
            q,
        )
    }

    @Test
    fun parserMapsFieldsToNonNullBuckets() {
        val result =
            InfluxResponseParser.parseBucketedFields(
                loadFixture("bucketed_multi_field_response.json"),
                listOf("voc", "co2"),
            )
        assertEquals(mapOf(2000L to 100.0, 3000L to 50.0, 4000L to 0.0), result["voc"])
        assertEquals(mapOf(1000L to 800.0, 2000L to 900.0, 4000L to 400.0), result["co2"])
    }

    @Test
    fun parserReturnsEmptyMapsForEmptyResult() {
        val result =
            InfluxResponseParser.parseBucketedFields(
                JSONObject("""{"results":[{"statement_id":0}]}"""),
                listOf("voc"),
            )
        assertTrue(result.getValue("voc").isEmpty())
    }

    @Test
    fun durationUtilsParsesAndCoarsens() {
        assertEquals(1800L, DurationUtils.parseSeconds("30m"))
        assertEquals(604800L, DurationUtils.parseSeconds("1w"))
        assertEquals(null, DurationUtils.parseSeconds("abc"))
        assertEquals("1h", DurationUtils.effectiveBucketInterval("24h", "1h"))
        assertEquals("1h", DurationUtils.effectiveBucketInterval("garbage", null))
        val coarse = DurationUtils.effectiveBucketInterval("7d", "1m")
        assertTrue(604800.0 / DurationUtils.parseSeconds(coarse)!! <= 300)
        val derived = DurationUtils.effectiveBucketInterval("24h", null)
        val buckets = 86400.0 / DurationUtils.parseSeconds(derived)!!
        assertTrue(buckets <= 60 && buckets > 5)
    }
}
