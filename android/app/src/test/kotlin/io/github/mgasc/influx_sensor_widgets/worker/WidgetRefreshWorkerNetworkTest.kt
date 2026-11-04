package io.github.mgasc.influx_sensor_widgets.worker

import androidx.work.NetworkType
import io.github.mgasc.influx_sensor_widgets.influx.InfluxHttpClient
import io.github.mgasc.influx_sensor_widgets.storage.WidgetStorageReader
import okhttp3.mockwebserver.MockWebServer
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class WidgetRefreshWorkerNetworkTest {
    private val prefs = mutableMapOf<String, String>()
    private lateinit var storageReader: WidgetStorageReader

    @Before
    fun setUp() {
        prefs.clear()
        storageReader =
            WidgetStorageReader(
                prefsGetter = { key -> prefs[key] },
                prefsSetter = { key, value -> prefs[key] = value },
                securePrefsGetter = { key -> prefs[key] },
            )
        // A server that was started and shut down again: connecting fails with an IOException.
        val server = MockWebServer()
        server.start()
        val deadUrl = server.url("/").toString().removeSuffix("/")
        server.shutdown()

        prefs[WidgetStorageReader.KEY_CONNECTIONS_METADATA] =
            """[{"id":"c1","name":"Server","url":"$deadUrl","database":"sensors"}]"""
        prefs["${WidgetStorageReader.KEY_TOKEN_PREFIX}c1"] = "token123"
        prefs[WidgetStorageReader.KEY_WIDGET_DEFINITIONS] =
            """[{"id":"w1","type":"single_value","title":"Temp","connectionId":"c1","measurement":"climate","field":"temperature"}]"""
    }

    @Test
    fun unreachableServerKeepsLastValuesWithinGrace() {
        storageReader.saveWidgetCache("w1", """{"widgetId":"w1","type":"single_value","value":22.8,"timestamp":1000}""")

        val result = WidgetRefreshWorker.refreshWidgets(storageReader, InfluxHttpClient(), nowMillis = { 50_000L })

        val cache = JSONObject(storageReader.getWidgetCache("w1")!!)
        assertFalse(cache.has("error"))
        assertEquals(22.8, cache.getDouble("value"), 0.001)
        assertEquals(1, result)
    }

    @Test
    fun unreachableServerShowsErrorAfterGrace() {
        storageReader.saveWidgetCache("w1", """{"widgetId":"w1","type":"single_value","value":22.8,"timestamp":1000}""")

        WidgetRefreshWorker.refreshWidgets(storageReader, InfluxHttpClient(), nowMillis = { 50_000L })
        WidgetRefreshWorker.refreshWidgets(
            storageReader,
            InfluxHttpClient(),
            nowMillis = { 50_000L + NetworkErrorGrace.GRACE_MILLIS },
        )

        val cache = JSONObject(storageReader.getWidgetCache("w1")!!)
        assertTrue(cache.getString("error").startsWith("Network error"))
    }

    @Test
    fun refreshWorkWaitsForANetworkConnection() {
        assertEquals(NetworkType.CONNECTED, WidgetRefreshWorker.refreshConstraints().requiredNetworkType)
    }

    @Test
    fun networkFailureIsReportedSoWorkManagerRetries() {
        storageReader.saveWidgetCache("w1", """{"widgetId":"w1","type":"single_value","value":22.8,"timestamp":1000}""")

        var thrown: Exception? = null
        try {
            WidgetRefreshWorker.refreshWidgetsOrThrowOnNetworkFailure(storageReader, InfluxHttpClient())
        } catch (e: Exception) {
            thrown = e
        }

        assertTrue(thrown is TransientRefreshException)
    }
}
