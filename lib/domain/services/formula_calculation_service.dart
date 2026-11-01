import 'package:sensor_widgets/core/utils/duration_utils.dart';
import 'package:sensor_widgets/core/utils/number_formatter.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/influx/influx_response_parser.dart';
import 'package:sensor_widgets/data/influx/influxql_query_builder.dart';
import 'package:sensor_widgets/domain/formula/formula_evaluator.dart';
import 'package:sensor_widgets/domain/formula/formula_exception.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/sensor_data_point.dart';
import 'package:sensor_widgets/domain/models/sensor_query_item.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';

/// A time bucket whose formula could not be calculated.
class FormulaBucketError {
  final DateTime timestamp;
  final FormulaException exception;

  const FormulaBucketError({required this.timestamp, required this.exception});

  String get message => exception.message;
}

/// Result of evaluating a formula over time buckets.
class FormulaSeriesResult {
  final List<SensorDataPoint> points;
  final List<FormulaBucketError> errors;

  const FormulaSeriesResult({required this.points, required this.errors});
}

class _VariableGroup {
  final String measurement;
  final Map<String, String>? tagFilters;
  final List<FormulaVariable> variables = [];

  _VariableGroup(this.measurement, this.tagFilters);
}

/// Service that executes queries to resolve formula variables from InfluxDB
/// and computes the final numerical result using [FormulaEvaluator].
class FormulaCalculationService {
  final InfluxApiClient _apiClient;
  final InfluxQlQueryBuilder _queryBuilder;
  final InfluxResponseParser _responseParser;

  FormulaCalculationService({
    InfluxApiClient? apiClient,
    InfluxQlQueryBuilder? queryBuilder,
    InfluxResponseParser? responseParser,
  }) : _apiClient = apiClient ?? InfluxApiClient(),
       _queryBuilder = queryBuilder ?? const InfluxQlQueryBuilder(),
       _responseParser = responseParser ?? const InfluxResponseParser();

  /// Resolves the formula variables for [widget] from InfluxDB and evaluates the formula.
  Future<double> calculateFormula({
    required WidgetDefinition widget,
    required InfluxConnection connection,
    required String token,
  }) async {
    final formula = _requireFormula(widget);
    final variableValues = <String, double>{};

    for (final group in _groupVariables(widget)) {
      final fields = group.variables.map((v) => v.field).toSet().toList();

      final influxQl = _queryBuilder.buildMultiValueQuery(
        measurement: group.measurement,
        fields: fields,
        tagFilters: group.tagFilters,
      );

      final response = await _apiClient.query(
        connection: connection,
        token: token,
        influxQl: influxQl,
      );

      final multiValues = _responseParser.parseMultiValues(response, fields);

      for (final v in group.variables) {
        final dataPoint = multiValues[v.field];
        if (dataPoint == null) {
          throw MissingVariableException(v.name);
        }
        variableValues[v.name] = dataPoint.value;
      }
    }

    final rawResult = FormulaEvaluator.evaluate(
      formula,
      variableValues,
      steps: widget.formulaSteps ?? const [],
    );
    return _round(rawResult, widget);
  }

  /// Calculates the formula of one multi-value row from its latest values.
  ///
  /// The row inherits measurement, tag filters and rounding from [widget].
  Future<double> calculateItemFormula({
    required WidgetDefinition widget,
    required SensorQueryItem item,
    required InfluxConnection connection,
    required String token,
  }) {
    return calculateFormula(
      widget: widget.copyWith(
        formula: item.formula,
        formulaVariables: item.formulaVariables,
        formulaSteps: item.formulaSteps ?? const [],
        decimalPlaces: item.decimalPlaces ?? widget.decimalPlaces,
      ),
      connection: connection,
      token: token,
    );
  }

  /// Evaluates the formula for every time bucket of the widget's time range.
  ///
  /// Variables are averaged into identical buckets (`GROUP BY time`). Buckets
  /// with missing variables are handled according to `widget.gapPolicy`.
  /// Buckets whose calculation fails (e.g. division by zero) are reported in
  /// [FormulaSeriesResult.errors]; if no bucket succeeds, the first error is
  /// thrown.
  Future<FormulaSeriesResult> calculateSeries({
    required WidgetDefinition widget,
    required InfluxConnection connection,
    required String token,
  }) async {
    final formula = _requireFormula(widget);
    final timeRange = widget.timeRange ?? '24h';
    final interval = DurationUtils.effectiveBucketInterval(
      timeRange: timeRange,
      requested: widget.aggregationInterval,
    );

    // variable name -> {epochMs: value}
    final byVariable = <String, Map<int, double>>{};
    for (final group in _groupVariables(widget)) {
      final fields = group.variables.map((v) => v.field).toSet().toList();
      final response = await _apiClient.query(
        connection: connection,
        token: token,
        influxQl: _queryBuilder.buildBucketedMultiFieldQuery(
          measurement: group.measurement,
          fields: fields,
          timeRange: timeRange,
          bucketInterval: interval,
          tagFilters: group.tagFilters,
        ),
      );
      final parsed = _responseParser.parseBucketedFields(response, fields);
      for (final v in group.variables) {
        final series = parsed[v.field] ?? const <int, double>{};
        if (series.isEmpty) throw MissingVariableException(v.name);
        byVariable[v.name] = series;
      }
    }

    final carryForward = widget.gapPolicy == 'previous';
    final timestamps = <int>{
      for (final series in byVariable.values) ...series.keys,
    }.toList()..sort();

    final last = <String, double>{};
    final points = <SensorDataPoint>[];
    final errors = <FormulaBucketError>[];

    for (final ts in timestamps) {
      final values = <String, double>{};
      var complete = true;
      for (final entry in byVariable.entries) {
        final current = entry.value[ts];
        if (current != null) last[entry.key] = current;
        final resolved = current ?? (carryForward ? last[entry.key] : null);
        if (resolved == null) {
          complete = false;
        } else {
          values[entry.key] = resolved;
        }
      }
      if (!complete) continue;

      final timestamp = DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true);
      try {
        final raw = FormulaEvaluator.evaluate(
          formula,
          values,
          steps: widget.formulaSteps ?? const [],
        );
        points.add(
          SensorDataPoint(
            timestamp: timestamp,
            value: _round(raw, widget),
            field: widget.field ?? 'formula',
          ),
        );
      } on FormulaException catch (e) {
        errors.add(FormulaBucketError(timestamp: timestamp, exception: e));
      }
    }

    if (points.isEmpty && errors.isNotEmpty) throw errors.first.exception;
    return FormulaSeriesResult(points: points, errors: errors);
  }

  /// Applies the formula per time bucket and then aggregates (min, max, mean).
  Future<Map<String, double>> calculateAggregate({
    required WidgetDefinition widget,
    required InfluxConnection connection,
    required String token,
  }) async {
    final result = await calculateSeries(
      widget: widget,
      connection: connection,
      token: token,
    );
    if (result.points.isEmpty) return const {};
    final values = result.points.map((p) => p.value).toList();
    final sum = values.reduce((a, b) => a + b);
    return {
      'min': values.reduce((a, b) => a < b ? a : b),
      'max': values.reduce((a, b) => a > b ? a : b),
      'mean': _round(sum / values.length, widget),
    };
  }

  String _requireFormula(WidgetDefinition widget) {
    final formula = widget.formula;
    if (formula == null || formula.trim().isEmpty) {
      throw const FormulaSyntaxException('Widget besitzt keine Formel');
    }
    final variables = widget.formulaVariables;
    if (variables == null || variables.isEmpty) {
      throw const FormulaSyntaxException(
        'Keine Variablen für die Formel definiert',
      );
    }
    return formula;
  }

  /// Groups variables by target (measurement, tag filters).
  List<_VariableGroup> _groupVariables(WidgetDefinition widget) {
    String tagsKey(Map<String, String>? tags) => tags == null
        ? ''
        : (tags.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
              .map((e) => '${e.key}=${e.value}')
              .join('&');

    final groups = <String, _VariableGroup>{};
    for (final v in widget.formulaVariables!) {
      final measurement = v.measurement ?? widget.measurement;
      final tags = v.tagFilters ?? widget.tagFilters;
      final key = '$measurement||${tagsKey(tags)}';
      groups
          .putIfAbsent(key, () => _VariableGroup(measurement, tags))
          .variables
          .add(v);
    }
    return groups.values.toList();
  }

  double _round(double value, WidgetDefinition widget) {
    final decimals = (widget.decimalPlaces ?? 2).clamp(0, 2);
    return NumberFormatter.roundToMaxDecimals(value, maxDecimals: decimals);
  }
}
