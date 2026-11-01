import 'package:sensor_widgets/domain/errors/influx_exception.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/domain/models/sensor_data_point.dart';

/// Parses InfluxDB v1 HTTP API query JSON responses into strongly-typed domain models.
class InfluxResponseParser {
  const InfluxResponseParser();

  void _checkErrors(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      throw InfluxQueryException(json['error'].toString());
    }
    final results = json['results'] as List<dynamic>?;
    if (results != null && results.isNotEmpty) {
      final first = results.first as Map<String, dynamic>;
      if (first.containsKey('error')) {
        throw InfluxQueryException(first['error'].toString());
      }
    }
  }

  List<Map<String, dynamic>> _extractSeries(Map<String, dynamic> json) {
    _checkErrors(json);
    final results = json['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return const [];
    final first = results.first as Map<String, dynamic>;
    final series = first['series'] as List<dynamic>?;
    if (series == null || series.isEmpty) return const [];
    return series.cast<Map<String, dynamic>>();
  }

  /// Parses a single value response (LIMIT 1).
  SensorDataPoint? parseSingleValue(
    Map<String, dynamic> json,
    String fieldName,
  ) {
    final seriesList = _extractSeries(json);
    if (seriesList.isEmpty) return null;

    final series = seriesList.first;
    final columns = (series['columns'] as List<dynamic>).cast<String>();
    final valuesList = series['values'] as List<dynamic>?;
    if (valuesList == null || valuesList.isEmpty) return null;

    final firstRow = valuesList.first as List<dynamic>;
    final timeIdx = columns.indexOf('time');
    var fieldIdx = columns.indexOf(fieldName);
    if (fieldIdx == -1) {
      // Fallback: if there are 2 columns and one is time, the other is the value
      if (columns.length == 2 && timeIdx != -1) {
        fieldIdx = timeIdx == 0 ? 1 : 0;
      } else {
        return null;
      }
    }

    final rawVal = firstRow[fieldIdx];
    if (rawVal == null) return null;

    final double val = (rawVal as num).toDouble();
    final int epochMs = timeIdx != -1 && firstRow[timeIdx] is num
        ? (firstRow[timeIdx] as num).toInt()
        : DateTime.now().toUtc().millisecondsSinceEpoch;

    return SensorDataPoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true),
      value: val,
      field: fieldName,
    );
  }

  /// Parses time series data for history charts.
  List<SensorDataPoint> parseTimeSeries(
    Map<String, dynamic> json,
    String fieldName,
  ) {
    final seriesList = _extractSeries(json);
    if (seriesList.isEmpty) return const [];

    final series = seriesList.first;
    final columns = (series['columns'] as List<dynamic>).cast<String>();
    final valuesList = series['values'] as List<dynamic>?;
    if (valuesList == null || valuesList.isEmpty) return const [];

    final timeIdx = columns.indexOf('time');
    var fieldIdx = columns.indexOf(fieldName);
    if (fieldIdx == -1) {
      if (columns.length == 2 && timeIdx != -1) {
        fieldIdx = timeIdx == 0 ? 1 : 0;
      } else {
        return const [];
      }
    }

    final points = <SensorDataPoint>[];
    for (final row in valuesList) {
      final rowList = row as List<dynamic>;
      final rawVal = rowList[fieldIdx];
      if (rawVal == null) continue; // Skip null / fill(none) buckets

      final double val = (rawVal as num).toDouble();
      final int epochMs = timeIdx != -1 && rowList[timeIdx] is num
          ? (rowList[timeIdx] as num).toInt()
          : 0;

      points.add(
        SensorDataPoint(
          timestamp: DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true),
          value: val,
          field: fieldName,
        ),
      );
    }

    return points;
  }

  /// Parses multi-value responses (mapping each field name to its latest SensorDataPoint).
  Map<String, SensorDataPoint> parseMultiValues(
    Map<String, dynamic> json,
    List<String> fields,
  ) {
    final seriesList = _extractSeries(json);
    if (seriesList.isEmpty) return const {};

    final series = seriesList.first;
    final columns = (series['columns'] as List<dynamic>).cast<String>();
    final valuesList = series['values'] as List<dynamic>?;
    if (valuesList == null || valuesList.isEmpty) return const {};

    final firstRow = valuesList.first as List<dynamic>;
    final timeIdx = columns.indexOf('time');
    final int epochMs = timeIdx != -1 && firstRow[timeIdx] is num
        ? (firstRow[timeIdx] as num).toInt()
        : DateTime.now().toUtc().millisecondsSinceEpoch;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true);

    final map = <String, SensorDataPoint>{};
    for (final field in fields) {
      final idx = columns.indexOf(field);
      if (idx != -1 && firstRow[idx] != null) {
        map[field] = SensorDataPoint(
          timestamp: timestamp,
          value: (firstRow[idx] as num).toDouble(),
          field: field,
        );
      }
    }

    return map;
  }

  /// Parses a bucketed multi-field response into `field -> {epochMs: value}`.
  /// Buckets where a field is `null` are omitted for that field.
  Map<String, Map<int, double>> parseBucketedFields(
    Map<String, dynamic> json,
    List<String> fields,
  ) {
    final result = <String, Map<int, double>>{
      for (final f in fields) f: <int, double>{},
    };
    final seriesList = _extractSeries(json);
    if (seriesList.isEmpty) return result;

    final series = seriesList.first;
    final columns = (series['columns'] as List<dynamic>).cast<String>();
    final valuesList = series['values'] as List<dynamic>?;
    final timeIdx = columns.indexOf('time');
    if (valuesList == null || timeIdx == -1) return result;

    for (final field in fields) {
      final idx = columns.indexOf(field);
      if (idx == -1) continue;
      for (final row in valuesList) {
        final cells = row as List<dynamic>;
        final raw = cells[idx];
        final time = cells[timeIdx];
        if (raw is num && time is num) {
          result[field]![time.toInt()] = raw.toDouble();
        }
      }
    }
    return result;
  }

  /// Parses aggregate values (min, max, mean).
  Map<String, double> parseAggregate(Map<String, dynamic> json) {
    final seriesList = _extractSeries(json);
    if (seriesList.isEmpty) return const {};

    final series = seriesList.first;
    final columns = (series['columns'] as List<dynamic>).cast<String>();
    final valuesList = series['values'] as List<dynamic>?;
    if (valuesList == null || valuesList.isEmpty) return const {};

    final firstRow = valuesList.first as List<dynamic>;
    final map = <String, double>{};

    for (var i = 0; i < columns.length; i++) {
      final col = columns[i].toLowerCase();
      if (col == 'time') continue;
      final val = firstRow[i];
      if (val is num) {
        map[col] = val.toDouble();
      }
    }

    return map;
  }

  /// Parses SHOW MEASUREMENTS.
  List<String> parseMeasurements(Map<String, dynamic> json) {
    final seriesList = _extractSeries(json);
    if (seriesList.isEmpty) return const [];
    final series = seriesList.first;
    final valuesList = series['values'] as List<dynamic>?;
    if (valuesList == null) return const [];

    return valuesList
        .map((row) => (row as List<dynamic>).first.toString())
        .toList();
  }

  /// Parses SHOW FIELD KEYS into key names only.
  List<String> parseFieldKeys(Map<String, dynamic> json) {
    final seriesList = _extractSeries(json);
    if (seriesList.isEmpty) return const [];
    final series = seriesList.first;
    final valuesList = series['values'] as List<dynamic>?;
    if (valuesList == null) return const [];

    return valuesList
        .map((row) => (row as List<dynamic>).first.toString())
        .toList();
  }

  /// Parses SHOW FIELD KEYS into strongly-typed [InfluxFieldInfo] objects.
  List<InfluxFieldInfo> parseFieldInfos(Map<String, dynamic> json) {
    final seriesList = _extractSeries(json);
    if (seriesList.isEmpty) return const [];
    final series = seriesList.first;
    final columns =
        (series['columns'] as List<dynamic>?)?.cast<String>() ?? const [];
    final keyIdx = columns.indexOf('fieldKey');
    final typeIdx = columns.indexOf('fieldType');
    final valuesList = series['values'] as List<dynamic>?;
    if (valuesList == null) return const [];

    return valuesList.map((row) {
      final rowList = row as List<dynamic>;
      final key = keyIdx != -1 && keyIdx < rowList.length
          ? rowList[keyIdx].toString()
          : (rowList.isNotEmpty ? rowList.first.toString() : '');
      final type = typeIdx != -1 && typeIdx < rowList.length
          ? rowList[typeIdx].toString()
          : 'unknown';
      return InfluxFieldInfo(key: key, type: type);
    }).toList();
  }

  /// Parses SHOW TAG KEYS.
  List<String> parseTagKeys(Map<String, dynamic> json) {
    final seriesList = _extractSeries(json);
    if (seriesList.isEmpty) return const [];
    final series = seriesList.first;
    final valuesList = series['values'] as List<dynamic>?;
    if (valuesList == null) return const [];

    return valuesList
        .map((row) => (row as List<dynamic>).first.toString())
        .toList();
  }

  /// Parses SHOW TAG VALUES.
  List<String> parseTagValues(Map<String, dynamic> json) {
    final seriesList = _extractSeries(json);
    if (seriesList.isEmpty) return const [];
    final series = seriesList.first;
    final columns = (series['columns'] as List<dynamic>).cast<String>();
    final valueIdx = columns.indexOf('value');
    final valuesList = series['values'] as List<dynamic>?;
    if (valuesList == null) return const [];

    final idx = valueIdx != -1 ? valueIdx : 1;
    return valuesList
        .map((row) => (row as List<dynamic>)[idx].toString())
        .toList();
  }
}
