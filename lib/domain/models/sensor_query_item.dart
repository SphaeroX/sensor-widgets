import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';

/// Sub-item configuration for multi-value widgets.
///
/// A row with a [formula] is calculated from its own [formulaVariables] (and
/// optional [formulaSteps]); [field] is then only the row identifier.
class SensorQueryItem {
  final String field;
  final String? label;
  final String? unit;
  final int? decimalPlaces;
  final String? formula;
  final List<FormulaVariable>? formulaVariables;
  final List<FormulaStep>? formulaSteps;

  const SensorQueryItem({
    required this.field,
    this.label,
    this.unit,
    this.decimalPlaces,
    this.formula,
    this.formulaVariables,
    this.formulaSteps,
  });

  bool get hasFormula => formula != null && formula!.trim().isNotEmpty;

  factory SensorQueryItem.fromJson(Map<String, dynamic> json) {
    return SensorQueryItem(
      field: json['field'] as String,
      label: json['label'] as String?,
      unit: json['unit'] as String?,
      decimalPlaces: json['decimalPlaces'] as int?,
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
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'field': field};
    if (label != null) map['label'] = label;
    if (unit != null) map['unit'] = unit;
    if (decimalPlaces != null) map['decimalPlaces'] = decimalPlaces;
    if (formula != null) map['formula'] = formula;
    if (formulaVariables != null) {
      map['formulaVariables'] = formulaVariables!
          .map((e) => e.toJson())
          .toList();
    }
    if (formulaSteps != null) {
      map['formulaSteps'] = formulaSteps!.map((e) => e.toJson()).toList();
    }
    return map;
  }

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorQueryItem &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          label == other.label &&
          unit == other.unit &&
          decimalPlaces == other.decimalPlaces &&
          formula == other.formula &&
          _listEquals(formulaVariables, other.formulaVariables) &&
          _listEquals(formulaSteps, other.formulaSteps);

  @override
  int get hashCode => Object.hash(
    field,
    label,
    unit,
    decimalPlaces,
    formula,
    Object.hashAll(formulaVariables ?? const []),
    Object.hashAll(formulaSteps ?? const []),
  );
}
