package io.github.sphaerox.influx_sensor_widgets.worker

import android.content.Context
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.Data
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import io.github.sphaerox.influx_sensor_widgets.R
import io.github.sphaerox.influx_sensor_widgets.alerts.AlertEvaluator
import io.github.sphaerox.influx_sensor_widgets.alerts.AlertHit
import io.github.sphaerox.influx_sensor_widgets.alerts.AlertNotifier
import io.github.sphaerox.influx_sensor_widgets.formula.FormulaEvaluator
import io.github.sphaerox.influx_sensor_widgets.formula.FormulaException
import io.github.sphaerox.influx_sensor_widgets.formula.FormulaSeriesCalculator
import io.github.sphaerox.influx_sensor_widgets.formula.MissingVariableException
import io.github.sphaerox.influx_sensor_widgets.glance.SensorGlanceAppWidget
import io.github.sphaerox.influx_sensor_widgets.influx.InfluxHttpClient
import io.github.sphaerox.influx_sensor_widgets.influx.InfluxNetworkException
import io.github.sphaerox.influx_sensor_widgets.influx.InfluxQlBuilder
import io.github.sphaerox.influx_sensor_widgets.influx.InfluxResponseParser
import io.github.sphaerox.influx_sensor_widgets.l10n.WidgetTexts
import io.github.sphaerox.influx_sensor_widgets.l10n.formulaError
import io.github.sphaerox.influx_sensor_widgets.model.WidgetDefinition
import io.github.sphaerox.influx_sensor_widgets.model.WidgetType
import io.github.sphaerox.influx_sensor_widgets.storage.WidgetStorageReader
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

        val outcome =
            WidgetRefreshRunner.run(
                refresh = {
                    refreshWidgetsOrThrowOnNetworkFailure(
                        storageReader,
                        httpClient,
                        WidgetTexts.of(applicationContext),
                        targetId,
                        onAlert = { widget, hit -> AlertNotifier.notify(applicationContext, widget, hit) },
                    )
                },
                notifyWidgets = { SensorGlanceAppWidget.refreshAll(applicationContext) },
            )
        return if (outcome == WidgetRefreshRunner.Outcome.SUCCESS) Result.success() else Result.retry()
    }

    companion object {
        const val TAG = "WidgetRefreshWorker"
        const val WORK_NAME_PERIODIC = "sensor_widgets_periodic_refresh"
        const val KEY_WIDGET_ID = "target_widget_id"

        /** Like [refreshWidgets], but throws [TransientRefreshException] when a server was unreachable. */
        fun refreshWidgetsOrThrowOnNetworkFailure(
            storageReader: WidgetStorageReader,
            httpClient: InfluxHttpClient,
            texts: WidgetTexts,
            targetWidgetId: String? = null,
            nowMillis: () -> Long = System::currentTimeMillis,
            onAlert: (WidgetDefinition, AlertHit) -> Unit = { _, _ -> },
        ): Int {
            var networkFailed = false
            val count =
                refreshWidgets(
                    storageReader,
                    httpClient,
                    texts,
                    targetWidgetId,
                    nowMillis,
                    onNetworkFailure = { networkFailed = true },
                    onAlert = onAlert,
                )
            if (networkFailed) throw TransientRefreshException()
            return count
        }

        /** Refreshes the caches; error texts are in the language of [texts]. */
        fun refreshWidgets(
            storageReader: WidgetStorageReader,
            httpClient: InfluxHttpClient,
            texts: WidgetTexts,
            targetWidgetId: String? = null,
            nowMillis: () -> Long = System::currentTimeMillis,
            onNetworkFailure: () -> Unit = {},
            onAlert: (WidgetDefinition, AlertHit) -> Unit = { _, _ -> },
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
                            put("error", texts.get(R.string.error_connection_not_found))
                            put("timestamp", System.currentTimeMillis())
                        }
                    storageReader.saveWidgetCache(widget.id, errJson.toString())
                    continue
                }

                val token = storageReader.getToken(conn.id)
                if (token.isNullOrEmpty()) {
                    val errJson =
                        JSONObject().apply {
                            put("error", texts.get(R.string.error_token_missing))
                            put("timestamp", System.currentTimeMillis())
                        }
                    storageReader.saveWidgetCache(widget.id, errJson.toString())
                    continue
                }

                try {
                    val cacheJson = executeQueryAndBuildCache(widget, conn, token, httpClient, texts)
                    storageReader.saveWidgetCache(widget.id, cacheJson)
                    checkAlerts(storageReader, widget, cacheJson, onAlert)
                } catch (e: InfluxNetworkException) {
                    onNetworkFailure()
                    val graced =
                        NetworkErrorGrace.cacheAfterNetworkError(
                            previousCacheJson = storageReader.getWidgetCache(widget.id),
                            errorMessage = e.message ?: texts.get(R.string.error_network),
                            nowMillis = nowMillis(),
                        )
                    storageReader.saveWidgetCache(widget.id, graced)
                } catch (e: Exception) {
                    val message =
                        if (e is FormulaException) texts.formulaError(e) else e.message ?: texts.get(R.string.error_query)
                    val errJson =
                        JSONObject().apply {
                            put("error", message)
                            put("timestamp", System.currentTimeMillis())
                        }
                    storageReader.saveWidgetCache(widget.id, errJson.toString())
                }
            }

            return widgetsToRefresh.size
        }

        private fun executeQueryAndBuildCache(
            widget: WidgetDefinition,
            conn: io.github.sphaerox.influx_sensor_widgets.model.InfluxConnection,
            token: String,
            httpClient: InfluxHttpClient,
            texts: WidgetTexts,
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
                            cacheObj.put("error", texts.get(R.string.error_no_data))
                            cacheObj.put("timestamp", System.currentTimeMillis())
                        }
                    }
                }

                WidgetType.HISTORY_CHART -> {
                    if (hasFormula(widget)) {
                        val series = FormulaSeriesCalculator.calculateSeries(widget, conn, token, httpClient)
                        val pointsArr = JSONArray()
                        for (p in series.points) {
                            pointsArr.put(JSONObject().apply { put("t", p.timestamp).put("v", p.value) })
                        }
                        cacheObj.put("points", pointsArr)
                        FormulaSeriesCalculator.summarizeErrors(series.errors, texts)?.let { cacheObj.put("warning", it) }
                        cacheObj.put("timestamp", System.currentTimeMillis())
                        return cacheObj.toString()
                    }
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
                    if (hasFormula(widget)) {
                        val series = FormulaSeriesCalculator.calculateSeries(widget, conn, token, httpClient)
                        val aggObj = JSONObject()
                        FormulaSeriesCalculator.aggregate(series, widget).forEach { (k, v) -> aggObj.put(k, v) }
                        cacheObj.put("aggregates", aggObj)
                        FormulaSeriesCalculator.summarizeErrors(series.errors, texts)?.let { cacheObj.put("warning", it) }
                        cacheObj.put("timestamp", System.currentTimeMillis())
                        return cacheObj.toString()
                    }
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
                    val items = widget.items.orEmpty()
                    val plainFields =
                        items.filter { it.formula.isNullOrBlank() }.map { it.field }.filter { it.isNotEmpty() } +
                            if (items.isEmpty()) listOfNotNull(widget.field) else emptyList()
                    val multiObj = JSONObject()
                    if (plainFields.isNotEmpty()) {
                        val query =
                            InfluxQlBuilder.buildMultiValueQuery(
                                measurement = widget.measurement,
                                fields = plainFields,
                                tagFilters = widget.tagFilters,
                            )
                        val json = httpClient.query(conn, token, query)
                        InfluxResponseParser.parseMultiValues(json, plainFields).forEach { (f, dp) ->
                            multiObj.put(f, JSONObject().apply { put("value", dp.value).put("timestamp", dp.timestamp) })
                        }
                    }
                    val rowErrors = JSONObject()
                    for (item in items.filter { !it.formula.isNullOrBlank() }) {
                        try {
                            val value = FormulaSeriesCalculator.calculateItemLatest(widget, item, conn, token, httpClient)
                            multiObj.put(
                                item.field,
                                JSONObject().apply { put("value", value).put("timestamp", System.currentTimeMillis()) },
                            )
                        } catch (e: FormulaException) {
                            rowErrors.put(item.field, texts.formulaError(e))
                        }
                    }
                    cacheObj.put("values", multiObj)
                    if (rowErrors.length() > 0) cacheObj.put("valueErrors", rowErrors)
                    cacheObj.put("timestamp", System.currentTimeMillis())
                }
            }

            return cacheObj.toString()
        }

        private fun checkAlerts(
            storageReader: WidgetStorageReader,
            widget: WidgetDefinition,
            cacheJson: String,
            onAlert: (WidgetDefinition, AlertHit) -> Unit,
        ) {
            val rules = widget.alerts.orEmpty()
            val previous = AlertEvaluator.decodeState(storageReader.getAlertState(widget.id))
            if (rules.isEmpty() && previous.isEmpty()) return
            val result = AlertEvaluator.evaluate(rules, cacheJson, previous)
            storageReader.saveAlertState(widget.id, AlertEvaluator.encodeState(result.active))
            result.triggered.forEach { onAlert(widget, it) }
        }

        private fun hasFormula(widget: WidgetDefinition): Boolean =
            !widget.formula.isNullOrBlank() && !widget.formulaVariables.isNullOrEmpty()

        /** Refreshes wait for a connection instead of failing right after a Doze wake-up. */
        fun refreshConstraints(): Constraints = Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()

        fun enqueuePeriodicWork(context: Context) {
            val periodicRequest =
                PeriodicWorkRequestBuilder<WidgetRefreshWorker>(
                    15,
                    TimeUnit.MINUTES,
                ).addTag(TAG)
                    .setConstraints(refreshConstraints())
                    .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME_PERIODIC,
                ExistingPeriodicWorkPolicy.KEEP,
                periodicRequest,
            )
        }

        fun cancelPeriodicWork(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME_PERIODIC)
        }

        fun enqueueOneTimeWork(
            context: Context,
            targetWidgetId: String? = null,
        ) {
            val builder = OneTimeWorkRequestBuilder<WidgetRefreshWorker>().addTag(TAG).setConstraints(refreshConstraints())
            if (targetWidgetId != null) {
                builder.setInputData(Data.Builder().putString(KEY_WIDGET_ID, targetWidgetId).build())
            }
            WorkManager.getInstance(context).enqueue(builder.build())
        }
    }
}
