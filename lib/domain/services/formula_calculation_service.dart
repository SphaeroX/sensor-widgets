import 'package:sensor_widgets/core/utils/number_formatter.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/influx/influx_response_parser.dart';
import 'package:sensor_widgets/data/influx/influxql_query_builder.dart';
import 'package:sensor_widgets/domain/formula/formula_evaluator.dart';
import 'package:sensor_widgets/domain/formula/formula_exception.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';

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

    // Group variables by target (measurement, tagFilters)
    final groups = <String, List<FormulaVariable>>{};
    for (final v in variables) {
      final m = v.measurement ?? widget.measurement;
      final tagsKey = v.tagFilters != null
          ? (v.tagFilters!.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key)))
                .map((e) => '${e.key}=${e.value}')
                .join('&')
          : (widget.tagFilters != null
                ? (widget.tagFilters!.entries.toList()
                        ..sort((a, b) => a.key.compareTo(b.key)))
                      .map((e) => '${e.key}=${e.value}')
                      .join('&')
                : '');
      final key = '$m||$tagsKey';
      groups.putIfAbsent(key, () => []).add(v);
    }

    final variableValues = <String, double>{};

    for (final group in groups.values) {
      final first = group.first;
      final m = first.measurement ?? widget.measurement;
      final tags = first.tagFilters ?? widget.tagFilters;
      final fields = group.map((v) => v.field).toSet().toList();

      final influxQl = _queryBuilder.buildMultiValueQuery(
        measurement: m,
        fields: fields,
        tagFilters: tags,
      );

      final response = await _apiClient.query(
        connection: connection,
        token: token,
        influxQl: influxQl,
      );

      final multiValues = _responseParser.parseMultiValues(response, fields);

      for (final v in group) {
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
    final decimals = (widget.decimalPlaces ?? 2).clamp(0, 2);
    return NumberFormatter.roundToMaxDecimals(rawResult, maxDecimals: decimals);
  }
}
