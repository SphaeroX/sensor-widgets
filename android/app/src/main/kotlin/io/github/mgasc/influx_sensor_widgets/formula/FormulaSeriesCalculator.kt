package io.github.mgasc.influx_sensor_widgets.formula

import io.github.mgasc.influx_sensor_widgets.influx.DurationUtils
import io.github.mgasc.influx_sensor_widgets.influx.InfluxHttpClient
import io.github.mgasc.influx_sensor_widgets.influx.InfluxQlBuilder
import io.github.mgasc.influx_sensor_widgets.influx.InfluxResponseParser
import io.github.mgasc.influx_sensor_widgets.model.FormulaVariable
import io.github.mgasc.influx_sensor_widgets.model.InfluxConnection
import io.github.mgasc.influx_sensor_widgets.model.SensorDataPoint
import io.github.mgasc.influx_sensor_widgets.model.SensorQueryItem
import io.github.mgasc.influx_sensor_widgets.model.WidgetDefinition
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.pow

/**
 * Evaluates a widget formula over time buckets. Mirrors the Dart
 * `FormulaCalculationService.calculateSeries/calculateAggregate`.
 */
object FormulaSeriesCalculator {
    data class BucketError(
        val timestamp: Long,
        val exception: FormulaException,
    )

    data class SeriesResult(
        val points: List<SensorDataPoint>,
        val errors: List<BucketError>,
    )

    private class VariableGroup(
        val measurement: String,
        val tagFilters: Map<String, String>?,
    ) {
        val variables = mutableListOf<FormulaVariable>()
    }

    fun calculateSeries(
        widget: WidgetDefinition,
        conn: InfluxConnection,
        token: String,
        httpClient: InfluxHttpClient,
    ): SeriesResult {
        val timeRange = widget.timeRange ?: "24h"
        val interval = DurationUtils.effectiveBucketInterval(timeRange, widget.aggregationInterval)
        val byVariable = linkedMapOf<String, Map<Long, Double>>()

        for (group in groupVariables(widget)) {
            val fields = group.variables.map { it.field }.distinct()
            val query =
                InfluxQlBuilder.buildBucketedMultiFieldQuery(
                    measurement = group.measurement,
                    fields = fields,
                    timeRange = timeRange,
                    bucketInterval = interval,
                    tagFilters = group.tagFilters,
                )
            val parsed = InfluxResponseParser.parseBucketedFields(httpClient.query(conn, token, query), fields)
            for (v in group.variables) {
                byVariable[v.name] = parsed[v.field] ?: emptyMap()
            }
        }
        return combine(widget, byVariable)
    }

    /** Merges per-variable buckets, honours `gapPolicy` and evaluates the formula per bucket. */
    fun combine(
        widget: WidgetDefinition,
        byVariable: Map<String, Map<Long, Double>>,
    ): SeriesResult {
        val formula = widget.formula ?: throw FormulaSyntaxException("Widget besitzt keine Formel")
        for ((name, series) in byVariable) {
            if (series.isEmpty()) throw MissingVariableException(name)
        }

        val carryForward = widget.gapPolicy == "previous"
        val timestamps = byVariable.values.flatMap { it.keys }.toSortedSet()
        val last = mutableMapOf<String, Double>()
        val points = mutableListOf<SensorDataPoint>()
        val errors = mutableListOf<BucketError>()

        for (ts in timestamps) {
            val values = mutableMapOf<String, Double>()
            var complete = true
            for ((name, series) in byVariable) {
                val current = series[ts]
                if (current != null) last[name] = current
                val resolved = current ?: if (carryForward) last[name] else null
                if (resolved == null) complete = false else values[name] = resolved
            }
            if (!complete) continue

            try {
                val raw = FormulaEvaluator.evaluate(formula, values, widget.formulaSteps ?: emptyList())
                points.add(SensorDataPoint(ts, round(raw, widget), widget.field ?: "formula"))
            } catch (e: FormulaException) {
                errors.add(BucketError(ts, e))
            }
        }

        if (points.isEmpty() && errors.isNotEmpty()) throw errors.first().exception
        return SeriesResult(points, errors)
    }

    /** Calculates the formula of one multi-value row from the latest values of its variables. */
    fun calculateItemLatest(
        widget: WidgetDefinition,
        item: SensorQueryItem,
        conn: InfluxConnection,
        token: String,
        httpClient: InfluxHttpClient,
    ): Double {
        val rowWidget =
            widget.copy(
                formula = item.formula,
                formulaVariables = item.formulaVariables,
                formulaSteps = item.formulaSteps,
                decimalPlaces = item.decimalPlaces ?: widget.decimalPlaces,
            )
        val values = mutableMapOf<String, Double>()
        for (group in groupVariables(rowWidget)) {
            val fields = group.variables.map { it.field }.distinct()
            val query = InfluxQlBuilder.buildMultiValueQuery(group.measurement, fields, group.tagFilters)
            val latest = InfluxResponseParser.parseMultiValues(httpClient.query(conn, token, query), fields)
            for (v in group.variables) {
                values[v.name] = latest[v.field]?.value ?: throw MissingVariableException(v.name)
            }
        }
        val raw = FormulaEvaluator.evaluate(item.formula.orEmpty(), values, item.formulaSteps ?: emptyList())
        return round(raw, rowWidget)
    }

    fun aggregate(
        result: SeriesResult,
        widget: WidgetDefinition,
    ): Map<String, Double> {
        if (result.points.isEmpty()) return emptyMap()
        val values = result.points.map { it.value }
        return mapOf(
            "min" to values.min(),
            "max" to values.max(),
            "mean" to round(values.sum() / values.size, widget),
        )
    }

    /** Short German summary of failed buckets, or null if all buckets succeeded. */
    fun summarizeErrors(errors: List<BucketError>): String? {
        if (errors.isEmpty()) return null
        val first = errors.first().exception.message
        return if (errors.size == 1) {
            "1 Zeit-Bucket nicht berechenbar: $first"
        } else {
            "${errors.size} Zeit-Buckets nicht berechenbar: $first"
        }
    }

    private fun groupVariables(widget: WidgetDefinition): List<VariableGroup> {
        fun tagsKey(tags: Map<String, String>?) = tags?.entries?.sortedBy { it.key }?.joinToString("&") { "${it.key}=${it.value}" } ?: ""

        val groups = linkedMapOf<String, VariableGroup>()
        for (v in widget.formulaVariables.orEmpty()) {
            val measurement = v.measurement ?: widget.measurement
            val tags = v.tagFilters ?: widget.tagFilters
            groups.getOrPut("$measurement||${tagsKey(tags)}") { VariableGroup(measurement, tags) }.variables.add(v)
        }
        return groups.values.toList()
    }

    /** Rounds half away from zero to at most 2 decimals, like the Dart `NumberFormatter`. */
    private fun round(
        value: Double,
        widget: WidgetDefinition,
    ): Double {
        val decimals = (widget.decimalPlaces ?: 2).coerceIn(0, 2)
        val factor = 10.0.pow(decimals)
        val scaled = abs(value) * factor
        val rounded = floor(scaled + 0.5) / factor
        return if (value < 0) -rounded else rounded
    }
}
