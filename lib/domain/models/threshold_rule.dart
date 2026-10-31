/// Comparison operators supported for threshold checks.
enum ThresholdOperator {
  greaterThan('greaterThan'),
  lessThan('lessThan');

  final String wireName;
  const ThresholdOperator(this.wireName);

  static ThresholdOperator fromString(String value) {
    return ThresholdOperator.values.firstWhere(
      (op) => op.wireName == value,
      orElse: () => throw ArgumentError('Unknown ThresholdOperator: $value'),
    );
  }

  String toJson() => wireName;
}

/// A threshold rule configured for indicator lamps or gauge bars.
class ThresholdRule {
  final ThresholdOperator operator;
  final double value;
  final String? color;
  final String? activeColor;
  final String? inactiveColor;

  const ThresholdRule({
    required this.operator,
    required this.value,
    this.color,
    this.activeColor,
    this.inactiveColor,
  });

  /// Evaluates whether the given [actualValue] matches this threshold rule.
  bool matches(double actualValue) {
    switch (operator) {
      case ThresholdOperator.greaterThan:
        return actualValue > value;
      case ThresholdOperator.lessThan:
        return actualValue < value;
    }
  }

  factory ThresholdRule.fromJson(Map<String, dynamic> json) {
    return ThresholdRule(
      operator: ThresholdOperator.fromString(json['operator'] as String),
      value: (json['value'] as num).toDouble(),
      color: json['color'] as String?,
      activeColor: json['activeColor'] as String?,
      inactiveColor: json['inactiveColor'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'operator': operator.toJson(),
      'value': value,
    };
    if (color != null) map['color'] = color;
    if (activeColor != null) map['activeColor'] = activeColor;
    if (inactiveColor != null) map['inactiveColor'] = inactiveColor;
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThresholdRule &&
          runtimeType == other.runtimeType &&
          operator == other.operator &&
          value == other.value &&
          color == other.color &&
          activeColor == other.activeColor &&
          inactiveColor == other.inactiveColor;

  @override
  int get hashCode =>
      Object.hash(operator, value, color, activeColor, inactiveColor);
}
