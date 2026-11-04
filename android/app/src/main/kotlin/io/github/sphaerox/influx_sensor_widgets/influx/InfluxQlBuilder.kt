package io.github.sphaerox.influx_sensor_widgets.influx

object InfluxQlBuilder {
    fun escapeIdentifier(identifier: String): String = identifier.replace("\"", "\\\"")

    fun escapeLiteral(literal: String): String = literal.replace("'", "\\'")

    private fun buildTagFilterClause(tagFilters: Map<String, String>?): String {
        if (tagFilters.isNullOrEmpty()) return ""
        val sortedKeys = tagFilters.keys.sorted()
        return sortedKeys.joinToString(" AND ") { key ->
            val escapedKey = escapeIdentifier(key)
            val escapedVal = escapeLiteral(tagFilters[key] ?: "")
            "\"$escapedKey\" = '$escapedVal'"
        }
    }

    fun buildSingleValueQuery(
        measurement: String,
        field: String,
        tagFilters: Map<String, String>? = null,
    ): String {
        val m = escapeIdentifier(measurement)
        val f = escapeIdentifier(field)
        val tagClause = buildTagFilterClause(tagFilters)
        return if (tagClause.isEmpty()) {
            "SELECT \"$f\" FROM \"$m\" ORDER BY time DESC LIMIT 1"
        } else {
            "SELECT \"$f\" FROM \"$m\" WHERE $tagClause ORDER BY time DESC LIMIT 1"
        }
    }

    /** Several fields of one measurement as time buckets; empty buckets are `null` (`fill(null)`). */
    fun buildBucketedMultiFieldQuery(
        measurement: String,
        fields: List<String>,
        timeRange: String,
        bucketInterval: String,
        tagFilters: Map<String, String>? = null,
    ): String {
        val m = escapeIdentifier(measurement)
        val selects =
            fields.joinToString(", ") {
                val e = escapeIdentifier(it)
                "MEAN(\"$e\") AS \"$e\""
            }
        val tagClause = buildTagFilterClause(tagFilters)
        val whereClause =
            if (tagClause.isEmpty()) {
                "time > now() - $timeRange"
            } else {
                "time > now() - $timeRange AND $tagClause"
            }
        return "SELECT $selects FROM \"$m\" WHERE $whereClause GROUP BY time($bucketInterval) fill(null)"
    }

    fun buildHistoryQuery(
        measurement: String,
        field: String,
        timeRange: String,
        bucketInterval: String,
        tagFilters: Map<String, String>? = null,
    ): String {
        val m = escapeIdentifier(measurement)
        val f = escapeIdentifier(field)
        val tagClause = buildTagFilterClause(tagFilters)
        val whereClause =
            if (tagClause.isEmpty()) {
                "time > now() - $timeRange"
            } else {
                "time > now() - $timeRange AND $tagClause"
            }
        return "SELECT MEAN(\"$f\") AS \"mean\" FROM \"$m\" WHERE $whereClause GROUP BY time($bucketInterval) fill(none)"
    }

    fun buildAggregateQuery(
        measurement: String,
        field: String,
        timeRange: String,
        tagFilters: Map<String, String>? = null,
    ): String {
        val m = escapeIdentifier(measurement)
        val f = escapeIdentifier(field)
        val tagClause = buildTagFilterClause(tagFilters)
        val whereClause =
            if (tagClause.isEmpty()) {
                "time > now() - $timeRange"
            } else {
                "time > now() - $timeRange AND $tagClause"
            }
        return "SELECT MIN(\"$f\") AS \"min\", MAX(\"$f\") AS \"max\", MEAN(\"$f\") AS \"mean\" FROM \"$m\" WHERE $whereClause"
    }

    fun buildMultiValueQuery(
        measurement: String,
        fields: List<String>,
        tagFilters: Map<String, String>? = null,
    ): String {
        val m = escapeIdentifier(measurement)
        val escapedFields = fields.joinToString(", ") { "\"${escapeIdentifier(it)}\"" }
        val tagClause = buildTagFilterClause(tagFilters)
        return if (tagClause.isEmpty()) {
            "SELECT $escapedFields FROM \"$m\" ORDER BY time DESC LIMIT 1"
        } else {
            "SELECT $escapedFields FROM \"$m\" WHERE $tagClause ORDER BY time DESC LIMIT 1"
        }
    }

    fun buildShowMeasurementsQuery(): String = "SHOW MEASUREMENTS"

    fun buildShowFieldKeysQuery(measurement: String): String = "SHOW FIELD KEYS FROM \"${escapeIdentifier(measurement)}\""

    fun buildShowTagKeysQuery(measurement: String): String = "SHOW TAG KEYS FROM \"${escapeIdentifier(measurement)}\""

    fun buildShowTagValuesQuery(
        measurement: String,
        tagKey: String,
    ): String = "SHOW TAG VALUES FROM \"${escapeIdentifier(measurement)}\" WITH KEY = \"${escapeIdentifier(tagKey)}\""
}
