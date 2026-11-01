import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/data/influx/influx_response_parser.dart';
import 'package:sensor_widgets/domain/errors/influx_exception.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';

void main() {
  group('InfluxResponseParser', () {
    const parser = InfluxResponseParser();

    Map<String, dynamic> loadFixture(String filename) {
      final file = File('fixtures/influx/$filename');
      return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    }

    test('parses single_value_response.json', () {
      final json = loadFixture('single_value_response.json');
      final point = parser.parseSingleValue(json, 'value');

      expect(point, isNotNull);
      expect(point!.value, 21.5);
      expect(point.field, 'value');
      expect(point.timestamp.millisecondsSinceEpoch, 1730370000000);
    });

    test('parses history_series_response.json', () {
      final json = loadFixture('history_series_response.json');
      final series = parser.parseTimeSeries(json, 'mean');

      expect(series.length, 6);
      expect(series.first.value, 19.8);
      expect(series.first.timestamp.millisecondsSinceEpoch, 1730352000000);
      expect(series.last.value, 21.5);
      expect(series.last.timestamp.millisecondsSinceEpoch, 1730370000000);
    });

    test('parses multi_series_room_response.json', () {
      final json = loadFixture('multi_series_room_response.json');
      final results = parser.parseMultiValues(json, [
        'temperature',
        'humidity',
        'co2',
      ]);

      expect(results.length, 3);
      expect(results['temperature']?.value, 22.3);
      expect(results['humidity']?.value, 48.5);
      expect(results['co2']?.value, 620.0);
    });

    test('parses aggregate_min_max_mean_response.json', () {
      final json = loadFixture('aggregate_min_max_mean_response.json');
      final agg = parser.parseAggregate(json);

      expect(agg['min'], 18.2);
      expect(agg['max'], 23.9);
      expect(agg['mean'], 21.1);
    });

    test('parses schema discovery fixtures', () {
      final measurements = parser.parseMeasurements(
        loadFixture('show_measurements_response.json'),
      );
      expect(measurements, ['climate', 'power', 'temperature']);

      final fieldKeys = parser.parseFieldKeys(
        loadFixture('show_field_keys_response.json'),
      );
      expect(fieldKeys, ['co2', 'humidity', 'pressure', 'temperature']);

      final fieldInfos = parser.parseFieldInfos(
        loadFixture('show_field_keys_response.json'),
      );
      expect(fieldInfos, [
        const InfluxFieldInfo(key: 'co2', type: 'float'),
        const InfluxFieldInfo(key: 'humidity', type: 'float'),
        const InfluxFieldInfo(key: 'pressure', type: 'float'),
        const InfluxFieldInfo(key: 'temperature', type: 'float'),
      ]);

      final tagKeys = parser.parseTagKeys(
        loadFixture('show_tag_keys_response.json'),
      );
      expect(tagKeys, ['building', 'device', 'room']);

      final tagValues = parser.parseTagValues(
        loadFixture('show_tag_values_response.json'),
      );
      expect(tagValues, ['bedroom', 'kitchen', 'living_room', 'office']);
    });

    test('parses empty_result_response.json safely', () {
      final json = loadFixture('empty_result_response.json');
      expect(parser.parseSingleValue(json, 'value'), isNull);
      expect(parser.parseTimeSeries(json, 'mean'), isEmpty);
      expect(parser.parseMultiValues(json, ['temp']), isEmpty);
      expect(parser.parseAggregate(json), isEmpty);
      expect(parser.parseMeasurements(json), isEmpty);
      expect(parser.parseFieldInfos(json), isEmpty);
    });

    test('parses mixed field types and missing type column safely', () {
      final responseWithMixed = {
        'results': [
          {
            'statement_id': 0,
            'series': [
              {
                'name': 'device_data',
                'columns': ['fieldKey', 'fieldType'],
                'values': [
                  ['temp', 'float'],
                  ['count', 'integer'],
                  ['mode', 'string'],
                  ['active', 'boolean'],
                ],
              },
            ],
          },
        ],
      };
      expect(parser.parseFieldInfos(responseWithMixed), [
        const InfluxFieldInfo(key: 'temp', type: 'float'),
        const InfluxFieldInfo(key: 'count', type: 'integer'),
        const InfluxFieldInfo(key: 'mode', type: 'string'),
        const InfluxFieldInfo(key: 'active', type: 'boolean'),
      ]);

      final responseWithoutTypeCol = {
        'results': [
          {
            'statement_id': 0,
            'series': [
              {
                'name': 'device_data',
                'columns': ['fieldKey'],
                'values': [
                  ['temp'],
                ],
              },
            ],
          },
        ],
      };
      expect(parser.parseFieldInfos(responseWithoutTypeCol), [
        const InfluxFieldInfo(key: 'temp', type: 'unknown'),
      ]);
    });

    test('throws InfluxQueryException on error_query_response.json', () {
      final json = loadFixture('error_query_response.json');
      expect(
        () => parser.parseSingleValue(json, 'value'),
        throwsA(isA<InfluxQueryException>()),
      );
    });
  });
}
