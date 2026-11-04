package io.github.sphaerox.influx_sensor_widgets.worker

import io.github.sphaerox.influx_sensor_widgets.glance.WidgetUiStateMapper
import io.github.sphaerox.influx_sensor_widgets.influx.InfluxHttpClient
import io.github.sphaerox.influx_sensor_widgets.l10n.TestTexts
import io.github.sphaerox.influx_sensor_widgets.model.FormulaStep
import io.github.sphaerox.influx_sensor_widgets.model.FormulaVariable
import io.github.sphaerox.influx_sensor_widgets.model.WidgetDefinitionParser
import io.github.sphaerox.influx_sensor_widgets.storage.WidgetStorageReader
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.io.File

class WidgetRefreshWorkerMultiFormulaTest {
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

    private fun enqueueLatest(
        columns: String,
        row: String,
    ) {
        server.enqueue(
            MockResponse()
                .setResponseCode(200)
                .setHeader("Content-Type", "application/json")
                .setBody(
                    """{"results":[{"statement_id":0,"series":[{"name":"room","columns":["time",$columns],"values":[[1730370000000,$row]]}]}]}""",
                ),
        )
    }

    private fun fixture(): String {
        val candidates =
            listOf(
                File("../../fixtures/widget_definitions/widget_definition_multi_formula.json"),
                File("../fixtures/widget_definitions/widget_definition_multi_formula.json"),
                File("fixtures/widget_definitions/widget_definition_multi_formula.json"),
            )
        return candidates.first { it.exists() }.readText()
    }

    @Test
    fun parserReadsItemFormulas() {
        val widget = WidgetDefinitionParser.parseDefinitionsList(fixture()).single()
        val plain = widget.items!![0]
        val formulaItem = widget.items!![1]
        assertEquals(null, plain.formula)
        assertEquals("min(vocIdx, 100)", formulaItem.formula)
        assertEquals(listOf(FormulaVariable(name = "v", field = "voc")), formulaItem.formulaVariables)
        assertEquals(listOf(FormulaStep("vocIdx", "100 - v * 0.6")), formulaItem.formulaSteps)
    }

    @Test
    fun formulaRowIsCalculatedAndPlainRowsStayUnchanged() {
        prefs[WidgetStorageReader.KEY_WIDGET_DEFINITIONS] = fixture().replace("conn-1", "c1")
        enqueueLatest("\"temp\"", "21.5")
        enqueueLatest("\"voc\"", "50.0")

        WidgetRefreshWorker.refreshWidgets(storageReader, InfluxHttpClient(), TestTexts.german)

        val cache = JSONObject(prefs.getValue("${WidgetStorageReader.KEY_CACHE_PREFIX}w-room"))
        val values = cache.getJSONObject("values")
        assertEquals(21.5, values.getJSONObject("temp").getDouble("value"), 1e-9)
        assertEquals(70.0, values.getJSONObject("iaq").getDouble("value"), 1e-9)
        assertFalse(cache.has("valueErrors"))
    }

    @Test
    fun errorInOneRowDoesNotBlockOtherRows() {
        prefs[WidgetStorageReader.KEY_WIDGET_DEFINITIONS] =
            """
            [{"id":"w1","type":"multi_value","title":"Room","connectionId":"c1","measurement":"room",
              "items":[
                {"field":"temp"},
                {"field":"ratio","formula":"1 / z","formulaVariables":[{"name":"z","field":"zero"}]}
              ]}]
            """.trimIndent()
        enqueueLatest("\"temp\"", "21.5")
        enqueueLatest("\"zero\"", "0.0")

        WidgetRefreshWorker.refreshWidgets(storageReader, InfluxHttpClient(), TestTexts.german)

        val cache = JSONObject(prefs.getValue("${WidgetStorageReader.KEY_CACHE_PREFIX}w1"))
        assertEquals(21.5, cache.getJSONObject("values").getJSONObject("temp").getDouble("value"), 1e-9)
        assertFalse(cache.getJSONObject("values").has("ratio"))
        assertEquals("Division durch Null", cache.getJSONObject("valueErrors").getString("ratio"))
        assertFalse(cache.has("error"))
    }

    @Test
    fun mapperShowsRowErrorsAsText() {
        val widget =
            WidgetDefinitionParser
                .parseDefinitionsList(
                    """[{"id":"w1","type":"multi_value","title":"Room","connectionId":"c1","measurement":"room","items":[{"field":"temp"}]}]""",
                ).single()
        val state =
            WidgetUiStateMapper.mapToUiState(
                appWidgetId = 1,
                boundWidgetId = "w1",
                widget = widget,
                cacheJson =
                    """{"values":{"temp":{"value":21.5,"timestamp":1}},"valueErrors":{"ratio":"Division durch Null"},"timestamp":5}""",
                texts = TestTexts.german,
            )
        assertEquals("Fehler: Division durch Null", state.multiValues!!["ratio"])
        assertTrue(state.multiValues!!.containsKey("temp"))
    }
}
