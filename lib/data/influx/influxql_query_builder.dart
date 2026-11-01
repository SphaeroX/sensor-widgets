/// Deterministic InfluxQL v1 query builder.
class InfluxQlQueryBuilder {
  const InfluxQlQueryBuilder();

  /// Escapes double quotes inside InfluxQL identifiers (measurement, field, tag key).
  String escapeIdentifier(String identifier) {
    return identifier.replaceAll('"', '\\"');
  }

  /// Escapes single quotes inside InfluxQL string literal values (tag values).
  String escapeLiteral(String literal) {
    return literal.replaceAll("'", "\\'");
  }

  /// Builds a WHERE clause from tag filters, ordered alphabetically for determinism.
  String _buildTagFilterClause(Map<String, String>? tagFilters) {
    if (tagFilters == null || tagFilters.isEmpty) {
      return '';
    }
    final sortedKeys = tagFilters.keys.toList()..sort();
    final conditions = sortedKeys
        .map((key) {
          final escapedKey = escapeIdentifier(key);
          final escapedVal = escapeLiteral(tagFilters[key]!);
          return '"$escapedKey" = \'$escapedVal\'';
        })
        .join(' AND ');

    return conditions;
  }

  /// Query for single value, indicator lamp, or gauge bar.
  String buildSingleValueQuery({
    required String measurement,
    required String field,
    Map<String, String>? tagFilters,
  }) {
    final m = escapeIdentifier(measurement);
    final f = escapeIdentifier(field);
    final tagClause = _buildTagFilterClause(tagFilters);

    if (tagClause.isEmpty) {
      return 'SELECT "$f" FROM "$m" ORDER BY time DESC LIMIT 1';
    }
    return 'SELECT "$f" FROM "$m" WHERE $tagClause ORDER BY time DESC LIMIT 1';
  }

  /// Query for history charts with aggregation and time range.
  String buildHistoryQuery({
    required String measurement,
    required String field,
    required String timeRange,
    required String bucketInterval,
    Map<String, String>? tagFilters,
  }) {
    final m = escapeIdentifier(measurement);
    final f = escapeIdentifier(field);
    final tagClause = _buildTagFilterClause(tagFilters);

    final whereClause = tagClause.isEmpty
        ? 'time > now() - $timeRange'
        : 'time > now() - $timeRange AND $tagClause';

    return 'SELECT MEAN("$f") AS "mean" FROM "$m" WHERE $whereClause GROUP BY time($bucketInterval) fill(none)';
  }

  /// Query for several fields of one measurement as time buckets.
  ///
  /// Empty buckets are returned as `null` (`fill(null)`) so that gap handling
  /// is done uniformly in Dart and does not depend on `fill(previous)`
  /// support of the InfluxDB version.
  String buildBucketedMultiFieldQuery({
    required String measurement,
    required List<String> fields,
    required String timeRange,
    required String bucketInterval,
    Map<String, String>? tagFilters,
  }) {
    final m = escapeIdentifier(measurement);
    final selects = fields
        .map((f) {
          final e = escapeIdentifier(f);
          return 'MEAN("$e") AS "$e"';
        })
        .join(', ');
    final tagClause = _buildTagFilterClause(tagFilters);
    final whereClause = tagClause.isEmpty
        ? 'time > now() - $timeRange'
        : 'time > now() - $timeRange AND $tagClause';

    return 'SELECT $selects FROM "$m" WHERE $whereClause GROUP BY time($bucketInterval) fill(null)';
  }

  /// Query for aggregate min, max, mean.
  String buildAggregateQuery({
    required String measurement,
    required String field,
    required String timeRange,
    Map<String, String>? tagFilters,
  }) {
    final m = escapeIdentifier(measurement);
    final f = escapeIdentifier(field);
    final tagClause = _buildTagFilterClause(tagFilters);

    final whereClause = tagClause.isEmpty
        ? 'time > now() - $timeRange'
        : 'time > now() - $timeRange AND $tagClause';

    return 'SELECT MIN("$f") AS "min", MAX("$f") AS "max", MEAN("$f") AS "mean" FROM "$m" WHERE $whereClause';
  }

  /// Query for multi-value widget.
  String buildMultiValueQuery({
    required String measurement,
    required List<String> fields,
    Map<String, String>? tagFilters,
  }) {
    final m = escapeIdentifier(measurement);
    final escapedFields = fields
        .map((f) => '"${escapeIdentifier(f)}"')
        .join(', ');
    final tagClause = _buildTagFilterClause(tagFilters);

    if (tagClause.isEmpty) {
      return 'SELECT $escapedFields FROM "$m" ORDER BY time DESC LIMIT 1';
    }
    return 'SELECT $escapedFields FROM "$m" WHERE $tagClause ORDER BY time DESC LIMIT 1';
  }

  /// Query to discover measurements.
  String buildShowMeasurementsQuery() => 'SHOW MEASUREMENTS';

  /// Query to discover field keys in a measurement.
  String buildShowFieldKeysQuery(String measurement) {
    return 'SHOW FIELD KEYS FROM "${escapeIdentifier(measurement)}"';
  }

  /// Query to discover tag keys in a measurement.
  String buildShowTagKeysQuery(String measurement) {
    return 'SHOW TAG KEYS FROM "${escapeIdentifier(measurement)}"';
  }

  /// Query to discover tag values for a specific tag key.
  String buildShowTagValuesQuery(String measurement, String tagKey) {
    return 'SHOW TAG VALUES FROM "${escapeIdentifier(measurement)}" WITH KEY = "${escapeIdentifier(tagKey)}"';
  }
}
