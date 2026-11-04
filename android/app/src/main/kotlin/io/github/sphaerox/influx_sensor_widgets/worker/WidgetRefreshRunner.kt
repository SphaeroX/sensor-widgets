package io.github.sphaerox.influx_sensor_widgets.worker

import kotlin.coroutines.cancellation.CancellationException

/**
 * Runs a data refresh and always tells the placed widgets afterwards, so freshly
 * cached data (or a cached error) is shown instead of the state from the last render.
 */
object WidgetRefreshRunner {
    enum class Outcome { SUCCESS, RETRY }

    suspend fun run(
        refresh: suspend () -> Unit,
        notifyWidgets: suspend () -> Unit,
    ): Outcome {
        val outcome =
            try {
                refresh()
                Outcome.SUCCESS
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Outcome.RETRY
            }
        try {
            notifyWidgets()
        } catch (e: CancellationException) {
            throw e
        } catch (_: Exception) {
            // No placed widget or Glance not ready: the next refresh notifies again.
        }
        return outcome
    }
}
