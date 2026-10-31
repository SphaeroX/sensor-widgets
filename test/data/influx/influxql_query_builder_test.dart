import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/data/influx/influxql_query_builder.dart';

void main() {
  group('InfluxQlQueryBuilder', () {
    const builder = InfluxQlQueryBuilder();

    test('builds single value query without tag filters', () {
      final query = builder.buildSingleValueQuery(
        measurement: 'temperature',
        field: 'value',
      );
      expect(
        query,
        'SELECT "value" FROM "temperature" ORDER BY time DESC LIMIT 1',
      );
    });

    test('builds single value query with tag filters and escaping', () {
      final query = builder.buildSingleValueQuery(
        measurement: 'temp"erature',
        field: 'val"ue',
        tagFilters: {'ro\'om': "living'room", 'device': 'sensor1'},
      );
      expect(
        query,
        'SELECT "val\\"ue" FROM "temp\\"erature" WHERE "device" = \'sensor1\' AND "ro\'om" = \'living\\\'room\' ORDER BY time DESC LIMIT 1',
      );
    });

    test('builds history query with group by and time range', () {
      final query = builder.buildHistoryQuery(
        measurement: 'temperature',
        field: 'value',
        timeRange: '24h',
        bucketInterval: '1h',
        tagFilters: {'room': 'living_room'},
      );
      expect(
        query,
        'SELECT MEAN("value") AS "mean" FROM "temperature" WHERE time > now() - 24h AND "room" = \'living_room\' GROUP BY time(1h) fill(none)',
      );
    });

    test('builds aggregate query with min, max, mean', () {
      final query = builder.buildAggregateQuery(
        measurement: 'power',
        field: 'watts',
        timeRange: '24h',
        tagFilters: {'device': 'main_grid'},
      );
      expect(
        query,
        'SELECT MIN("watts") AS "min", MAX("watts") AS "max", MEAN("watts") AS "mean" FROM "power" WHERE time > now() - 24h AND "device" = \'main_grid\'',
      );
    });

    test('builds multi-value query', () {
      final query = builder.buildMultiValueQuery(
        measurement: 'climate',
        fields: ['temperature', 'humidity', 'co2'],
        tagFilters: {'room': 'office'},
      );
      expect(
        query,
        'SELECT "temperature", "humidity", "co2" FROM "climate" WHERE "room" = \'office\' ORDER BY time DESC LIMIT 1',
      );
    });

    test('builds schema discovery queries', () {
      expect(builder.buildShowMeasurementsQuery(), 'SHOW MEASUREMENTS');
      expect(
        builder.buildShowFieldKeysQuery('climate'),
        'SHOW FIELD KEYS FROM "climate"',
      );
      expect(
        builder.buildShowTagKeysQuery('climate'),
        'SHOW TAG KEYS FROM "climate"',
      );
      expect(
        builder.buildShowTagValuesQuery('climate', 'room'),
        'SHOW TAG VALUES FROM "climate" WITH KEY = "room"',
      );
    });
  });
}
