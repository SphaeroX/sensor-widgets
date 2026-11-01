package io.github.mgasc.influx_sensor_widgets.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.Data
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import io.github.mgasc.influx_sensor_widgets.formula.FormulaEvaluator
import io.github.mgasc.influx_sensor_widgets.formula.MissingVariableException
import io.github.mgasc.influx_sensor_widgets.influx.InfluxHttpClient
import io.github.mgasc.influx_sensor_widgets.influx.InfluxQlBuilder
import io.github.mgasc.influx_sensor_widgets.influx.InfluxResponseParser
import io.github.mgasc.influx_sensor_widgets.model.WidgetDefinition
import io.github.mgasc.influx_sensor_widgets.model.WidgetType
import io.github.mgasc.influx_sensor_widgets.storage.WidgetStorageReader
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class WidgetRefreshWorker(
    context: Context,
    workerParams: WorkerParameters,
) : CoroutineWorker(context, workerParams) {
    override suspend fun doWork(): Result {
        val targetId = inputData.getString(KEY_WIDGET_ID)
        val storageReader = WidgetStorageReader(applicationContext)
        val httpClient = InfluxHttpClient()

        return try {
            refreshWidgets(storageReader, httpClient, targetId)
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    companion object {
        const val TAG = "WidgetRefreshWorker"
        const val WORK_NAME_PERIODIC = "sensor_widgets_periodic_refresh"
        const val KEY_WIDGET_ID = "target_widget_id"

        fun refreshWidgets(
            storageReader: WidgetStorageReader,
            httpClient: InfluxHttpClient,
            targetWidgetId: String? = null,
        ): Int {
            val allWidgets = storageReader.getWidgetDefinitions()
            val widgetsToRefresh =
                if (targetWidgetId != null) {
                    allWidgets.filter { it.id == targetWidgetId }
                } else {
                    allWidgets
                }

            if (widgetsToRefresh.isEmpty()) return 0

            val connections = storageReader.getConnections().associateBy { it.id }

            for (widget in widgetsToRefresh) {
                val conn = connections[widget.connectionId]
                if (conn == null) {
                    val errJson =
                        JSONObject().apply {
                            put("error", "Verbindung nicht gefunden")
                            put("timestamp", System.currentTimeMillis())
                        }
                    storageReader.saveWidgetCache(widget.id, errJson.toString())
                    continue
                }

                val token = storageReader.getToken(conn.id)
                if (token.isNullOrEmpty()) {
                    val errJson =
                        JSONObject().apply {
                            put("error", "Authentifizierungs-Token fehlt")
                            put("timestamp", System.currentTimeMillis())
                        }
                    storageReader.saveWidgetCache(widget.id, errJson.toString())
                    continue
                }

                try {
                    val cacheJson = executeQueryAndBuildCache(widget, conn, token, httpClient)
                    storageReader.saveWidgetCache(widget.id, cacheJson)
                } catch (e: Exception) {
                    val errJson =
                        JSONObject().apply {
                            put("error", e.message ?: "Abfragefehler")
                            put("timestamp", System.currentTimeMillis())
                        }
                    storageReader.saveWidgetCache(widget.id, errJson.toString())
                }
            }

            return widgetsToRefresh.size
        }

        private fun executeQueryAndBuildCache(
            widget: WidgetDefinition,
            conn: io.github.mgasc.influx_sensor_widgets.model.InfluxConnection,
            token: String,
            httpClient: InfluxHttpClient,
        ): String {
            val cacheObj = JSONObject()
            cacheObj.put("widgetId", widget.id)
            cacheObj.put("type", widget.type.wireName)
            if (widget.unit != null) cacheObj.put("unit", widget.unit)

            when (widget.type) {
                WidgetType.SINGLE_VALUE, WidgetType.INDICATOR_LAMP, WidgetType.GAUGE_BAR -> {
                    if (!widget.formula.isNullOrBlank() && !widget.formulaVariables.isNullOrEmpty()) {
                        val varValues = mutableMapOf<String, Double>()
                        val groups =
                            widget.formulaVariables.groupBy { v ->
                                val m = v.measurement ?: widget.measurement
                                val tagsKey =
                                    v.tagFilters
                                        ?.entries
                                        ?.sortedBy { it.key }
                                        ?.joinToString("&") { "${it.key}=${it.value}" }
                                        ?: (
                                            widget.tagFilters
                                                ?.entries
                                                ?.sortedBy { it.key }
                                                ?.joinToString("&") { "${it.key}=${it.value}" }
                                                ?: ""
                                        )
                                "$m||$tagsKey"
                            }

                        for ((_, groupVars) in groups) {
                            val first = groupVars.first()
                            val m = first.measurement ?: widget.measurement
                            val tags = first.tagFilters ?: widget.tagFilters
                            val fields = groupVars.map { it.field }.distinct()

                            val query = InfluxQlBuilder.buildMultiValueQuery(m, fields, tags)
                            val json = httpClient.query(conn, token, query)
                            val multiValues = InfluxResponseParser.parseMultiValues(json, fields)

                            for (v in groupVars) {
                                val point =
                                    multiValues[v.field]
                                        ?: throw MissingVariableException(v.name)
                                varValues[v.name] = point.value
                            }
                        }

                        val calculatedValue = FormulaEvaluator.evaluate(widget.formula, varValues, widget.formulaSteps ?: emptyList())
                        val decimals = (widget.decimalPlaces ?: 2).coerceIn(0, 2)
                        val multiplier =
                            when (decimals) {
                                0 -> 1.0
                                1 -> 10.0
                                else -> 100.0
                            }
                        val roundedValue = Math.round(calculatedValue * multiplier) / multiplier
                        cacheObj.put("value", roundedValue)
                        cacheObj.put("timestamp", System.currentTimeMillis())
                        if (widget.type == WidgetType.INDICATOR_LAMP && widget.threshold != null) {
                            cacheObj.put("isActive", widget.threshold.matches(roundedValue))
                        }
                    } else {
                        val field = widget.field ?: ""
                        val query =
                            InfluxQlBuilder.buildSingleValueQuery(
                                measurement = widget.measurement,
                                field = field,
                                tagFilters = widget.tagFilters,
                            )
                        val json = httpClient.query(conn, token, query)
                        val point = InfluxResponseParser.parseSingleValue(json, field)
                        if (point != null) {
                            cacheObj.put("value", point.value)
                            cacheObj.put("timestamp", point.timestamp)
                            if (widget.type == WidgetType.INDICATOR_LAMP && widget.threshold != null) {
                                cacheObj.put("isActive", widget.threshold.matches(point.value))
                            }
                        } else {
                            cacheObj.put("error", "Keine Messdaten gefunden")
                            cacheObj.put("timestamp", System.currentTimeMillis())
                        }
                    }
                }

                WidgetType.HISTORY_CHART -> {
                    val field = widget.field ?: ""
                    val query =
                        InfluxQlBuilder.buildHistoryQuery(
                            measurement = widget.measurement,
                            field = field,
                            timeRange = widget.timeRange ?: "24h",
                            bucketInterval = widget.aggregationInterval ?: "1h",
                            tagFilters = widget.tagFilters,
                        )
                    val json = httpClient.query(conn, token, query)
                    val points = InfluxResponseParser.parseTimeSeries(json, field)
                    val pointsArr = JSONArray()
                    for (p in points) {
                        val pObj =
                            JSONObject().apply {
                                put("t", p.timestamp)
                                put("v", p.value)
                            }
                        pointsArr.put(pObj)
                    }
                    cacheObj.put("points", pointsArr)
                    cacheObj.put("timestamp", System.currentTimeMillis())
                }

                WidgetType.AGGREGATE -> {
                    val field = widget.field ?: ""
                    val query =
                        InfluxQlBuilder.buildAggregateQuery(
                            measurement = widget.measurement,
                            field = field,
                            timeRange = widget.timeRange ?: "24h",
                            tagFilters = widget.tagFilters,
                        )
                    val json = httpClient.query(conn, token, query)
                    val aggMap = InfluxResponseParser.parseAggregate(json)
                    val aggObj = JSONObject()
                    aggMap.forEach { (k, v) -> aggObj.put(k, v) }
                    cacheObj.put("aggregates", aggObj)
                    cacheObj.put("timestamp", System.currentTimeMillis())
                }

                WidgetType.MULTI_VALUE -> {
                    val fields =
                        widget.items?.map { it.field }?.filter { it.isNotEmpty() }
                            ?: listOfNotNull(widget.field)
                    val query =
                        InfluxQlBuilder.buildMultiValueQuery(
                            measurement = widget.measurement,
                            fields = fields,
                            tagFilters = widget.tagFilters,
                        )
                    val json = httpClient.query(conn, token, query)
                    val multiMap = InfluxResponseParser.parseMultiValues(json, fields)
                    val multiObj = JSONObject()
                    multiMap.forEach { (f, dp) ->
                        val itemObj =
                            JSONObject().apply {
                                put("value", dp.value)
                                put("timestamp", dp.timestamp)
                            }
                        multiObj.put(f, itemObj)
                    }
                    cacheObj.put("values", multiObj)
                    cacheObj.put("timestamp", System.currentTimeMillis())
                }
            }

            return cacheObj.toString()
        }

        fun enqueuePeriodicWork(context: Context) {
            val periodicRequest =
                PeriodicWorkRequestBuilder<WidgetRefreshWorker>(
                    15,
                    TimeUnit.MINUTES,
                ).addTag(TAG).build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME_PERIODIC,
                ExistingPeriodicWorkPolicy.KEEP,
                periodicRequest,
            )
        }

        fun enqueueOneTimeWork(
            context: Context,
            targetWidgetId: String? = null,
        ) {
            val builder = OneTimeWorkRequestBuilder<WidgetRefreshWorker>().addTag(TAG)
            if (targetWidgetId != null) {
                builder.setInputData(Data.Builder().putString(KEY_WIDGET_ID, targetWidgetId).build())
            }
            WorkManager.getInstance(context).enqueue(builder.build())
        }
    }
}
