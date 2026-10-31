/// Shared constants for storage keys across Flutter, Android, and iOS.
class StorageKeys {
  StorageKeys._();

  /// Current JSON contract schema version.
  static const int schemaVersion = 1;

  /// Apple App Group ID shared between Flutter app and WidgetKit extension.
  static const String appGroupId =
      'group.io.github.mgasc.influx_sensor_widgets';

  /// Android SharedPreferences file name.
  static const String androidPreferencesName = 'sensor_widgets_prefs';

  /// Key under which all widget configurations are persisted as JSON.
  static const String widgetDefinitionsKey = 'widget_definitions_v1';

  /// Key under which connection metadata (excluding sensitive tokens) is persisted.
  static const String connectionsMetadataKey = 'connections_metadata_v1';

  /// Key prefix for secure storage of InfluxDB tokens.
  static const String tokenKeyPrefix = 'influx_token_';

  /// Key prefix for shared widget cache data.
  static const String cacheKeyPrefix = 'widget_cache_';

  /// Generates the storage key for a connection's secure token.
  static String tokenKey(String connectionId) => '$tokenKeyPrefix$connectionId';

  /// Generates the cache key for a widget's cached sensor data.
  static String cacheKey(String widgetId) => '$cacheKeyPrefix$widgetId';
}
