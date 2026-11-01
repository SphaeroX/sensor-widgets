package io.github.mgasc.influx_sensor_widgets.model

import org.json.JSONArray
import org.json.JSONObject

object WidgetDefinitionParser {
    fun parseDefinitionsList(jsonString: String): List<WidgetDefinition> {
        val trimmed = jsonString.trim()
        val array =
            if (trimmed.startsWith("[")) {
                JSONArray(trimmed)
            } else {
                val root = JSONObject(trimmed)
                if (root.has("widgets")) {
                    root.getJSONArray("widgets")
                } else {
                    JSONArray()
                }
            }
        return parseArray(array)
    }

    fun parseArray(array: JSONArray): List<WidgetDefinition> {
        val list = mutableListOf<WidgetDefinition>()
        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            list.add(parseObject(obj))
        }
        return list
    }

    fun parseObject(json: JSONObject): WidgetDefinition {
        val tagFilters =
            if (json.has("tagFilters") && !json.isNull("tagFilters")) {
                val tagsObj = json.getJSONObject("tagFilters")
                val map = mutableMapOf<String, String>()
                tagsObj.keys().forEach { key ->
                    map[key] = tagsObj.getString(key)
                }
                map
            } else {
                null
            }

        val threshold =
            if (json.has("threshold") && !json.isNull("threshold")) {
                parseThreshold(json.getJSONObject("threshold"))
            } else {
                null
            }

        val thresholds =
            if (json.has("thresholds") && !json.isNull("thresholds")) {
                val tArr = json.getJSONArray("thresholds")
                val tList = mutableListOf<ThresholdRule>()
                for (i in 0 until tArr.length()) {
                    tList.add(parseThreshold(tArr.getJSONObject(i)))
                }
                tList
            } else {
                null
            }

        val items =
            if (json.has("items") && !json.isNull("items")) {
                val itemsArr = json.getJSONArray("items")
                (0 until itemsArr.length()).map { parseItem(itemsArr.getJSONObject(it)) }
            } else {
                null
            }

        val formulaVariables = parseFormulaVariables(json)
        val formulaSteps = parseFormulaSteps(json)

        return WidgetDefinition(
            id = json.getString("id"),
            type = WidgetType.fromWireName(json.getString("type")),
            title = json.getString("title"),
            connectionId = json.getString("connectionId"),
            measurement = json.getString("measurement"),
            field = json.optString("field").takeIf { it.isNotEmpty() },
            tagFilters = tagFilters,
            unit = json.optString("unit").takeIf { it.isNotEmpty() },
            decimalPlaces =
                if (json.has("decimalPlaces") && !json.isNull("decimalPlaces")) {
                    json.getInt("decimalPlaces")
                } else {
                    null
                },
            refreshIntervalMinutes = json.optInt("refreshIntervalMinutes", 15),
            timeRange = json.optString("timeRange").takeIf { it.isNotEmpty() },
            aggregationInterval = json.optString("aggregationInterval").takeIf { it.isNotEmpty() },
            aggregateFunction = json.optString("aggregateFunction").takeIf { it.isNotEmpty() },
            threshold = threshold,
            min = if (json.has("min") && !json.isNull("min")) json.getDouble("min") else null,
            max = if (json.has("max") && !json.isNull("max")) json.getDouble("max") else null,
            thresholds = thresholds,
            items = items,
            formula = json.optString("formula").takeIf { it.isNotEmpty() },
            formulaVariables = formulaVariables,
            formulaSteps = formulaSteps,
            gapPolicy = json.optString("gapPolicy").takeIf { it.isNotEmpty() },
            chartStyle = parseChartStyle(json),
        )
    }

    private fun parseChartStyle(owner: JSONObject): ChartStyle? {
        if (!owner.has("chartStyle") || owner.isNull("chartStyle")) return null
        val obj = owner.getJSONObject("chartStyle")
        val stopsArr = obj.optJSONArray("colorStops")
        val stops =
            if (stopsArr == null) {
                emptyList()
            } else {
                (0 until stopsArr.length()).map {
                    val s = stopsArr.getJSONObject(it)
                    ColorStop(value = s.getDouble("value"), color = s.getString("color"))
                }
            }
        return ChartStyle(
            colorStops = stops,
            fillArea = obj.optBoolean("fillArea", false),
            showGrid = obj.optBoolean("showGrid", false),
            showAxes = obj.optBoolean("showAxes", false),
            markMinMax = obj.optBoolean("markMinMax", false),
            lineWidth = obj.optDouble("lineWidth", ChartStyle.DEFAULT_LINE_WIDTH.toDouble()).toFloat(),
        )
    }

    private fun parseItem(itemObj: JSONObject): SensorQueryItem =
        SensorQueryItem(
            field = itemObj.getString("field"),
            label = itemObj.optString("label").takeIf { it.isNotEmpty() },
            unit = itemObj.optString("unit").takeIf { it.isNotEmpty() },
            decimalPlaces =
                if (itemObj.has("decimalPlaces") && !itemObj.isNull("decimalPlaces")) {
                    itemObj.getInt("decimalPlaces")
                } else {
                    null
                },
            formula = itemObj.optString("formula").takeIf { it.isNotEmpty() },
            formulaVariables = parseFormulaVariables(itemObj),
            formulaSteps = parseFormulaSteps(itemObj),
        )

    private fun parseFormulaVariables(owner: JSONObject): List<FormulaVariable>? {
        if (!owner.has("formulaVariables") || owner.isNull("formulaVariables")) return null
        val arr = owner.getJSONArray("formulaVariables")
        return (0 until arr.length()).map {
            val obj = arr.getJSONObject(it)
            val tags =
                if (obj.has("tagFilters") && !obj.isNull("tagFilters")) {
                    val tagsObj = obj.getJSONObject("tagFilters")
                    tagsObj.keys().asSequence().associateWith { key -> tagsObj.getString(key) }
                } else {
                    null
                }
            FormulaVariable(
                name = obj.getString("name"),
                field = obj.getString("field"),
                measurement = obj.optString("measurement").takeIf { v -> v.isNotEmpty() },
                tagFilters = tags,
                label = obj.optString("label").takeIf { v -> v.isNotEmpty() },
            )
        }
    }

    private fun parseFormulaSteps(owner: JSONObject): List<FormulaStep>? {
        if (!owner.has("formulaSteps") || owner.isNull("formulaSteps")) return null
        val arr = owner.getJSONArray("formulaSteps")
        return (0 until arr.length()).map {
            val obj = arr.getJSONObject(it)
            FormulaStep(
                name = obj.getString("name"),
                expression = obj.getString("expression"),
                label = obj.optString("label").takeIf { v -> v.isNotEmpty() },
            )
        }
    }

    private fun parseThreshold(obj: JSONObject): ThresholdRule =
        ThresholdRule(
            operator = ThresholdOperator.fromWireName(obj.getString("operator")),
            value = obj.getDouble("value"),
            color = obj.optString("color").takeIf { it.isNotEmpty() },
            activeColor = obj.optString("activeColor").takeIf { it.isNotEmpty() },
            inactiveColor = obj.optString("inactiveColor").takeIf { it.isNotEmpty() },
        )
}
