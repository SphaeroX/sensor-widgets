package io.github.mgasc.influx_sensor_widgets.glance

import org.junit.Assert.assertArrayEquals
import org.junit.Test

class ConfigScreenInsetsTest {
    @Test
    fun addsSystemBarInsetsToBasePadding() {
        val padding = ConfigScreenInsets.padding(basePx = 48, left = 0, top = 120, right = 0, bottom = 63)

        assertArrayEquals(intArrayOf(48, 168, 48, 111), padding)
    }

    @Test
    fun keepsBasePaddingWithoutInsets() {
        val padding = ConfigScreenInsets.padding(basePx = 48, left = 0, top = 0, right = 0, bottom = 0)

        assertArrayEquals(intArrayOf(48, 48, 48, 48), padding)
    }

    @Test
    fun includesSideInsetsForCutoutsInLandscape() {
        val padding = ConfigScreenInsets.padding(basePx = 10, left = 80, top = 0, right = 30, bottom = 0)

        assertArrayEquals(intArrayOf(90, 10, 40, 10), padding)
    }
}
