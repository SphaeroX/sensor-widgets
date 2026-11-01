/// Definition of a single variable used within a widget calculation formula.
class FormulaVariable {
  final String name;
  final String field;
  final String? measurement;
  final Map<String, String>? tagFilters;
  final String? label;

  const FormulaVariable({
    required this.name,
    required this.field,
    this.measurement,
    this.tagFilters,
    this.label,
  });

  factory FormulaVariable.fromJson(Map<String, dynamic> json) {
    return FormulaVariable(
      name: json['name'] as String,
      field: json['field'] as String,
      measurement: json['measurement'] as String?,
      tagFilters: json['tagFilters'] != null
          ? Map<String, String>.from(json['tagFilters'] as Map)
          : null,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'name': name, 'field': field};
    if (measurement != null) map['measurement'] = measurement;
    if (tagFilters != null) map['tagFilters'] = tagFilters;
    if (label != null) map['label'] = label;
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormulaVariable &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          field == other.field &&
          measurement == other.measurement &&
          label == other.label &&
          _mapsEqual(tagFilters, other.tagFilters);

  static bool _mapsEqual(Map<String, String>? a, Map<String, String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    var tagsHash = 0;
    if (tagFilters != null) {
      for (final entry in tagFilters!.entries) {
        tagsHash ^= Object.hash(entry.key, entry.value);
      }
    }
    return Object.hash(name, field, measurement, label, tagsHash);
  }

  @override
  String toString() =>
      'FormulaVariable(name: $name, field: $field, measurement: $measurement, tagFilters: $tagFilters, label: $label)';
}
