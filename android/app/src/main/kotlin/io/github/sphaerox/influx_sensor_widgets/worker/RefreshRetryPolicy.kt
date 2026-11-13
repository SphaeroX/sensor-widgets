package io.github.sphaerox.influx_sensor_widgets.worker

/**
 * Decides what a finished refresh reports to WorkManager.
 *
 * Periodic work never asks for a retry: WorkManager would reschedule it with exponential
 * backoff (30 s doubling up to 5 hours) instead of its 15-minute period, and the backoff
 * only resets after a success. A few network failures in Doze during the night then froze
 * the widgets for hours. The periodic work simply runs again next period; the cache keeps
 * the last good values thanks to [NetworkErrorGrace].
 *
 * One-time work (↻ button, app save, system update) retries a few times, then gives up.
 */
object RefreshRetryPolicy {
    enum class Decision { SUCCESS, RETRY }

    const val MAX_ONE_TIME_ATTEMPTS = 4

    private const val ONE_TIME_WORK_PREFIX = "sensor_widgets_one_time_refresh"

    fun decide(
        outcome: WidgetRefreshRunner.Outcome,
        isOneTime: Boolean,
        runAttemptCount: Int,
    ): Decision =
        when {
            outcome == WidgetRefreshRunner.Outcome.SUCCESS -> Decision.SUCCESS
            !isOneTime -> Decision.SUCCESS
            runAttemptCount + 1 >= MAX_ONE_TIME_ATTEMPTS -> Decision.SUCCESS
            else -> Decision.RETRY
        }

    /** Unique name per target, so a new request replaces one that is still waiting in backoff. */
    fun oneTimeWorkName(targetWidgetId: String?): String =
        if (targetWidgetId == null) "${ONE_TIME_WORK_PREFIX}_all" else "${ONE_TIME_WORK_PREFIX}_$targetWidgetId"
}
