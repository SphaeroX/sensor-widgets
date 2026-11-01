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
                val itemsList = mutableListOf<SensorQueryItem>()
                for (i in 0 until itemsArr.length()) {
                    val itemObj = itemsArr.getJSONObject(i)
                    itemsList.add(
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
                        ),
                    )
                }
                itemsList
            } else {
                null
            }

        val formulaVariables =
            if (json.has("formulaVariables") && !json.isNull("formulaVariables")) {
                val fvArr = json.getJSONArray("formulaVariables")
                val fvList = mutableListOf<FormulaVariable>()
                for (i in 0 until fvArr.length()) {
                    val fvObj = fvArr.getJSONObject(i)
                    val varTags =
                        if (fvObj.has("tagFilters") && !fvObj.isNull("tagFilters")) {
                            val tagsObj = fvObj.getJSONObject("tagFilters")
                            val map = mutableMapOf<String, String>()
                            tagsObj.keys().forEach { key ->
                                map[key] = tagsObj.getString(key)
                            }
                            map
                        } else {
                            null
                        }
                    fvList.add(
                        FormulaVariable(
                            name = fvObj.getString("name"),
                            field = fvObj.getString("field"),
                            measurement = fvObj.optString("measurement").takeIf { it.isNotEmpty() },
                            tagFilters = varTags,
                            label = fvObj.optString("label").takeIf { it.isNotEmpty() },
                        ),
                    )
                }
                fvList
            } else {
                null
            }

        val formulaSteps =
            if (json.has("formulaSteps") && !json.isNull("formulaSteps")) {
                val arr = json.getJSONArray("formulaSteps")
                (0 until arr.length()).map {
                    val o = arr.getJSONObject(it)
                    FormulaStep(
                        name = o.getString("name"),
                        expression = o.getString("expression"),
                        label = o.optString("label").takeIf { l -> l.isNotEmpty() },
                    )
                }
            } else {
                null
            }

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
        )
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
