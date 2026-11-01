import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/domain/formula/formula_exception.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/domain/services/formula_calculation_service.dart';

class MockHttpClient extends Mock implements http.Client {}

const _connection = InfluxConnection(
  id: 'c',
  name: 'x',
  url: 'https://influx.example.com:8086',
  database: 'db',
);

http.Response _series(
  List<String> columns,
  List<List<Object?>> rows, {
  String name = 'sen66',
}) => http.Response(
  json.encode({
    'results': [
      {
        'statement_id': 0,
        'series': [
          {'name': name, 'columns': columns, 'values': rows},
        ],
      },
    ],
  }),
  200,
);

const _ratio = WidgetDefinition(
  id: 'w',
  type: WidgetType.historyChart,
  title: 'ratio',
  connectionId: 'c',
  measurement: 'sen66',
  formula: 'a / b',
  formulaVariables: [
    FormulaVariable(name: 'a', field: 'a'),
    FormulaVariable(name: 'b', field: 'b'),
  ],
);

void main() {
  setUpAll(() => registerFallbackValue(Uri.parse('https://example.com')));

  late MockHttpClient client;
  late FormulaCalculationService service;

  setUp(() {
    client = MockHttpClient();
    service = FormulaCalculationService(
      apiClient: InfluxApiClient(httpClient: client),
    );
  });

  void answer(List<http.Response> responses) {
    var i = 0;
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => responses[i++ % responses.length]);
  }

  WidgetDefinition iaq({String? gapPolicy, WidgetType? type}) =>
      WidgetDefinition(
        id: 'w',
        type: type ?? WidgetType.historyChart,
        title: 'IAQ',
        connectionId: 'c',
        measurement: 'sen66',
        timeRange: '24h',
        aggregationInterval: '1h',
        formula: 'min(vocIdx, co2Idx)',
        formulaVariables: const [
          FormulaVariable(name: 'v', field: 'voc'),
          FormulaVariable(name: 'c', field: 'co2'),
        ],
        formulaSteps: const [
          FormulaStep(name: 'vocIdx', expression: '100 - v * 0.6'),
          FormulaStep(
            name: 'co2Idx',
            expression: 'clamp(100 - (c - 400) / 10, 0, 100)',
          ),
        ],
        gapPolicy: gapPolicy,
      );

  final rows = <List<Object?>>[
    [1000, null, 800], // no voc yet
    [2000, 100.0, 900], // vocIdx 40, co2Idx 50 -> 40
    [3000, 50.0, null], // co2 missing
    [4000, 0.0, 400], // 100, 100 -> 100
  ];

  group('FormulaCalculationService.calculateSeries', () {
    test('computes IAQ per bucket and skips incomplete buckets', () async {
      answer([
        _series(['time', 'voc', 'co2'], rows),
      ]);

      final result = await service.calculateSeries(
        widget: iaq(),
        connection: _connection,
        token: 't',
      );

      expect(result.points.map((p) => p.value), [40.0, 100.0]);
      expect(result.points.map((p) => p.timestamp.millisecondsSinceEpoch), [
        2000,
        4000,
      ]);
      expect(result.errors, isEmpty);
    });

    test('previous policy carries the last value forward', () async {
      answer([
        _series(['time', 'voc', 'co2'], rows),
      ]);

      final result = await service.calculateSeries(
        widget: iaq(gapPolicy: 'previous'),
        connection: _connection,
        token: 't',
      );

      // bucket 1000 is still skipped (no voc yet); 3000 reuses co2 = 900.
      expect(result.points.map((p) => p.value), [40.0, 50.0, 100.0]);
    });

    test(
      'records division by zero per bucket and keeps good buckets',
      () async {
        answer([
          _series(
            ['time', 'a', 'b'],
            [
              [1000, 10.0, 2.0],
              [2000, 10.0, 0.0],
              [3000, 9.0, 3.0],
            ],
          ),
        ]);

        final result = await service.calculateSeries(
          widget: _ratio,
          connection: _connection,
          token: 't',
        );

        expect(result.points.map((p) => p.value), [5.0, 3.0]);
        expect(result.errors, hasLength(1));
        expect(result.errors.single.exception, isA<DivisionByZeroException>());
        expect(result.errors.single.timestamp.millisecondsSinceEpoch, 2000);
      },
    );

    test('throws the bucket error when every bucket fails', () {
      answer([
        _series(
          ['time', 'a', 'b'],
          [
            [1000, 10.0, 0.0],
          ],
        ),
      ]);

      expect(
        () => service.calculateSeries(
          widget: _ratio,
          connection: _connection,
          token: 't',
        ),
        throwsA(isA<DivisionByZeroException>()),
      );
    });

    test('throws MissingVariableException when a variable has no data', () {
      answer([
        _series(
          ['time', 'voc', 'co2'],
          [
            [1000, 10.0, null],
          ],
        ),
      ]);

      expect(
        () => service.calculateSeries(
          widget: iaq(),
          connection: _connection,
          token: 't',
        ),
        throwsA(
          isA<MissingVariableException>().having(
            (e) => e.variableName,
            'variableName',
            'c',
          ),
        ),
      );
    });

    test('combines variables from different measurements by bucket', () async {
      answer([
        _series(
          ['time', 'voc'],
          [
            [1000, 10.0],
            [2000, 20.0],
          ],
        ),
        _series(
          ['time', 'temp'],
          [
            [2000, 5.0],
            [3000, 6.0],
          ],
          name: 'outdoor',
        ),
      ]);
      const widget = WidgetDefinition(
        id: 'w',
        type: WidgetType.historyChart,
        title: 'sum',
        connectionId: 'c',
        measurement: 'sen66',
        formula: 'a + b',
        formulaVariables: [
          FormulaVariable(name: 'a', field: 'voc'),
          FormulaVariable(name: 'b', field: 'temp', measurement: 'outdoor'),
        ],
      );

      final result = await service.calculateSeries(
        widget: widget,
        connection: _connection,
        token: 't',
      );

      expect(result.points.map((p) => p.value), [25.0]);
    });
  });

  group('FormulaCalculationService.calculateAggregate', () {
    test('applies the formula per bucket before min/max/mean', () async {
      answer([
        _series(['time', 'voc', 'co2'], rows),
      ]);

      final agg = await service.calculateAggregate(
        widget: iaq(type: WidgetType.aggregate),
        connection: _connection,
        token: 't',
      );

      expect(agg['min'], 40.0);
      expect(agg['max'], 100.0);
      expect(agg['mean'], 70.0);
    });
  });
}
