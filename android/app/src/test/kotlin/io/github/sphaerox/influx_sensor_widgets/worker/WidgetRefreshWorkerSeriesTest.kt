package io.github.sphaerox.influx_sensor_widgets.worker

import io.github.sphaerox.influx_sensor_widgets.influx.InfluxHttpClient
import io.github.sphaerox.influx_sensor_widgets.storage.WidgetStorageReader
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class WidgetRefreshWorkerSeriesTest {
    private lateinit var server: MockWebServer
    private lateinit var storageReader: WidgetStorageReader
    private val prefs = mutableMapOf<String, String>()

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
        prefs.clear()
        storageReader =
            WidgetStorageReader(
                prefsGetter = { key -> prefs[key] },
                prefsSetter = { key, value -> prefs[key] = value },
                securePrefsGetter = { key -> prefs[key] },
            )
        val url = server.url("/").toString().removeSuffix("/")
        prefs[WidgetStorageReader.KEY_CONNECTIONS_METADATA] =
            """[{"id":"c1","name":"S","url":"$url","database":"db"}]"""
        prefs["${WidgetStorageReader.KEY_TOKEN_PREFIX}c1"] = "tok"
    }

    @After
    fun tearDown() {
        server.shutdown()
    }

    private fun enqueueBuckets(rows: String) {
        server.enqueue(
            MockResponse()
                .setResponseCode(200)
                .setHeader("Content-Type", "application/json")
                .setBody(
                    """{"results":[{"statement_id":0,"series":[{"name":"m","columns":["time","a","b"],"values":$rows}]}]}""",
                ),
        )
    }

    private fun widgetJson(type: String) =
        """
        [{
          "id": "w1", "type": "$type", "title": "ratio", "connectionId": "c1",
          "measurement": "m", "timeRange": "6h",
          "formula": "a / b",
          "formulaVariables": [{"name":"a","field":"a"},{"name":"b","field":"b"}]
        }]
        """.trimIndent()

    private fun cache(): JSONObject = JSONObject(prefs.getValue("${WidgetStorageReader.KEY_CACHE_PREFIX}w1"))

    @Test
    fun historyChartWithFormulaCachesCalculatedSeriesAndWarning() {
        enqueueBuckets("[[1000,10.0,2.0],[2000,10.0,0.0],[3000,9.0,3.0]]")
        prefs[WidgetStorageReader.KEY_WIDGET_DEFINITIONS] = widgetJson("history_chart")

        WidgetRefreshWorker.refreshWidgets(storageReader, InfluxHttpClient())

        val cache = cache()
        val points = cache.getJSONArray("points")
        assertEquals(2, points.length())
        assertEquals(5.0, points.getJSONObject(0).getDouble("v"), 1e-9)
        assertEquals(3.0, points.getJSONObject(1).getDouble("v"), 1e-9)
        assertTrue(cache.getString("warning").contains("Division durch Null"))
        val query = server.takeRequest().requestUrl!!.queryParameter("q")!!
        assertTrue(query.contains("GROUP BY time(") && query.endsWith("fill(null)"))
    }

    @Test
    fun aggregateWithFormulaCachesAggregatesOfCalculatedSeries() {
        enqueueBuckets("[[1000,10.0,2.0],[2000,10.0,0.0],[3000,9.0,3.0]]")
        prefs[WidgetStorageReader.KEY_WIDGET_DEFINITIONS] = widgetJson("aggregate")

        WidgetRefreshWorker.refreshWidgets(storageReader, InfluxHttpClient())

        val agg = cache().getJSONObject("aggregates")
        assertEquals(3.0, agg.getDouble("min"), 1e-9)
        assertEquals(5.0, agg.getDouble("max"), 1e-9)
        assertEquals(4.0, agg.getDouble("mean"), 1e-9)
    }

    @Test
    fun historyChartWithFormulaStoresErrorWhenEveryBucketFails() {
        enqueueBuckets("[[1000,10.0,0.0]]")
        prefs[WidgetStorageReader.KEY_WIDGET_DEFINITIONS] = widgetJson("history_chart")

        WidgetRefreshWorker.refreshWidgets(storageReader, InfluxHttpClient())

        assertTrue(cache().getString("error").contains("Division durch Null"))
    }
}
