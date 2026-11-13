package io.github.sphaerox.influx_sensor_widgets.worker

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

class RefreshRetryPolicyTest {
    @Test
    fun successStaysSuccess() {
        assertEquals(
            RefreshRetryPolicy.Decision.SUCCESS,
            RefreshRetryPolicy.decide(WidgetRefreshRunner.Outcome.SUCCESS, isOneTime = false, runAttemptCount = 0),
        )
        assertEquals(
            RefreshRetryPolicy.Decision.SUCCESS,
            RefreshRetryPolicy.decide(WidgetRefreshRunner.Outcome.SUCCESS, isOneTime = true, runAttemptCount = 0),
        )
    }

    /**
     * Regression: a retried periodic work is rescheduled with exponential backoff (up to 5 hours)
     * instead of its 15-minute period, so a few failures during the night froze the widgets until
     * the morning. The periodic work must finish normally and simply run again next period.
     */
    @Test
    fun periodicWorkNeverRetriesAfterNetworkFailure() {
        for (attempt in listOf(0, 1, 5, 20)) {
            assertEquals(
                RefreshRetryPolicy.Decision.SUCCESS,
                RefreshRetryPolicy.decide(WidgetRefreshRunner.Outcome.RETRY, isOneTime = false, runAttemptCount = attempt),
            )
        }
    }

    @Test
    fun oneTimeWorkRetriesAFewTimes() {
        for (attempt in 0 until RefreshRetryPolicy.MAX_ONE_TIME_ATTEMPTS - 1) {
            assertEquals(
                RefreshRetryPolicy.Decision.RETRY,
                RefreshRetryPolicy.decide(WidgetRefreshRunner.Outcome.RETRY, isOneTime = true, runAttemptCount = attempt),
            )
        }
    }

    @Test
    fun oneTimeWorkGivesUpAfterMaxAttempts() {
        assertEquals(
            RefreshRetryPolicy.Decision.SUCCESS,
            RefreshRetryPolicy.decide(
                WidgetRefreshRunner.Outcome.RETRY,
                isOneTime = true,
                runAttemptCount = RefreshRetryPolicy.MAX_ONE_TIME_ATTEMPTS - 1,
            ),
        )
    }

    /** A new one-time request replaces a waiting (backing-off) one instead of piling up. */
    @Test
    fun oneTimeWorkNameIsStablePerTarget() {
        assertEquals(RefreshRetryPolicy.oneTimeWorkName(null), RefreshRetryPolicy.oneTimeWorkName(null))
        assertEquals(RefreshRetryPolicy.oneTimeWorkName("w1"), RefreshRetryPolicy.oneTimeWorkName("w1"))
        assertNotEquals(RefreshRetryPolicy.oneTimeWorkName(null), RefreshRetryPolicy.oneTimeWorkName("w1"))
        assertNotEquals(RefreshRetryPolicy.oneTimeWorkName("w1"), RefreshRetryPolicy.oneTimeWorkName("w2"))
        assertNotEquals(WidgetRefreshWorker.WORK_NAME_PERIODIC, RefreshRetryPolicy.oneTimeWorkName(null))
    }
}
