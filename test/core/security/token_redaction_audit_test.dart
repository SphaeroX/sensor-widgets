import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/domain/errors/influx_exception.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';

void main() {
  group('Token Redaction & Security Audit Tests', () {
    const rawToken = 'my_super_secret_influx_token_xyz_12345';

    test('InfluxApiClient masks token in error messages', () {
      const sensitiveMessage =
          'Failed request to http://localhost:8086 with Token $rawToken: 401 Unauthorized';
      final masked = InfluxApiClient.maskToken(sensitiveMessage, rawToken);

      expect(masked.contains(rawToken), isFalse);
      expect(masked.contains('***'), isTrue);
    });

    test(
      'InfluxException types preserve safety and do not leak token when masked',
      () {
        final sanitizedMessage = InfluxApiClient.maskToken(
          'Auth error for Token $rawToken',
          rawToken,
        );

        final authEx = InfluxAuthException(sanitizedMessage);
        final queryEx = InfluxQueryException(sanitizedMessage);
        final netEx = InfluxNetworkException(sanitizedMessage);
        final notFoundEx = InfluxNotFoundException(sanitizedMessage);

        for (final ex in [authEx, queryEx, netEx, notFoundEx]) {
          expect(ex.message.contains(rawToken), isFalse);
          expect(ex.toString().contains(rawToken), isFalse);
          expect(ex.message.contains('***'), isTrue);
        }
      },
    );

    test('InfluxConnection serialization never includes API tokens', () {
      const conn = InfluxConnection(
        id: 'conn-safe-1',
        name: 'Home Influx',
        url: 'http://192.168.1.100:8086',
        database: 'home_telemetry',
      );

      final json = conn.toJson();
      expect(json.containsKey('token'), isFalse);
      expect(json.containsKey('apiToken'), isFalse);
      expect(json.containsKey('secret'), isFalse);
      expect(json.toString().contains(rawToken), isFalse);

      final decoded = InfluxConnection.fromJson(json);
      expect(decoded.id, conn.id);
      expect(decoded.name, conn.name);
      expect(decoded.url, conn.url);
      expect(decoded.database, conn.database);
    });

    test(
      'WidgetDefinition serialization never includes tokens or secret fields',
      () {
        const widget = WidgetDefinition(
          id: 'w-safe-1',
          type: WidgetType.singleValue,
          title: 'Safe Widget',
          connectionId: 'conn-safe-1',
          measurement: 'temp_sensors',
          field: 'celsius',
        );

        final json = widget.toJson();
        expect(json.containsKey('token'), isFalse);
        expect(json.containsKey('auth'), isFalse);
        expect(json.containsKey('secret'), isFalse);
        expect(json.toString().contains(rawToken), isFalse);
      },
    );
  });
}
