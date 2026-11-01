import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/data/influx/influx_response_parser.dart';
import 'package:sensor_widgets/data/influx/influxql_query_builder.dart';

void main() {
  const builder = InfluxQlQueryBuilder();
  const parser = InfluxResponseParser();

  group('InfluxQlQueryBuilder.buildBucketedMultiFieldQuery', () {
    test('builds MEAN per field with GROUP BY time and fill(null)', () {
      final q = builder.buildBucketedMultiFieldQuery(
        measurement: 'sen66',
        fields: ['voc', 'co2'],
        timeRange: '24h',
        bucketInterval: '1h',
      );
      expect(
        q,
        'SELECT MEAN("voc") AS "voc", MEAN("co2") AS "co2" FROM "sen66" '
        'WHERE time > now() - 24h GROUP BY time(1h) fill(null)',
      );
    });

    test('adds sorted tag filters', () {
      final q = builder.buildBucketedMultiFieldQuery(
        measurement: 'm',
        fields: ['a'],
        timeRange: '6h',
        bucketInterval: '10m',
        tagFilters: {'room': 'kitchen', 'floor': '1'},
      );
      expect(
        q,
        'SELECT MEAN("a") AS "a" FROM "m" WHERE time > now() - 6h AND '
        '"floor" = \'1\' AND "room" = \'kitchen\' GROUP BY time(10m) fill(null)',
      );
    });
  });

  group('InfluxResponseParser.parseBucketedFields', () {
    final json = {
      'results': [
        {
          'statement_id': 0,
          'series': [
            {
              'name': 'sen66',
              'columns': ['time', 'voc', 'co2'],
              'values': [
                [1000, 10.0, null],
                [2000, null, 5],
                [3000, 12.5, 6.5],
              ],
            },
          ],
        },
      ],
    };

    test('maps each field to its non-null buckets', () {
      final result = parser.parseBucketedFields(json, ['voc', 'co2']);
      expect(result['voc'], {1000: 10.0, 3000: 12.5});
      expect(result['co2'], {2000: 5.0, 3000: 6.5});
    });

    test('returns empty maps for an empty result', () {
      final result = parser.parseBucketedFields(
        {
          'results': [
            {'statement_id': 0},
          ],
        },
        ['voc'],
      );
      expect(result['voc'], isEmpty);
    });
  });
}
