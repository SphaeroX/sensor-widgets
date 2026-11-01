import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/domain/errors/influx_exception.dart';

/// Formats InfluxDB exceptions and errors into user-friendly German messages,
/// ensuring that tokens are always redacted.
class InfluxErrorFormatter {
  const InfluxErrorFormatter._();

  static String format(Object error, {String? token}) {
    String mask(String text) {
      if (token == null || token.trim().isEmpty) return text;
      return InfluxApiClient.maskToken(text, token);
    }

    if (error is InfluxAuthException) {
      return 'Authentifizierungsfehler (401): Bitte API-Token und Leseberechtigungen für die Datenbank bzw. das Bucket prüfen.';
    }

    if (error is InfluxQueryException) {
      final msg = mask(error.message);
      if (msg.toLowerCase().contains('database not found')) {
        return 'Datenbank bzw. Bucket nicht gefunden: In InfluxDB v2 muss für das Bucket ein v1-DBRP-Mapping eingerichtet sein oder der Bucket-Name exakt mit dem Datenbanknamen übereinstimmen.';
      }
      return 'Abfragefehler: $msg';
    }

    if (error is InfluxNotFoundException) {
      return 'Endpunkt nicht gefunden (404): Bitte Basis-URL und Port der InfluxDB-Instanz prüfen.';
    }

    if (error is InfluxNetworkException) {
      final msg = mask(error.message);
      return 'Netzwerkverbindung fehlgeschlagen ($msg): Die InfluxDB-Instanz konnte nicht erreicht werden. Bitte Netzwerkverbindung, Host und Port prüfen.';
    }

    if (error is InfluxParseException) {
      final msg = mask(error.message);
      return 'Unerwartetes Antwortformat ($msg): Die Antwort der InfluxDB konnte nicht verarbeitet werden.';
    }

    final raw = error is Exception ? error.toString() : '$error';
    return 'Unerwarteter Fehler: ${mask(raw)}';
  }
}
