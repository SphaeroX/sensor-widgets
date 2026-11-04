import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/core/constants/storage_keys.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';

void main() {
  group('Cross-Platform Schema & Storage Contract Tests', () {
    test('StorageKeys constants match specification across all platforms', () {
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

      expect(StorageKeys.tokenKey('abc'), 'influx_token_abc');
      expect(StorageKeys.cacheKey('xyz'), 'widget_cache_xyz');
    });

    test('Kotlin WidgetStorageReader contains exact matching storage keys', () {
      final kotlinFile = File(
        'android/app/src/main/kotlin/io/github/sphaerox/influx_sensor_widgets/storage/WidgetStorageReader.kt',
      );
      expect(kotlinFile.existsSync(), isTrue);

      final content = kotlinFile.readAsStringSync();
      expect(content.contains('sensor_widgets_prefs'), isTrue);
      expect(content.contains('widget_definitions_v1'), isTrue);
      expect(content.contains('connections_metadata_v1'), isTrue);
      expect(content.contains('influx_token_'), isTrue);
      expect(content.contains('widget_cache_'), isTrue);
    });

    test('Swift SharedGroupStorage contains exact matching storage keys', () {
      final swiftFile = File(
        'ios/SensorWidgetsExtension/Storage/SharedGroupStorage.swift',
      );
      expect(swiftFile.existsSync(), isTrue);

      final content = swiftFile.readAsStringSync();
      expect(
        content.contains('group.io.github.mgasc.influx_sensor_widgets'),
        isTrue,
      );
      expect(content.contains('widget_definitions_v1'), isTrue);
      expect(content.contains('connections_metadata_v1'), isTrue);
      expect(content.contains('influx_token_'), isTrue);
      expect(content.contains('widget_cache_'), isTrue);
    });

    test('Android package matches the Play application ID', () {
      const package = 'io.github.sphaerox.influx_sensor_widgets';
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('namespace = "$package"'));
      expect(gradle, contains('applicationId = "$package"'));
    });

    test('Android class names referenced outside Kotlin exist', () {
      final references = [
        RegExp(r"qualifiedAndroidName:\s*'([\w.]+)'").firstMatch(
          File('lib/data/storage/shared_widget_store.dart').readAsStringSync(),
        ),
        RegExp(r'android:configure="([\w.]+)"').firstMatch(
          File('android/app/src/main/res/xml/sensor_widget_info.xml')
              .readAsStringSync(),
        ),
      ];

      for (final match in references) {
        expect(match, isNotNull);
        final path = match!.group(1)!.replaceAll('.', '/');
        expect(
          File('android/app/src/main/kotlin/$path.kt').existsSync(),
          isTrue,
          reason: '${match.group(1)} has no Kotlin source',
        );
      }
    });

    test('All 6 widget types have exact matching string representations', () {
      final expectedTypes = {
        'single_value': WidgetType.singleValue,
        'history_chart': WidgetType.historyChart,
        'indicator_lamp': WidgetType.indicatorLamp,
        'multi_value': WidgetType.multiValue,
        'aggregate': WidgetType.aggregate,
        'gauge_bar': WidgetType.gaugeBar,
      };

      for (final entry in expectedTypes.entries) {
        expect(entry.value.wireName, entry.key);
      }
    });

    test('Fixtures widget_definitions_v1.json parses and round-trips without field loss', () {
      final fixtureFile = File(
        'fixtures/widget_definitions/widget_definitions_v1.json',
      );
      expect(fixtureFile.existsSync(), isTrue);

      final jsonStr = fixtureFile.readAsStringSync();
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawWidgets = map['widgets'] as List<dynamic>;

      expect(rawWidgets.length, 6);
      for (final raw in rawWidgets) {
        final widget = WidgetDefinition.fromJson(raw as Map<String, dynamic>);
        final roundTrip = widget.toJson();

        expect(roundTrip['id'], widget.id);
        expect(roundTrip['type'], widget.type.wireName);
        expect(roundTrip['title'], widget.title);
        expect(roundTrip['connectionId'], widget.connectionId);
        expect(roundTrip['measurement'], widget.measurement);
      }
    });
  });
}
