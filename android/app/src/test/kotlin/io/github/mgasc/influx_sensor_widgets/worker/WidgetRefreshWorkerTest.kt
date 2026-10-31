package io.github.mgasc.influx_sensor_widgets.worker

import io.github.mgasc.influx_sensor_widgets.influx.InfluxHttpClient
import io.github.mgasc.influx_sensor_widgets.storage.WidgetStorageReader
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class WidgetRefreshWorkerTest {
    private lateinit var server: MockWebServer
    private lateinit var storageReader: WidgetStorageReader
    private val inMemoryPrefs = mutableMapOf<String, String>()
    private val inMemorySecurePrefs = mutableMapOf<String, String>()

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()

        inMemoryPrefs.clear()
        inMemorySecurePrefs.clear()

        storageReader =
            WidgetStorageReader(
                prefsGetter = { key -> inMemoryPrefs[key] },
                prefsSetter = { key, value -> inMemoryPrefs[key] = value },
                securePrefsGetter = { key -> inMemorySecurePrefs[key] ?: inMemoryPrefs[key] },
            )
    }

    @After
    fun tearDown() {
        server.shutdown()
    }

    @Test
    fun testRefreshSingleValueWidget() {
        server.enqueue(
            MockResponse()
                .setResponseCode(200)
                .setHeader("Content-Type", "application/json")
                .setBody(
                    """
                    {
                      "results": [
                        {
                          "statement_id": 0,
                          "series": [
                            {
                              "name": "climate",
                              "columns": ["time", "temperature"],
                              "values": [[1730370000000, 22.8]]
                            }
                          ]
                        }
                      ]
                    }
                    """.trimIndent(),
                ),
        )

        val serverUrl = server.url("/").toString().removeSuffix("/")
        inMemoryPrefs[WidgetStorageReader.KEY_CONNECTIONS_METADATA] =
            """
            [
              {
                "id": "c1",
                "name": "Server",
                "url": "$serverUrl",
                "database": "sensors"
              }
            ]
            """.trimIndent()
        inMemorySecurePrefs["${WidgetStorageReader.KEY_TOKEN_PREFIX}c1"] = "token123"

        inMemoryPrefs[WidgetStorageReader.KEY_WIDGET_DEFINITIONS] =
            """
            [
              {
                "id": "w1",
                "type": "single_value",
                "title": "Temp",
                "connectionId": "c1",
                "measurement": "climate",
                "field": "temperature",
                "unit": "°C",
                "decimalPlaces": 1
              }
            ]
            """.trimIndent()

        val httpClient = InfluxHttpClient()
        val count = WidgetRefreshWorker.refreshWidgets(storageReader, httpClient)

        assertEquals(1, count)
        val cache = storageReader.getWidgetCache("w1")
        assertNotNull(cache)

        val cacheJson = JSONObject(cache!!)
        assertEquals(22.8, cacheJson.getDouble("value"), 0.001)
        assertEquals("°C", cacheJson.getString("unit"))
        assertEquals(1730370000000L, cacheJson.getLong("timestamp"))
    }

    @Test
    fun testRefreshHandlesConnectionNotFoundGracefully() {
        inMemoryPrefs[WidgetStorageReader.KEY_CONNECTIONS_METADATA] = "[]"
        inMemoryPrefs[WidgetStorageReader.KEY_WIDGET_DEFINITIONS] =
            """
            [
              {
                "id": "w-broken",
                "type": "single_value",
                "title": "Broken",
                "connectionId": "c-missing",
                "measurement": "m",
                "field": "f"
              }
            ]
            """.trimIndent()

        val httpClient = InfluxHttpClient()
        val count = WidgetRefreshWorker.refreshWidgets(storageReader, httpClient)

        assertEquals(1, count)
        val cache = storageReader.getWidgetCache("w-broken")
        assertNotNull(cache)
        assertTrue(cache!!.contains("error"))
    }
}
