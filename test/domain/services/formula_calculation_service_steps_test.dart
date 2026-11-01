import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/domain/services/formula_calculation_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() => registerFallbackValue(Uri.parse('https://example.com')));

  test('calculateFormula evaluates formulaSteps and min() over them', () async {
    final client = MockHttpClient();
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        json.encode({
          'results': [
            {
              'statement_id': 0,
              'series': [
                {
                  'name': 'sen66',
                  'columns': ['time', 'voc', 'co2'],
                  'values': [
                    [1730370000000, 100.0, 900.0],
                  ],
                },
              ],
            },
          ],
        }),
        200,
      ),
    );
    final service = FormulaCalculationService(
      apiClient: InfluxApiClient(httpClient: client),
    );
    const widget = WidgetDefinition(
      id: 'w-1',
      type: WidgetType.singleValue,
      title: 'IAQ',
      connectionId: 'c-1',
      measurement: 'sen66',
      formula: 'min(a, b)',
      formulaVariables: [
        FormulaVariable(name: 'v', field: 'voc'),
        FormulaVariable(name: 'c', field: 'co2'),
      ],
      formulaSteps: [
        FormulaStep(name: 'a', expression: '100 - v * 0.6'),
        FormulaStep(
          name: 'b',
          expression: 'clamp(100 - (c - 400) / 10, 0, 100)',
        ),
      ],
    );

    final result = await service.calculateFormula(
      widget: widget,
      connection: const InfluxConnection(
        id: 'c-1',
        name: 'x',
        url: 'https://influx.example.com:8086',
        database: 'db',
      ),
      token: 'tok',
    );

    expect(result, 40.0);
  });
}
