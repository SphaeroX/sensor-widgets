import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/core/constants/storage_keys.dart';

void main() {
  group('StorageKeys', () {
    test('constants have expected values', () {
      expect(StorageKeys.schemaVersion, 1);
      expect(
        StorageKeys.appGroupId,
        'group.io.github.mgasc.influx_sensor_widgets',
      );
      expect(StorageKeys.androidPreferencesName, 'sensor_widgets_prefs');
      expect(StorageKeys.widgetDefinitionsKey, 'widget_definitions_v1');
      expect(StorageKeys.connectionsMetadataKey, 'connections_metadata_v1');
      expect(StorageKeys.tokenKeyPrefix, 'influx_token_');
      expect(StorageKeys.cacheKeyPrefix, 'widget_cache_');
    });

    test('tokenKey helper generates correct key', () {
      expect(StorageKeys.tokenKey('conn-123'), 'influx_token_conn-123');
    });

    test('cacheKey helper generates correct key', () {
      expect(StorageKeys.cacheKey('widget-456'), 'widget_cache_widget-456');
    });
  });
}
