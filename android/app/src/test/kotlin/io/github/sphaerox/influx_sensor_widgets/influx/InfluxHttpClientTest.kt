package io.github.sphaerox.influx_sensor_widgets.influx

import io.github.sphaerox.influx_sensor_widgets.model.InfluxConnection
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class InfluxHttpClientTest {
    private lateinit var server: MockWebServer
    private lateinit var client: InfluxHttpClient

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
        client = InfluxHttpClient()
    }

    @After
    fun tearDown() {
        server.shutdown()
    }

    @Test
    fun testSuccessfulQuery() {
        server.enqueue(
            MockResponse()
                .setResponseCode(200)
                .setHeader("Content-Type", "application/json")
                .setBody(
                    """{"results":[{"statement_id":0,"series":[{"name":"cpu","columns":["time","val"],"values":[[1730000, 42.0]]}]}]}""",
                ),
        )

        val conn =
            InfluxConnection(
                id = "c1",
                name = "Test",
                url = server.url("/").toString().removeSuffix("/"),
                database = "sensors",
            )

        val json = client.query(conn, "secret-token-xyz", "SELECT val FROM cpu")
        val recorded = server.takeRequest()

        assertEquals("Token secret-token-xyz", recorded.getHeader("Authorization"))
        assertEquals("application/json", recorded.getHeader("Accept"))
        assertTrue(json.has("results"))
    }

    @Test(expected = InfluxAuthException::class)
    fun testAuthFailureThrowsInfluxAuthException() {
        server.enqueue(
            MockResponse()
                .setResponseCode(401)
                .setBody("""{"error":"unauthorized"}"""),
        )

        val conn =
            InfluxConnection(
                id = "c1",
                name = "Test",
                url = server.url("/").toString().removeSuffix("/"),
                database = "sensors",
            )

        client.query(conn, "secret-token-xyz", "SELECT val FROM cpu")
    }

    @Test
    fun testRedactsTokenInErrors() {
        server.enqueue(
            MockResponse()
                .setResponseCode(500)
                .setBody("""{"error":"internal server error with token secret-token-xyz"}"""),
        )

        val conn =
            InfluxConnection(
                id = "c1",
                name = "Test",
                url = server.url("/").toString().removeSuffix("/"),
                database = "sensors",
            )

        try {
            client.query(conn, "secret-token-xyz", "SELECT val FROM cpu")
        } catch (e: Exception) {
            assertFalse(e.message?.contains("secret-token-xyz") == true)
        }
    }
}
