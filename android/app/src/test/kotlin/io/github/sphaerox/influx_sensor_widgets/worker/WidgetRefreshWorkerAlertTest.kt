package io.github.sphaerox.influx_sensor_widgets.worker

import io.github.sphaerox.influx_sensor_widgets.alerts.AlertHit
import io.github.sphaerox.influx_sensor_widgets.influx.InfluxHttpClient
import io.github.sphaerox.influx_sensor_widgets.model.WidgetDefinition
import io.github.sphaerox.influx_sensor_widgets.storage.WidgetStorageReader
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

class WidgetRefreshWorkerAlertTest {
    private lateinit var server: MockWebServer
    private lateinit var storageReader: WidgetStorageReader
    private val prefs = mutableMapOf<String, String>()
    private val hits = mutableListOf<Pair<String, AlertHit>>()

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
        prefs.clear()
        hits.clear()
        storageReader =
            WidgetStorageReader(
                prefsGetter = { key -> prefs[key] },
                prefsSetter = { key, value -> prefs[key] = value },
                securePrefsGetter = { key -> prefs[key] },
            )
        val url = server.url("/").toString().removeSuffix("/")
        prefs[WidgetStorageReader.KEY_CONNECTIONS_METADATA] =
            """[{"id":"c1","name":"Server","url":"$url","database":"sensors"}]"""
        prefs["${WidgetStorageReader.KEY_TOKEN_PREFIX}c1"] = "token123"
        prefs[WidgetStorageReader.KEY_WIDGET_DEFINITIONS] =
            """
            [{"id":"w1","type":"single_value","title":"CO2","connectionId":"c1","measurement":"air","field":"co2",
              "alerts":[{"target":"value","operator":"greaterThan","value":1000}]}]
            """.trimIndent()
    }

    @After
    fun tearDown() {
        server.shutdown()
    }

    private fun refreshWith(value: Double) {
        server.enqueue(
            MockResponse().setResponseCode(200).setBody(
                """{"results":[{"statement_id":0,"series":[{"name":"air","columns":["time","co2"],"values":[[1730370000000,$value]]}]}]}""",
            ),
        )
        WidgetRefreshWorker.refreshWidgets(
            storageReader,
            InfluxHttpClient(),
            onAlert = { widget: WidgetDefinition, hit: AlertHit -> hits += widget.id to hit },
        )
    }

    @Test
    fun notifiesOncePerCrossing() {
        refreshWith(900.0)
        refreshWith(1200.0)
        refreshWith(1300.0)

        assertEquals(1, hits.size)
        assertEquals("w1", hits[0].first)
        assertEquals(1200.0, hits[0].second.actualValue, 0.001)
    }

    @Test
    fun notifiesAgainAfterTheValueFellBack() {
        refreshWith(1200.0)
        refreshWith(800.0)
        refreshWith(1100.0)

        assertEquals(listOf(1200.0, 1100.0), hits.map { it.second.actualValue })
    }

    @Test
    fun alertStateIsStoredPerWidget() {
        refreshWith(1200.0)

        assertEquals(true, prefs["${WidgetStorageReader.KEY_ALERT_STATE_PREFIX}w1"]?.contains("greaterThan"))
    }
}
