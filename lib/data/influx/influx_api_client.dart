import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sensor_widgets/data/influx/influx_response_parser.dart';
import 'package:sensor_widgets/data/influx/influxql_query_builder.dart';
import 'package:sensor_widgets/domain/errors/influx_exception.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';

/// HTTP Client that executes InfluxQL queries against the InfluxDB v1-compatible HTTP API.
class InfluxApiClient {
  final http.Client _httpClient;
  final InfluxQlQueryBuilder _queryBuilder;
  final InfluxResponseParser _responseParser;

  InfluxApiClient({
    http.Client? httpClient,
    InfluxQlQueryBuilder? queryBuilder,
    InfluxResponseParser? responseParser,
  }) : _httpClient = httpClient ?? http.Client(),
       _queryBuilder = queryBuilder ?? const InfluxQlQueryBuilder(),
       _responseParser = responseParser ?? const InfluxResponseParser();

  /// Replaces any occurrence of the secret token with `***`.
  static String maskToken(String text, String token) {
    if (token.isEmpty) return text;
    return text.replaceAll(token, '***');
  }

  /// Sends an InfluxQL query to the `/query` endpoint of the given connection.
  Future<Map<String, dynamic>> query({
    required InfluxConnection connection,
    required String token,
    required String influxQl,
  }) async {
    final baseUri = Uri.parse(connection.url);
    final uri = baseUri.replace(
      path: baseUri.path.endsWith('/')
          ? '${baseUri.path}query'
          : '${baseUri.path}/query',
      queryParameters: {
        'db': connection.database,
        'q': influxQl,
        'epoch': 'ms',
      },
    );

    final headers = {
      'Authorization': 'Token $token',
      'Accept': 'application/json',
    };

    try {
      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw InfluxAuthException(
          maskToken(
            'Authentication failed (HTTP ${response.statusCode})',
            token,
          ),
        );
      }

      if (response.statusCode == 404) {
        throw const InfluxNotFoundException();
      }

      if (response.statusCode >= 400) {
        throw InfluxQueryException(
          maskToken(
            'InfluxDB request failed (HTTP ${response.statusCode}): ${response.body}',
            token,
          ),
        );
      }

      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return decoded;
      } catch (e) {
        throw InfluxParseException(maskToken(e.toString(), token));
      }
    } on InfluxException {
      rethrow;
    } on SocketException catch (e) {
      throw InfluxNetworkException(maskToken(e.message, token));
    } on http.ClientException catch (e) {
      throw InfluxNetworkException(maskToken(e.message, token));
    } catch (e) {
      throw InfluxNetworkException(maskToken(e.toString(), token));
    }
  }

  /// Tests connectivity and credentials by requesting `SHOW MEASUREMENTS`.
  Future<bool> testConnection({
    required InfluxConnection connection,
    required String token,
  }) async {
    final q = _queryBuilder.buildShowMeasurementsQuery();
    final json = await query(connection: connection, token: token, influxQl: q);
    // If it didn't throw and returned a valid response, connection is good
    return json.containsKey('results');
  }

  /// Fetches available measurement names for schema discovery.
  Future<List<String>> fetchMeasurements({
    required InfluxConnection connection,
    required String token,
  }) async {
    final q = _queryBuilder.buildShowMeasurementsQuery();
    final json = await query(connection: connection, token: token, influxQl: q);
    return _responseParser.parseMeasurements(json);
  }

  /// Fetches available field keys for a given measurement.
  Future<List<String>> fetchFieldKeys({
    required InfluxConnection connection,
    required String token,
    required String measurement,
  }) async {
    final q = _queryBuilder.buildShowFieldKeysQuery(measurement);
    final json = await query(connection: connection, token: token, influxQl: q);
    return _responseParser.parseFieldKeys(json);
  }

  /// Fetches available tag keys for a given measurement.
  Future<List<String>> fetchTagKeys({
    required InfluxConnection connection,
    required String token,
    required String measurement,
  }) async {
    final q = _queryBuilder.buildShowTagKeysQuery(measurement);
    final json = await query(connection: connection, token: token, influxQl: q);
    return _responseParser.parseTagKeys(json);
  }

  /// Fetches available tag values for a given measurement and tag key.
  Future<List<String>> fetchTagValues({
    required InfluxConnection connection,
    required String token,
    required String measurement,
    required String tagKey,
  }) async {
    final q = _queryBuilder.buildShowTagValuesQuery(measurement, tagKey);
    final json = await query(connection: connection, token: token, influxQl: q);
    return _responseParser.parseTagValues(json);
  }
}
