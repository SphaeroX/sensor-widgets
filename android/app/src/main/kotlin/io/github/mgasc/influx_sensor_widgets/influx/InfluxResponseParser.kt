package io.github.mgasc.influx_sensor_widgets.influx

import io.github.mgasc.influx_sensor_widgets.model.SensorDataPoint
import org.json.JSONArray
import org.json.JSONObject

object InfluxResponseParser {
    private fun checkErrors(json: JSONObject) {
        if (json.has("error")) {
            throw InfluxQueryException(json.getString("error"))
        }
        val results = json.optJSONArray("results")
        if (results != null && results.length() > 0) {
            val first = results.getJSONObject(0)
            if (first.has("error")) {
                throw InfluxQueryException(first.getString("error"))
            }
        }
    }

    private fun extractSeries(json: JSONObject): JSONArray? {
        checkErrors(json)
        val results = json.optJSONArray("results") ?: return null
        if (results.length() == 0) return null
        val first = results.getJSONObject(0)
        return first.optJSONArray("series")
    }

    fun parseSingleValue(
        json: JSONObject,
        fieldName: String,
    ): SensorDataPoint? {
        val seriesArr = extractSeries(json) ?: return null
        if (seriesArr.length() == 0) return null
        val series = seriesArr.getJSONObject(0)
        val columns = series.getJSONArray("columns")
        val values = series.optJSONArray("values") ?: return null
        if (values.length() == 0) return null

        val firstRow = values.getJSONArray(0)
        var timeIdx = -1
        var fieldIdx = -1

        for (i in 0 until columns.length()) {
            val col = columns.getString(i)
            if (col == "time") timeIdx = i
            if (col == fieldName) fieldIdx = i
        }

        if (fieldIdx == -1) {
            if (columns.length() == 2 && timeIdx != -1) {
                fieldIdx = if (timeIdx == 0) 1 else 0
            } else {
                return null
            }
        }

        if (firstRow.isNull(fieldIdx)) return null
        val value = firstRow.getDouble(fieldIdx)
        val timestamp =
            if (timeIdx != -1 && !firstRow.isNull(timeIdx)) {
                firstRow.getLong(timeIdx)
            } else {
                System.currentTimeMillis()
            }

        return SensorDataPoint(timestamp = timestamp, value = value, field = fieldName)
    }

    fun parseTimeSeries(
        json: JSONObject,
        fieldName: String,
    ): List<SensorDataPoint> {
        val seriesArr = extractSeries(json) ?: return emptyList()
        if (seriesArr.length() == 0) return emptyList()
        val series = seriesArr.getJSONObject(0)
        val columns = series.getJSONArray("columns")
        val values = series.optJSONArray("values") ?: return emptyList()

        var timeIdx = -1
        var fieldIdx = -1
        for (i in 0 until columns.length()) {
            val col = columns.getString(i)
            if (col == "time") timeIdx = i
            if (col == fieldName) fieldIdx = i
        }

        if (fieldIdx == -1) {
            if (columns.length() == 2 && timeIdx != -1) {
                fieldIdx = if (timeIdx == 0) 1 else 0
            } else {
                return emptyList()
            }
        }

        val points = mutableListOf<SensorDataPoint>()
        for (i in 0 until values.length()) {
            val row = values.getJSONArray(i)
            if (row.isNull(fieldIdx)) continue
            val value = row.getDouble(fieldIdx)
            val timestamp =
                if (timeIdx != -1 && !row.isNull(timeIdx)) {
                    row.getLong(timeIdx)
                } else {
                    0L
                }
            points.add(SensorDataPoint(timestamp = timestamp, value = value, field = fieldName))
        }
        return points
    }

    fun parseMultiValues(
        json: JSONObject,
        fields: List<String>,
    ): Map<String, SensorDataPoint> {
        val seriesArr = extractSeries(json) ?: return emptyMap()
        if (seriesArr.length() == 0) return emptyMap()
        val series = seriesArr.getJSONObject(0)
        val columns = series.getJSONArray("columns")
        val values = series.optJSONArray("values") ?: return emptyMap()
        if (values.length() == 0) return emptyMap()

        val firstRow = values.getJSONArray(0)
        var timeIdx = -1
        val colMap = mutableMapOf<String, Int>()
        for (i in 0 until columns.length()) {
            val col = columns.getString(i)
            if (col == "time") timeIdx = i
            colMap[col] = i
        }

        val timestamp =
            if (timeIdx != -1 && !firstRow.isNull(timeIdx)) {
                firstRow.getLong(timeIdx)
            } else {
                System.currentTimeMillis()
            }

        val result = mutableMapOf<String, SensorDataPoint>()
        for (field in fields) {
            val idx = colMap[field]
            if (idx != null && !firstRow.isNull(idx)) {
                result[field] =
                    SensorDataPoint(
                        timestamp = timestamp,
                        value = firstRow.getDouble(idx),
                        field = field,
                    )
            }
        }
        return result
    }

    fun parseAggregate(json: JSONObject): Map<String, Double> {
        val seriesArr = extractSeries(json) ?: return emptyMap()
        if (seriesArr.length() == 0) return emptyMap()
        val series = seriesArr.getJSONObject(0)
        val columns = series.getJSONArray("columns")
        val values = series.optJSONArray("values") ?: return emptyMap()
        if (values.length() == 0) return emptyMap()

        val firstRow = values.getJSONArray(0)
        val map = mutableMapOf<String, Double>()
        for (i in 0 until columns.length()) {
            val col = columns.getString(i).lowercase()
            if (col == "time") continue
            if (!firstRow.isNull(i)) {
                map[col] = firstRow.getDouble(i)
            }
        }
        return map
    }

    fun parseMeasurements(json: JSONObject): List<String> {
        val seriesArr = extractSeries(json) ?: return emptyList()
        if (seriesArr.length() == 0) return emptyList()
        val series = seriesArr.getJSONObject(0)
        val values = series.optJSONArray("values") ?: return emptyList()
        val list = mutableListOf<String>()
        for (i in 0 until values.length()) {
            list.add(values.getJSONArray(i).getString(0))
        }
        return list
    }

    fun parseFieldKeys(json: JSONObject): List<String> {
        val seriesArr = extractSeries(json) ?: return emptyList()
        if (seriesArr.length() == 0) return emptyList()
        val series = seriesArr.getJSONObject(0)
        val values = series.optJSONArray("values") ?: return emptyList()
        val list = mutableListOf<String>()
        for (i in 0 until values.length()) {
            list.add(values.getJSONArray(i).getString(0))
        }
        return list
    }

    fun parseTagKeys(json: JSONObject): List<String> {
        val seriesArr = extractSeries(json) ?: return emptyList()
        if (seriesArr.length() == 0) return emptyList()
        val series = seriesArr.getJSONObject(0)
        val values = series.optJSONArray("values") ?: return emptyList()
        val list = mutableListOf<String>()
        for (i in 0 until values.length()) {
            list.add(values.getJSONArray(i).getString(0))
        }
        return list
    }

    fun parseTagValues(json: JSONObject): List<String> {
        val seriesArr = extractSeries(json) ?: return emptyList()
        if (seriesArr.length() == 0) return emptyList()
        val series = seriesArr.getJSONObject(0)
        val columns = series.getJSONArray("columns")
        val values = series.optJSONArray("values") ?: return emptyList()

        var valIdx = 1
        for (i in 0 until columns.length()) {
            if (columns.getString(i) == "value") {
                valIdx = i
                break
            }
        }

        val list = mutableListOf<String>()
        for (i in 0 until values.length()) {
            list.add(values.getJSONArray(i).getString(valIdx))
        }
        return list
    }
}
