package io.github.mgasc.influx_sensor_widgets.worker

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NetworkErrorGraceTest {
    private val goodCache = """{"widgetId":"w1","type":"single_value","value":21.5,"timestamp":1000}"""
    private val error = "Network error while connecting to InfluxDB: Unable to resolve host"

    @Test
    fun keepsLastDataOnFirstNetworkError() {
        val now = 10_000_000L

        val result = JSONObject(NetworkErrorGrace.cacheAfterNetworkError(goodCache, error, now))

        assertFalse(result.has("error"))
        assertEquals(21.5, result.getDouble("value"), 0.001)
        assertEquals(1000L, result.getLong("timestamp"))
        assertEquals(now, result.getLong(NetworkErrorGrace.KEY_FAILURE_SINCE))
    }

    @Test
    fun keepsFirstFailureTimeAcrossRepeatedErrorsWithinGrace() {
        val start = 10_000_000L
        val first = NetworkErrorGrace.cacheAfterNetworkError(goodCache, error, start)

        val second = JSONObject(NetworkErrorGrace.cacheAfterNetworkError(first, error, start + 30 * 60_000L))

        assertFalse(second.has("error"))
        assertEquals(start, second.getLong(NetworkErrorGrace.KEY_FAILURE_SINCE))
    }

    @Test
    fun showsErrorOnceFailuresLastLongerThanGrace() {
        val start = 10_000_000L
        val first = NetworkErrorGrace.cacheAfterNetworkError(goodCache, error, start)

        val late = JSONObject(NetworkErrorGrace.cacheAfterNetworkError(first, error, start + NetworkErrorGrace.GRACE_MILLIS))

        assertEquals(error, late.getString("error"))
        assertEquals(start, late.getLong(NetworkErrorGrace.KEY_FAILURE_SINCE))
    }

    @Test
    fun graceIsOneHour() {
        assertEquals(60 * 60_000L, NetworkErrorGrace.GRACE_MILLIS)
    }

    @Test
    fun showsErrorWhenThereIsNoDataToKeep() {
        val result = JSONObject(NetworkErrorGrace.cacheAfterNetworkError(null, error, 5L))

        assertEquals(error, result.getString("error"))
    }

    @Test
    fun previousNonNetworkErrorIsReplacedByNetworkError() {
        val previous = """{"error":"Keine Messdaten gefunden","timestamp":1}"""

        val result = JSONObject(NetworkErrorGrace.cacheAfterNetworkError(previous, error, 5L))

        assertEquals(error, result.getString("error"))
    }

    @Test
    fun brokenPreviousCacheFallsBackToError() {
        val result = JSONObject(NetworkErrorGrace.cacheAfterNetworkError("{not json", error, 5L))

        assertTrue(result.has("error"))
    }
}
