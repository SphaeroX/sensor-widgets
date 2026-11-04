package io.github.sphaerox.influx_sensor_widgets.worker

import org.json.JSONObject

/**
 * Short network outages (Doze wake-up, Wi-Fi handover, DNS hiccup) must not replace the
 * last good values with an error. The previous data stays in the cache and only after
 * [GRACE_MILLIS] of consecutive network failures is the error written.
 */
object NetworkErrorGrace {
    const val GRACE_MILLIS = 60 * 60_000L

    /** Cache field holding the time of the first network failure of the current streak. */
    const val KEY_FAILURE_SINCE = "networkFailureSince"

    fun cacheAfterNetworkError(
        previousCacheJson: String?,
        errorMessage: String,
        nowMillis: Long,
    ): String {
        val previous =
            previousCacheJson?.let {
                try {
                    JSONObject(it)
                } catch (_: Exception) {
                    null
                }
            }
        val failureSince = previous?.optLong(KEY_FAILURE_SINCE, nowMillis) ?: nowMillis
        val hasData = previous != null && !previous.has("error")

        if (hasData && nowMillis - failureSince < GRACE_MILLIS) {
            return previous!!.put(KEY_FAILURE_SINCE, failureSince).toString()
        }
        return JSONObject()
            .put("error", errorMessage)
            .put("timestamp", nowMillis)
            .put(KEY_FAILURE_SINCE, failureSince)
            .toString()
    }
}

/** At least one widget could not reach its server; WorkManager should retry with backoff. */
class TransientRefreshException : Exception("Network error during widget refresh")
