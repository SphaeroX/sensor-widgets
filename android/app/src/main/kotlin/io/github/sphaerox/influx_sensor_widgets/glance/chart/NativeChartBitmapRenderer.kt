package io.github.sphaerox.influx_sensor_widgets.glance.chart

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Shader
import io.github.sphaerox.influx_sensor_widgets.model.ChartStyle

object NativeChartBitmapRenderer {
    private const val FILL_ALPHA = 0x59
    private const val GRID_COLOR = 0x33FFFFFF
    private const val LABEL_COLOR = 0xFFB0B0B8.toInt()

    /**
     * Renders a styled chart (value gradient, fill, grid, axis labels, min/max markers).
     * Returns null when the data cannot be drawn (fewer than two points); the caller
     * then falls back to [renderSparkline]. Size is clamped to [ChartRenderPlan.MAX_WIDTH]
     * x [ChartRenderPlan.MAX_HEIGHT] to stay within RemoteViews bitmap limits.
     */
    fun renderChart(
        values: List<Double>,
        style: ChartStyle,
        width: Int = 300,
        height: Int = 100,
        lineColor: Int = 0xFF7C4DFF.toInt(),
    ): Bitmap? {
        val plan = ChartRenderPlan.create(values, style, width, height) ?: return null
        val bitmap = Bitmap.createBitmap(plan.width, plan.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val gridPaint =
            Paint().apply {
                color = GRID_COLOR
                strokeWidth = 1f
            }
        plan.gridYs.forEach { y -> canvas.drawLine(plan.left, y, plan.right, y, gridPaint) }

        val linePath = Path()
        plan.points.forEachIndexed { i, (x, y) -> if (i == 0) linePath.moveTo(x, y) else linePath.lineTo(x, y) }

        fun shader(alpha: Int): Shader? =
            plan.gradient?.let { g ->
                LinearGradient(
                    0f,
                    plan.bottom,
                    0f,
                    plan.top,
                    g.colors.map { (it and 0x00FFFFFF) or (alpha shl 24) }.toIntArray(),
                    g.positions.toFloatArray(),
                    Shader.TileMode.CLAMP,
                )
            }

        if (style.fillArea) {
            val fillPath = Path(linePath)
            fillPath.lineTo(plan.points.last().first, plan.bottom)
            fillPath.lineTo(plan.points.first().first, plan.bottom)
            fillPath.close()
            val fillPaint =
                Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    this.style = Paint.Style.FILL
                    val s = shader(FILL_ALPHA)
                    if (s != null) shader = s else color = (lineColor and 0x00FFFFFF) or (0x40 shl 24)
                }
            canvas.drawPath(fillPath, fillPaint)
        }

        val strokePaint =
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.style = Paint.Style.STROKE
                strokeWidth = style.lineWidth
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
                val s = shader(0xFF)
                if (s != null) shader = s else color = lineColor
            }
        canvas.drawPath(linePath, strokePaint)

        if (style.markMinMax) {
            val markerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = lineColor }
            listOf(plan.minIndex, plan.maxIndex).forEach { i ->
                val (x, y) = plan.points[i]
                canvas.drawCircle(x, y, style.lineWidth + 1.5f, markerPaint)
            }
        }

        plan.axisLabels?.let { (topLabel, bottomLabel) ->
            val textPaint =
                Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = LABEL_COLOR
                    textSize = 16f
                }
            canvas.drawText(topLabel, 0f, plan.top + 12f, textPaint)
            canvas.drawText(bottomLabel, 0f, plan.bottom, textPaint)
        }
        return bitmap
    }

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
