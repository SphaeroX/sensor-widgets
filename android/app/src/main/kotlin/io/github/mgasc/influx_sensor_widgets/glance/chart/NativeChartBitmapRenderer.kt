package io.github.mgasc.influx_sensor_widgets.glance.chart

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path

object NativeChartBitmapRenderer {
    fun renderSparkline(
        normalizedPoints: List<Float>,
        width: Int = 300,
        height: Int = 100,
        lineColor: Int = 0xFF7C4DFF.toInt(),
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        if (normalizedPoints.isEmpty()) {
            return bitmap
        }

        val strokePaint =
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = lineColor
                style = Paint.Style.STROKE
                strokeWidth = 4f
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
            }

        val padding = 8f
        val drawWidth = width - (padding * 2)
        val drawHeight = height - (padding * 2)

        val path = Path()
        val stepX =
            if (normalizedPoints.size > 1) {
                drawWidth / (normalizedPoints.size - 1)
            } else {
                drawWidth
            }

        for (i in normalizedPoints.indices) {
            val x = padding + (i * stepX)
            // Normalized: 0.0 is min, 1.0 is max. On canvas, y=0 is top, y=height is bottom.
            val y = padding + drawHeight - (normalizedPoints[i] * drawHeight)
            if (i == 0) {
                path.moveTo(x, y)
            } else {
                path.lineTo(x, y)
            }
        }

        canvas.drawPath(path, strokePaint)
        return bitmap
    }
}
