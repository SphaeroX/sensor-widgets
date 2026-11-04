import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/domain/errors/influx_exception.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// Formats InfluxDB exceptions and errors into user-friendly messages in the
/// language of the given [AppLocalizations], ensuring that tokens are always
/// redacted.
class InfluxErrorFormatter {
  const InfluxErrorFormatter._();

  static String format(
    Object error, {
    String? token,
    required AppLocalizations l10n,
  }) {
    String mask(String text) {
      if (token == null || token.trim().isEmpty) return text;
      return InfluxApiClient.maskToken(text, token);
    }

    if (error is InfluxAuthException) {
      return l10n.influxErrorAuth;
    }

    if (error is InfluxQueryException) {
      final msg = mask(error.message);
      if (msg.toLowerCase().contains('database not found')) {
        return l10n.influxErrorDatabaseNotFound;
      }
      return l10n.influxErrorQuery(msg);
    }

    if (error is InfluxNotFoundException) {
      return l10n.influxErrorEndpointNotFound;
    }

    if (error is InfluxNetworkException) {
      final msg = mask(error.message);
      return l10n.influxErrorNetwork(msg);
    }

    if (error is InfluxParseException) {
      final msg = mask(error.message);
      return l10n.influxErrorParse(msg);
    }

    final raw = error is Exception ? error.toString() : '$error';
    return l10n.influxErrorUnexpected(mask(raw));
  }
}
