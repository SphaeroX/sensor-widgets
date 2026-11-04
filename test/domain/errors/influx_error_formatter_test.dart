import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/errors/influx_error_formatter.dart';
import 'package:sensor_widgets/domain/errors/influx_exception.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// The tests assert the German texts.
final _de = lookupAppLocalizations(const Locale('de'));

void main() {
  group('InfluxErrorFormatter', () {
    const secretToken = 'secret-auth-token-12345';

    test('formats InfluxAuthException with permission hint', () {
      const error = InfluxAuthException('Unauthorized access');
      final msg = InfluxErrorFormatter.format(
        error,
        token: secretToken,
        l10n: _de,
      );

      expect(msg, contains('Authentifizierungsfehler (401)'));
      expect(msg, contains('API-Token'));
      expect(msg.contains(secretToken), isFalse);
    });

    test('formats InfluxQueryException with database not found hint for InfluxDB v2 DBRP', () {
      const error = InfluxQueryException('database not found: telegraf');
      final msg = InfluxErrorFormatter.format(
        error,
        token: secretToken,
        l10n: _de,
      );

      expect(msg, contains('Datenbank bzw. Bucket nicht gefunden'));
      expect(msg, contains('DBRP-Mapping'));
      expect(msg.contains(secretToken), isFalse);
    });

    test(
      'formats general InfluxQueryException with query error description',
      () {
        const error = InfluxQueryException('syntax error at line 1');
        final msg = InfluxErrorFormatter.format(
          error,
          token: secretToken,
          l10n: _de,
        );

        expect(msg, contains('Abfragefehler: syntax error at line 1'));
        expect(msg.contains(secretToken), isFalse);
      },
    );

    test('formats InfluxNotFoundException with 404 URL hint', () {
      const error = InfluxNotFoundException('Endpoint /query not found');
      final msg = InfluxErrorFormatter.format(
        error,
        token: secretToken,
        l10n: _de,
      );

      expect(msg, contains('Endpunkt nicht gefunden (404)'));
      expect(msg, contains('URL'));
      expect(msg.contains(secretToken), isFalse);
    });

    test('formats InfluxNetworkException with network connection hint', () {
      const error = InfluxNetworkException('Connection refused');
      final msg = InfluxErrorFormatter.format(
        error,
        token: secretToken,
        l10n: _de,
      );

      expect(msg, contains('Netzwerkverbindung fehlgeschlagen'));
      expect(msg.contains(secretToken), isFalse);
    });

    test('formats InfluxParseException with JSON response format hint', () {
      const error = InfluxParseException('Invalid JSON body');
      final msg = InfluxErrorFormatter.format(
        error,
        token: secretToken,
        l10n: _de,
      );

      expect(msg, contains('Unerwartetes Antwortformat'));
      expect(msg.contains(secretToken), isFalse);
    });

    test('masks secret token even when contained inside error message', () {
      const error = InfluxNetworkException(
        'Failed connecting with token: $secretToken to host',
      );
      final msg = InfluxErrorFormatter.format(
        error,
        token: secretToken,
        l10n: _de,
      );

      expect(msg.contains(secretToken), isFalse);
      expect(msg, contains('***'));
    });

    test('formats unknown generic error safely', () {
      final msg = InfluxErrorFormatter.format('Random string error', l10n: _de);
      expect(msg, contains('Unerwarteter Fehler: Random string error'));
    });
  });
}
