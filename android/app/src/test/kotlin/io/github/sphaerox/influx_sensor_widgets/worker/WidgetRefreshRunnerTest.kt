package io.github.sphaerox.influx_sensor_widgets.worker

import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetRefreshRunnerTest {
    @Test
    fun notifiesWidgetsAfterSuccessfulRefresh() =
        runTest {
            val calls = mutableListOf<String>()

            val outcome =
                WidgetRefreshRunner.run(
                    refresh = { calls += "refresh" },
                    notifyWidgets = { calls += "notify" },
                )

            assertEquals(listOf("refresh", "notify"), calls)
            assertEquals(WidgetRefreshRunner.Outcome.SUCCESS, outcome)
        }

    @Test
    fun stillNotifiesWidgetsWhenRefreshFails() =
        runTest {
            val calls = mutableListOf<String>()

            val outcome =
                WidgetRefreshRunner.run(
                    refresh = {
                        calls += "refresh"
                        throw IllegalStateException("boom")
                    },
                    notifyWidgets = { calls += "notify" },
                )

            assertEquals(listOf("refresh", "notify"), calls)
            assertEquals(WidgetRefreshRunner.Outcome.RETRY, outcome)
        }

    @Test
    fun notifyFailureDoesNotTurnSuccessIntoRetry() =
        runTest {
            val outcome =
                WidgetRefreshRunner.run(
                    refresh = { },
                    notifyWidgets = { throw IllegalStateException("no glance ids") },
                )

            assertEquals(WidgetRefreshRunner.Outcome.SUCCESS, outcome)
        }
}
