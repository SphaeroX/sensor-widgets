package io.github.sphaerox.influx_sensor_widgets.alerts

import io.github.sphaerox.influx_sensor_widgets.model.AlertRule
import io.github.sphaerox.influx_sensor_widgets.model.ThresholdOperator
import org.json.JSONArray
import org.json.JSONObject

data class AlertHit(
    val rule: AlertRule,
    val actualValue: Double,
)

/**
 * Edge-triggered threshold check: a rule notifies when it starts matching and only
 * again after it stopped matching once. [Result.active] is stored per widget and passed
 * back as `previouslyActive` on the next refresh. Cases: `fixtures/alerts/evaluation_cases.json`.
 */
object AlertEvaluator {
    data class Result(
        val triggered: List<AlertHit>,
        val active: List<AlertRule>,
    )

    fun evaluate(
        rules: List<AlertRule>,
        cacheJson: String,
        previouslyActive: List<AlertRule>,
    ): Result {
        val cache =
            try {
                JSONObject(cacheJson)
            } catch (_: Exception) {
                null
            }
        if (cache == null || cache.has("error")) {
            return Result(emptyList(), rules.filter { it in previouslyActive })
        }
        val triggered = mutableListOf<AlertHit>()
        val active = mutableListOf<AlertRule>()
        for (rule in rules) {
            val wasActive = rule in previouslyActive
            val actual = resolveValue(rule.target, cache)
            if (actual == null) {
                if (wasActive) active += rule
                continue
            }
            if (rule.matches(actual)) {
                active += rule
                if (!wasActive) triggered += AlertHit(rule, actual)
            }
        }
        return Result(triggered, active)
    }

    /** Reads the value a rule targets from a widget cache entry, or null when it is not there. */
    fun resolveValue(
        target: String,
        cache: JSONObject,
    ): Double? {
        if (target == AlertRule.TARGET_VALUE) {
            if (cache.has("value") && !cache.isNull("value")) return cache.getDouble("value")
            val points = cache.optJSONArray("points")
            if (points != null && points.length() > 0) return points.getJSONObject(points.length() - 1).getDouble("v")
        }
        val row = cache.optJSONObject("values")?.optJSONObject(target)
        if (row != null && row.has("value")) return row.getDouble("value")
        val aggregates = cache.optJSONObject("aggregates")
        if (aggregates != null && aggregates.has(target) && !aggregates.isNull(target)) return aggregates.getDouble(target)
        return null
    }

    fun encodeState(active: List<AlertRule>): String {
        val arr = JSONArray()
        active.forEach {
            arr.put(JSONObject().put("target", it.target).put("operator", it.operator.wireName).put("value", it.value))
        }
        return arr.toString()
    }

    fun decodeState(json: String?): List<AlertRule> {
        if (json.isNullOrEmpty()) return emptyList()
        return try {
            val arr = JSONArray(json)
            (0 until arr.length()).map {
                val o = arr.getJSONObject(it)
                AlertRule(o.getString("target"), ThresholdOperator.fromWireName(o.getString("operator")), o.getDouble("value"))
            }
        } catch (_: Exception) {
            emptyList()
        }
    }
}
