import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/domain/errors/influx_exception.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  group('InfluxApiClient', () {
    late MockHttpClient mockClient;
    late InfluxApiClient apiClient;

    const connection = InfluxConnection(
      id: 'conn-1',
      name: 'Test Influx',
      url: 'https://influx.example.com:8086',
      database: 'test_db',
    );
    const token = 'my-secret-token-xyz';

    setUp(() {
      mockClient = MockHttpClient();
      apiClient = InfluxApiClient(httpClient: mockClient);
    });

    test('sends query with correct URL parameters and Token header', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
            (_) async => http.Response(
              json.encode({
                'results': [
                  {
                    'statement_id': 0,
                    'series': [
                      {
                        'name': 'm',
                        'columns': ['time', 'value'],
                        'values': [
                          [1730370000000, 42.0],
                        ],
                      },
                    ],
                  },
                ],
              }),
              200,
            ),
          );

      final result = await apiClient.query(
        connection: connection,
        token: token,
        influxQl: 'SELECT "value" FROM "m" LIMIT 1',
      );

      expect(result['results'], isNotNull);

      final captured = verify(
        () =>
            mockClient.get(captureAny(), headers: captureAny(named: 'headers')),
      ).captured;

      final capturedUri = captured[0] as Uri;
      final capturedHeaders = captured[1] as Map<String, String>;

      expect(capturedUri.host, 'influx.example.com');
      expect(capturedUri.port, 8086);
      expect(capturedUri.path, '/query');
      expect(capturedUri.queryParameters['db'], 'test_db');
      expect(
        capturedUri.queryParameters['q'],
        'SELECT "value" FROM "m" LIMIT 1',
      );
      expect(capturedUri.queryParameters['epoch'], 'ms');

      expect(capturedHeaders['Authorization'], 'Token my-secret-token-xyz');
      expect(capturedHeaders['Accept'], 'application/json');
    });

    test(
      'throws InfluxAuthException on HTTP 401 without leaking token',
      () async {
        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response('Unauthorized', 401));

        try {
          await apiClient.query(
            connection: connection,
            token: token,
            influxQl: 'SHOW MEASUREMENTS',
          );
          fail('Should throw InfluxAuthException');
        } on InfluxAuthException catch (e) {
          expect(e.statusCode, 401);
          expect(e.message.contains(token), isFalse);
          expect(e.toString().contains(token), isFalse);
        }
      },
    );

    test('throws InfluxNetworkException on client network error without leaking token', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(
            http.ClientException(
              'Connection failed to https://influx.example.com?token=my-secret-token-xyz',
            ),
          );

      try {
        await apiClient.query(
          connection: connection,
          token: token,
          influxQl: 'SHOW MEASUREMENTS',
        );
        fail('Should throw InfluxNetworkException');
      } on InfluxNetworkException catch (e) {
        expect(e.message.contains(token), isFalse);
        expect(e.toString().contains(token), isFalse);
      }
    });

    test('testConnection returns true on HTTP 200', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
            (_) async => http.Response(
              json.encode({
                'results': [
                  {'statement_id': 0},
                ],
              }),
              200,
            ),
          );

      final success = await apiClient.testConnection(
        connection: connection,
        token: token,
      );
      expect(success, isTrue);
    });
  });
}
