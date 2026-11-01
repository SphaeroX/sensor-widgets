import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/domain/formula/formula_exception.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/domain/services/formula_calculation_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  group('FormulaCalculationService', () {
    late MockHttpClient mockClient;
    late InfluxApiClient apiClient;
    late FormulaCalculationService calculationService;

    const connection = InfluxConnection(
      id: 'conn-1',
      name: 'Test Influx',
      url: 'https://influx.example.com:8086',
      database: 'test_db',
    );
    const token = 'my-token';

    setUp(() {
      mockClient = MockHttpClient();
      apiClient = InfluxApiClient(httpClient: mockClient);
      calculationService = FormulaCalculationService(apiClient: apiClient);
    });

    test('calculates formula with multiple variables from same measurement in single query', () async {
      const widget = WidgetDefinition(
        id: 'w-1',
        type: WidgetType.singleValue,
        title: 'Avg Temp',
        connectionId: 'conn-1',
        measurement: 'sensors',
        formula: '(A + B) / 2',
        formulaVariables: [
          FormulaVariable(name: 'A', field: 'temp_in'),
          FormulaVariable(name: 'B', field: 'temp_out'),
        ],
      );

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
            (_) async => http.Response(
              json.encode({
                'results': [
                  {
                    'statement_id': 0,
                    'series': [
                      {
                        'name': 'sensors',
                        'columns': ['time', 'temp_in', 'temp_out'],
                        'values': [
                          [1730370000000, 24.0, 16.0],
                        ],
                      },
                    ],
                  },
                ],
              }),
              200,
            ),
          );

      final result = await calculationService.calculateFormula(
        widget: widget,
        connection: connection,
        token: token,
      );

      expect(result, 20.0);
    });

    test('rounds average calculations to max 2 decimals without floating point artifacts', () async {
      const widget = WidgetDefinition(
        id: 'w-avg',
        type: WidgetType.singleValue,
        title: 'Average Calc',
        connectionId: 'conn-1',
        measurement: 'sensors',
        formula: '(A + B) / 2',
        formulaVariables: [
          FormulaVariable(name: 'A', field: 'valA'),
          FormulaVariable(name: 'B', field: 'valB'),
        ],
      );

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
            (_) async => http.Response(
              jsonEncode({
                'results': [
                  {
                    'statement_id': 0,
                    'series': [
                      {
                        'name': 'sensors',
                        'columns': ['time', 'valA', 'valB'],
                        'values': [
                          [1730370000000, 10.1, 20.2],
                        ],
                      },
                    ],
                  },
                ],
              }),
              200,
            ),
          );

      final result = await calculationService.calculateFormula(
        widget: widget,
        connection: connection,
        token: token,
      );

      // (10.1 + 20.2) / 2 produces 15.150000000000002 in unrounded double
      // Must be cleanly rounded to 15.15
      expect(result, 15.15);
    });

    test(
      'calculates formula with variables from different measurements / tags',
      () async {
        const widget = WidgetDefinition(
          id: 'w-2',
          type: WidgetType.singleValue,
          title: 'Diff Temp',
          connectionId: 'conn-1',
          measurement: 'sensors_in',
          formula: 'A - B',
          formulaVariables: [
            FormulaVariable(name: 'A', field: 'temp'),
            FormulaVariable(
              name: 'B',
              field: 'temp',
              measurement: 'sensors_out',
              tagFilters: {'area': 'patio'},
            ),
          ],
        );

        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((invocation) async {
              final uri = invocation.positionalArguments.first as Uri;
              final q = uri.queryParameters['q'] ?? '';

              if (q.contains('sensors_in')) {
                return http.Response(
                  json.encode({
                    'results': [
                      {
                        'statement_id': 0,
                        'series': [
                          {
                            'name': 'sensors_in',
                            'columns': ['time', 'temp'],
                            'values': [
                              [1730370000000, 25.5],
                            ],
                          },
                        ],
                      },
                    ],
                  }),
                  200,
                );
              } else {
                return http.Response(
                  json.encode({
                    'results': [
                      {
                        'statement_id': 0,
                        'series': [
                          {
                            'name': 'sensors_out',
                            'columns': ['time', 'temp'],
                            'values': [
                              [1730370000000, 15.0],
                            ],
                          },
                        ],
                      },
                    ],
                  }),
                  200,
                );
              }
            });

        final result = await calculationService.calculateFormula(
          widget: widget,
          connection: connection,
          token: token,
        );

        expect(result, 10.5);
      },
    );

    test(
      'throws MissingVariableException when a variable cannot be queried',
      () async {
        const widget = WidgetDefinition(
          id: 'w-3',
          type: WidgetType.singleValue,
          title: 'Calc',
          connectionId: 'conn-1',
          measurement: 'sensors',
          formula: 'A + B',
          formulaVariables: [
            FormulaVariable(name: 'A', field: 'temp_in'),
            FormulaVariable(name: 'B', field: 'temp_out'),
          ],
        );

        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer(
              (_) async => http.Response(
                json.encode({
                  'results': [
                    {
                      'statement_id': 0,
                      'series': [
                        {
                          'name': 'sensors',
                          'columns': ['time', 'temp_in'],
                          'values': [
                            [1730370000000, 20.0],
                          ],
                        },
                      ],
                    },
                  ],
                }),
                200,
              ),
            );

        expect(
          () => calculationService.calculateFormula(
            widget: widget,
            connection: connection,
            token: token,
          ),
          throwsA(isA<MissingVariableException>()),
        );
      },
    );

    test(
      'throws DivisionByZeroException when calculated result divides by 0',
      () async {
        const widget = WidgetDefinition(
          id: 'w-4',
          type: WidgetType.singleValue,
          title: 'DivZero',
          connectionId: 'conn-1',
          measurement: 'sensors',
          formula: 'A / B',
          formulaVariables: [
            FormulaVariable(name: 'A', field: 'val1'),
            FormulaVariable(name: 'B', field: 'val2'),
          ],
        );

        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer(
              (_) async => http.Response(
                json.encode({
                  'results': [
                    {
                      'statement_id': 0,
                      'series': [
                        {
                          'name': 'sensors',
                          'columns': ['time', 'val1', 'val2'],
                          'values': [
                            [1730370000000, 10.0, 0.0],
                          ],
                        },
                      ],
                    },
                  ],
                }),
                200,
              ),
            );

        expect(
          () => calculationService.calculateFormula(
            widget: widget,
            connection: connection,
            token: token,
          ),
          throwsA(isA<DivisionByZeroException>()),
        );
      },
    );
  });
}
