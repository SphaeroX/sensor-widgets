/// Base class for all InfluxDB-related exceptions.
///
/// NOTE: Exception messages must NEVER contain authorization tokens or raw headers.
abstract class InfluxException implements Exception {
  final String message;
  final int? statusCode;

  const InfluxException(this.message, {this.statusCode});

  @override
  String toString() =>
      '$runtimeType: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Thrown when authentication or authorization fails (HTTP 401 / 403).
class InfluxAuthException extends InfluxException {
  const InfluxAuthException([
    super.message = 'Authentication failed. Check API token and permissions.',
  ]) : super(statusCode: 401);
}

/// Thrown when InfluxDB returns a query syntax error or execution error.
class InfluxQueryException extends InfluxException {
  const InfluxQueryException(super.message);
}

/// Thrown when network connectivity fails or requests time out.
class InfluxNetworkException extends InfluxException {
  const InfluxNetworkException(String details)
    : super('Network error: $details');
}

/// Thrown when an InfluxDB resource or database is not found (HTTP 404).
class InfluxNotFoundException extends InfluxException {
  const InfluxNotFoundException([
    super.message = 'InfluxDB resource or database not found (HTTP 404)',
  ]) : super(statusCode: 404);
}

/// Thrown when InfluxDB response cannot be parsed.
class InfluxParseException extends InfluxException {
  const InfluxParseException(String details)
    : super('Failed to parse InfluxDB response: $details');
}
