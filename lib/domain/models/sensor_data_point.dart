/// A parsed single measurement data point.
class SensorDataPoint {
  final DateTime timestamp;
  final double value;
  final String field;

  const SensorDataPoint({
    required this.timestamp,
    required this.value,
    required this.field,
  });

  factory SensorDataPoint.fromJson(Map<String, dynamic> json) {
    return SensorDataPoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestampEpochMs'] as int,
        isUtc: true,
      ),
      value: (json['value'] as num).toDouble(),
      field: json['field'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'timestampEpochMs': timestamp.millisecondsSinceEpoch,
      'value': value,
      'field': field,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorDataPoint &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          value == other.value &&
          field == other.field;

  @override
  int get hashCode => Object.hash(timestamp, value, field);

  @override
  String toString() => 'SensorDataPoint($field: $value @ $timestamp)';
}
