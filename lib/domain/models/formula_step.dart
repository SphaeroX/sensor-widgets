/// A named intermediate formula. Steps are evaluated in order and may refer to
/// variables and to earlier steps only.
class FormulaStep {
  final String name;
  final String expression;
  final String? label;

  const FormulaStep({required this.name, required this.expression, this.label});

  factory FormulaStep.fromJson(Map<String, dynamic> json) {
    return FormulaStep(
      name: json['name'] as String,
      expression: json['expression'] as String,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'name': name, 'expression': expression};
    if (label != null) map['label'] = label;
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormulaStep &&
          name == other.name &&
          expression == other.expression &&
          label == other.label;

  @override
  int get hashCode => Object.hash(name, expression, label);

  @override
  String toString() =>
      'FormulaStep(name: $name, expression: $expression, label: $label)';
}
