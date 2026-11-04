import 'package:sensor_widgets/domain/models/threshold_rule.dart';

/// Push notification rule of a widget (contract field `alerts`).
///
/// [target] is [targetValue] for the primary value (with a formula: the
/// calculated value; history chart: the latest point), a row `field` of a
/// multi-value widget, or `min`/`max`/`mean` of an aggregate. The native
/// widget code notifies once when the rule starts matching and again only
/// after the value went back (`fixtures/alerts/evaluation_cases.json`).
class AlertRule {
  static const String targetValue = 'value';

  final String target;
  final ThresholdOperator operator;
  final double value;

  const AlertRule({
    required this.target,
    required this.operator,
    required this.value,
  });

  bool get isValid => target.trim().isNotEmpty && value.isFinite;

  factory AlertRule.fromJson(Map<String, dynamic> json) {
    return AlertRule(
      target: json['target'] as String,
      operator: ThresholdOperator.fromString(json['operator'] as String),
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'target': target,
    'operator': operator.toJson(),
    'value': value,
  };

  AlertRule copyWith({
    String? target,
    ThresholdOperator? operator,
    double? value,
  }) {
    return AlertRule(
      target: target ?? this.target,
      operator: operator ?? this.operator,
      value: value ?? this.value,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertRule &&
          target == other.target &&
          operator == other.operator &&
          value == other.value;

  @override
  int get hashCode => Object.hash(target, operator, value);
}
