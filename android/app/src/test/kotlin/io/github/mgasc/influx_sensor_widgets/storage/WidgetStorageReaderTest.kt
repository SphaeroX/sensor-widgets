package io.github.mgasc.influx_sensor_widgets.storage

import io.github.mgasc.influx_sensor_widgets.model.WidgetType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test

class WidgetStorageReaderTest {
    private lateinit var storageReader: WidgetStorageReader
    private val inMemoryPrefs = mutableMapOf<String, String>()
    private val inMemorySecurePrefs = mutableMapOf<String, String>()

    @Before
    fun setUp() {
        inMemoryPrefs.clear()
        inMemorySecurePrefs.clear()

        storageReader =
            WidgetStorageReader(
                prefsGetter = { key -> inMemoryPrefs[key] },
                prefsSetter = { key, value -> inMemoryPrefs[key] = value },
                securePrefsGetter = { key -> inMemorySecurePrefs[key] ?: inMemoryPrefs[key] },
            )
    }

    @Test
    fun testGetWidgetDefinitionsEmpty() {
        val list = storageReader.getWidgetDefinitions()
        assertEquals(0, list.size)
    }

    @Test
    fun testGetWidgetDefinitionsAndConnections() {
        val widgetsJson =
            """
            [
              {
                "id": "w1",
                "type": "single_value",
                "title": "Temp",
                "connectionId": "c1",
                "measurement": "climate",
                "field": "temp"
              }
            ]
            """.trimIndent()
        inMemoryPrefs["widget_definitions_v1"] = widgetsJson

        val connsJson =
            """
            [
              {
                "id": "c1",
                "name": "Home Server",
                "url": "http://192.168.1.100:8086",
                "database": "sensors"
              }
            ]
            """.trimIndent()
        inMemoryPrefs["connections_metadata_v1"] = connsJson
        inMemorySecurePrefs["influx_token_c1"] = "my-secret-token"

        val widgets = storageReader.getWidgetDefinitions()
        assertEquals(1, widgets.size)
        assertEquals("w1", widgets[0].id)
        assertEquals(WidgetType.SINGLE_VALUE, widgets[0].type)

        val conns = storageReader.getConnections()
        assertEquals(1, conns.size)
        assertEquals("c1", conns[0].id)
        assertEquals("Home Server", conns[0].name)

        val token = storageReader.getToken("c1")
        assertEquals("my-secret-token", token)
    }

    @Test
    fun testSaveAndGetWidgetCache() {
        storageReader.saveWidgetCache("w1", """{"value": 23.5}""")
        val cached = storageReader.getWidgetCache("w1")
        assertEquals("""{"value": 23.5}""", cached)
        assertNull(storageReader.getWidgetCache("unknown"))
    }
}
