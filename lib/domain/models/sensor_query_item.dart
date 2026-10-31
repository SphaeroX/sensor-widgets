/// Sub-item configuration for multi-value widgets.
class SensorQueryItem {
  final String field;
  final String? label;
  final String? unit;
  final int? decimalPlaces;

  const SensorQueryItem({
    required this.field,
    this.label,
    this.unit,
    this.decimalPlaces,
  });

  factory SensorQueryItem.fromJson(Map<String, dynamic> json) {
    return SensorQueryItem(
      field: json['field'] as String,
      label: json['label'] as String?,
      unit: json['unit'] as String?,
      decimalPlaces: json['decimalPlaces'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'field': field};
    if (label != null) map['label'] = label;
    if (unit != null) map['unit'] = unit;
    if (decimalPlaces != null) map['decimalPlaces'] = decimalPlaces;
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorQueryItem &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          label == other.label &&
          unit == other.unit &&
          decimalPlaces == other.decimalPlaces;

  @override
  int get hashCode => Object.hash(field, label, unit, decimalPlaces);
}
