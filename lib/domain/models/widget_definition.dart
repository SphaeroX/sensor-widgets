import 'package:sensor_widgets/domain/formula/formula_evaluator.dart';
import 'package:sensor_widgets/domain/models/chart_style.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/sensor_query_item.dart';
import 'package:sensor_widgets/domain/models/threshold_rule.dart';
import 'package:sensor_widgets/domain/models/widget_appearance.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';

/// Specification for a configured home screen widget.
class WidgetDefinition {
  final String id;
  final WidgetType type;
  final String title;
  final String connectionId;
  final String measurement;
  final String? field;
  final Map<String, String>? tagFilters;
  final String? unit;
  final int? decimalPlaces;
  final int refreshIntervalMinutes;

  // History & Aggregate specific
  final String? timeRange;
  final String? aggregationInterval;
  final String? aggregateFunction;

  // Indicator Lamp specific
  final ThresholdRule? threshold;

  // Gauge specific
  final double? min;
  final double? max;
  final List<ThresholdRule>? thresholds;

  // Multi-Value specific
  final List<SensorQueryItem>? items;

  // Formula specific
  final String? formula;
  final List<FormulaVariable>? formulaVariables;
  final List<FormulaStep>? formulaSteps;

  /// How time buckets with missing variables are handled: `skip` (default) or `previous`.
  final String? gapPolicy;

  /// Optional history chart styling (gradient, fill, grid, axes, markers).
  final ChartStyle? chartStyle;

  /// Optional per-widget look (colors, font scale, corner radius).
  final WidgetAppearance? appearance;

  const WidgetDefinition({
    required this.id,
    required this.type,
    required this.title,
    required this.connectionId,
    required this.measurement,
    this.field,
    this.tagFilters,
    this.unit,
    this.decimalPlaces,
    this.refreshIntervalMinutes = 15,
    this.timeRange,
    this.aggregationInterval,
    this.aggregateFunction,
    this.threshold,
    this.min,
    this.max,
    this.thresholds,
    this.items,
    this.formula,
    this.formulaVariables,
    this.formulaSteps,
    this.gapPolicy,
    this.chartStyle,
    this.appearance,
  });

  bool get isValid {
    if (id.trim().isEmpty || title.trim().isEmpty) return false;
    if (gapPolicy != null && gapPolicy != 'skip' && gapPolicy != 'previous') {
      return false;
    }
    if (chartStyle != null && !chartStyle!.isValid) return false;
    if (appearance != null && !appearance!.isValid) return false;
    if (connectionId.trim().isEmpty || measurement.trim().isEmpty) return false;

    if (formula != null && formula!.trim().isNotEmpty) {
      if (formulaVariables == null || formulaVariables!.isEmpty) return false;
      if (FormulaEvaluator.validateSteps(
            formulaSteps ?? const [],
            formula!,
            variableNames: formulaVariables!.map((v) => v.name).toList(),
          ) !=
          null) {
        return false;
      }
    } else if (type == WidgetType.multiValue) {
      if (items == null || items!.isEmpty) return false;
      for (final item in items!.where((i) => i.hasFormula)) {
        final vars = item.formulaVariables;
        if (vars == null || vars.isEmpty) return false;
        if (FormulaEvaluator.validateSteps(
              item.formulaSteps ?? const [],
              item.formula!,
              variableNames: vars.map((v) => v.name).toList(),
            ) !=
            null) {
          return false;
        }
      }
    } else {
      if (field == null || field!.trim().isEmpty) return false;
    }
    return true;
  }

  factory WidgetDefinition.fromJson(Map<String, dynamic> json) {
    return WidgetDefinition(
      id: json['id'] as String,
      type: WidgetType.fromString(json['type'] as String),
      title: json['title'] as String,
      connectionId: json['connectionId'] as String,
      measurement: json['measurement'] as String,
      field: json['field'] as String?,
      tagFilters: json['tagFilters'] != null
          ? Map<String, String>.from(json['tagFilters'] as Map)
          : null,
      unit: json['unit'] as String?,
      decimalPlaces: json['decimalPlaces'] as int?,
      refreshIntervalMinutes: json['refreshIntervalMinutes'] as int? ?? 15,
      timeRange: json['timeRange'] as String?,
      aggregationInterval: json['aggregationInterval'] as String?,
      aggregateFunction: json['aggregateFunction'] as String?,
      threshold: json['threshold'] != null
          ? ThresholdRule.fromJson(json['threshold'] as Map<String, dynamic>)
          : null,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      thresholds: json['thresholds'] != null
          ? (json['thresholds'] as List<dynamic>)
                .map((e) => ThresholdRule.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      items: json['items'] != null
          ? (json['items'] as List<dynamic>)
                .map((e) => SensorQueryItem.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      formula: json['formula'] as String?,
      formulaVariables: json['formulaVariables'] != null
          ? (json['formulaVariables'] as List<dynamic>)
                .map((e) => FormulaVariable.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      formulaSteps: json['formulaSteps'] != null
          ? (json['formulaSteps'] as List<dynamic>)
                .map((e) => FormulaStep.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      gapPolicy: json['gapPolicy'] as String?,
      chartStyle: json['chartStyle'] != null
          ? ChartStyle.fromJson(json['chartStyle'] as Map<String, dynamic>)
          : null,
      appearance: json['appearance'] != null
          ? WidgetAppearance.fromJson(
              json['appearance'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'type': type.toJson(),
      'title': title,
      'connectionId': connectionId,
      'measurement': measurement,
      'refreshIntervalMinutes': refreshIntervalMinutes,
    };
    if (field != null) map['field'] = field;
    if (tagFilters != null) map['tagFilters'] = tagFilters;
    if (unit != null) map['unit'] = unit;
    if (decimalPlaces != null) map['decimalPlaces'] = decimalPlaces;
    if (timeRange != null) map['timeRange'] = timeRange;
    if (aggregationInterval != null) {
      map['aggregationInterval'] = aggregationInterval;
    }
    if (aggregateFunction != null) {
      map['aggregateFunction'] = aggregateFunction;
    }
    if (threshold != null) map['threshold'] = threshold!.toJson();
    if (min != null) map['min'] = min;
    if (max != null) map['max'] = max;
    if (thresholds != null) {
      map['thresholds'] = thresholds!.map((e) => e.toJson()).toList();
    }
    if (items != null) {
      map['items'] = items!.map((e) => e.toJson()).toList();
    }
    if (formula != null) map['formula'] = formula;
    if (formulaVariables != null) {
      map['formulaVariables'] = formulaVariables!
          .map((e) => e.toJson())
          .toList();
    }
    if (formulaSteps != null) {
      map['formulaSteps'] = formulaSteps!.map((e) => e.toJson()).toList();
    }
    if (gapPolicy != null) map['gapPolicy'] = gapPolicy;
    if (chartStyle != null) map['chartStyle'] = chartStyle!.toJson();
    if (appearance != null) map['appearance'] = appearance!.toJson();
    return map;
  }

  WidgetDefinition copyWith({
    String? id,
    WidgetType? type,
    String? title,
    String? connectionId,
    String? measurement,
    String? field,
    Map<String, String>? tagFilters,
    String? unit,
    int? decimalPlaces,
    int? refreshIntervalMinutes,
    String? timeRange,
    String? aggregationInterval,
    String? aggregateFunction,
    ThresholdRule? threshold,
    double? min,
    double? max,
    List<ThresholdRule>? thresholds,
    List<SensorQueryItem>? items,
    String? formula,
    List<FormulaVariable>? formulaVariables,
    List<FormulaStep>? formulaSteps,
    String? gapPolicy,
    ChartStyle? chartStyle,
    WidgetAppearance? appearance,
  }) {
    return WidgetDefinition(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      connectionId: connectionId ?? this.connectionId,
      measurement: measurement ?? this.measurement,
      field: field ?? this.field,
      tagFilters: tagFilters ?? this.tagFilters,
      unit: unit ?? this.unit,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      refreshIntervalMinutes:
          refreshIntervalMinutes ?? this.refreshIntervalMinutes,
      timeRange: timeRange ?? this.timeRange,
      aggregationInterval: aggregationInterval ?? this.aggregationInterval,
      aggregateFunction: aggregateFunction ?? this.aggregateFunction,
      threshold: threshold ?? this.threshold,
      min: min ?? this.min,
      max: max ?? this.max,
      thresholds: thresholds ?? this.thresholds,
      items: items ?? this.items,
      formula: formula ?? this.formula,
      formulaVariables: formulaVariables ?? this.formulaVariables,
      formulaSteps: formulaSteps ?? this.formulaSteps,
      gapPolicy: gapPolicy ?? this.gapPolicy,
      chartStyle: chartStyle ?? this.chartStyle,
      appearance: appearance ?? this.appearance,
    );
  }
}
