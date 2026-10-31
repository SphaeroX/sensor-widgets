package io.github.mgasc.influx_sensor_widgets.influx

import io.github.mgasc.influx_sensor_widgets.model.InfluxConnection
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit

class InfluxHttpClient(
    private val okHttpClient: OkHttpClient =
        OkHttpClient
            .Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(15, TimeUnit.SECONDS)
            .build(),
) {
    private fun maskToken(
        message: String,
        token: String,
    ): String =
        if (token.isNotEmpty()) {
            message.replace(token, "***")
        } else {
            message
        }

    @Throws(InfluxException::class)
    fun query(
        connection: InfluxConnection,
        token: String,
        influxQl: String,
    ): JSONObject {
        val baseUrl = connection.url.trimEnd('/')
        val urlBuilder =
            "$baseUrl/query".toHttpUrlOrNull()?.newBuilder()
                ?: throw InfluxNetworkException("Invalid InfluxDB URL: $baseUrl")

        urlBuilder.addQueryParameter("db", connection.database)
        urlBuilder.addQueryParameter("q", influxQl)
        urlBuilder.addQueryParameter("epoch", "ms")

        val url = urlBuilder.build()
        val request =
            Request
                .Builder()
                .url(url)
                .header("Authorization", "Token $token")
                .header("Accept", "application/json")
                .get()
                .build()

        try {
            okHttpClient.newCall(request).execute().use { response ->
                val body = response.body?.string() ?: ""
                val code = response.code

                when (code) {
                    200 -> {
                        return try {
                            JSONObject(body)
                        } catch (e: Exception) {
                            throw InfluxQueryException("Failed to parse JSON response: ${e.message}")
                        }
                    }
                    401, 403 -> {
                        val sanitized = maskToken(body, token)
                        throw InfluxAuthException("Authentication failed (HTTP $code): $sanitized")
                    }
                    404 -> {
                        throw InfluxNotFoundException("InfluxDB resource or database not found (HTTP 404)")
                    }
                    else -> {
                        val sanitized = maskToken(body, token)
                        throw InfluxQueryException("InfluxDB query error (HTTP $code): $sanitized")
                    }
                }
            }
        } catch (e: InfluxException) {
            throw e
        } catch (e: IOException) {
            val sanitized = maskToken(e.message ?: "Unknown IO error", token)
            throw InfluxNetworkException("Network error while connecting to InfluxDB: $sanitized", e)
        } catch (e: Exception) {
            val sanitized = maskToken(e.message ?: "Unknown error", token)
            throw InfluxQueryException("Unexpected error during query: $sanitized")
        }
    }
}
