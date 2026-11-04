package io.github.sphaerox.influx_sensor_widgets.storage

import android.content.Context
import io.github.sphaerox.influx_sensor_widgets.model.InfluxConnection
import io.github.sphaerox.influx_sensor_widgets.model.WidgetDefinition
import io.github.sphaerox.influx_sensor_widgets.model.WidgetDefinitionParser
import org.json.JSONArray

class WidgetStorageReader(
    private val prefsGetter: (String) -> String?,
    private val prefsSetter: (String, String) -> Unit,
    private val securePrefsGetter: (String) -> String?,
) {
    constructor(context: Context) : this(
        prefsGetter = { key ->
            val homeWidgetPrefs = context.getSharedPreferences(HOME_WIDGET_PREFS_NAME, Context.MODE_PRIVATE)
            homeWidgetPrefs.getString(key, null)
                ?: context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).getString(key, null)
        },
        prefsSetter = { key, value ->
            val homeWidgetPrefs = context.getSharedPreferences(HOME_WIDGET_PREFS_NAME, Context.MODE_PRIVATE)
            homeWidgetPrefs.edit().putString(key, value).apply()
            val legacyPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            legacyPrefs.edit().putString(key, value).apply()
        },
        securePrefsGetter = { key ->
            val homeWidgetPrefs = context.getSharedPreferences(HOME_WIDGET_PREFS_NAME, Context.MODE_PRIVATE)
            var token = homeWidgetPrefs.getString(key, null)
            if (token == null) {
                val legacyPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                token = legacyPrefs.getString(key, null)
            }
            if (token == null) {
                val securePrefs = context.getSharedPreferences(SECURE_PREFS_NAME, Context.MODE_PRIVATE)
                token = securePrefs.getString(key, null)
                    ?: securePrefs.getString("VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg_$key", null)
            }
            token
        },
    )

    fun getWidgetDefinitions(): List<WidgetDefinition> {
        val jsonStr = prefsGetter(KEY_WIDGET_DEFINITIONS) ?: return emptyList()
        return try {
            WidgetDefinitionParser.parseDefinitionsList(jsonStr)
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun getConnections(): List<InfluxConnection> {
        val jsonStr = prefsGetter(KEY_CONNECTIONS_METADATA) ?: return emptyList()
        return try {
            val array = JSONArray(jsonStr)
            val list = mutableListOf<InfluxConnection>()
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                list.add(
                    InfluxConnection(
                        id = obj.getString("id"),
                        name = obj.getString("name"),
                        url = obj.getString("url"),
                        database = obj.getString("database"),
                    ),
                )
            }
            list
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun getToken(connectionId: String): String? {
        val key = "$KEY_TOKEN_PREFIX$connectionId"
        return securePrefsGetter(key) ?: prefsGetter(key)
    }

    fun saveWidgetCache(
        widgetId: String,
        cacheJson: String,
    ) {
        val key = "$KEY_CACHE_PREFIX$widgetId"
        prefsSetter(key, cacheJson)
    }

    fun getAlertState(widgetId: String): String? = prefsGetter("$KEY_ALERT_STATE_PREFIX$widgetId")

    fun saveAlertState(
        widgetId: String,
        stateJson: String,
    ) = prefsSetter("$KEY_ALERT_STATE_PREFIX$widgetId", stateJson)

    fun getWidgetCache(widgetId: String): String? {
        val key = "$KEY_CACHE_PREFIX$widgetId"
        return prefsGetter(key)
    }

    companion object {
        const val HOME_WIDGET_PREFS_NAME = "HomeWidgetPreferences"
        const val PREFS_NAME = "sensor_widgets_prefs"
        const val SECURE_PREFS_NAME = "FlutterSecureStorage"
        const val KEY_WIDGET_DEFINITIONS = "widget_definitions_v1"
        const val KEY_CONNECTIONS_METADATA = "connections_metadata_v1"
        const val KEY_TOKEN_PREFIX = "influx_token_"
        const val KEY_CACHE_PREFIX = "widget_cache_"

        /** Native only: rules that matched on the last refresh (see AlertEvaluator). */
        const val KEY_ALERT_STATE_PREFIX = "widget_alert_state_"
    }
}
