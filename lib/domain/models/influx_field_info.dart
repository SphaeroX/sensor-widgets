import 'package:flutter/foundation.dart';

/// Represents metadata for an InfluxDB field: its key and data type.
@immutable
class InfluxFieldInfo {
  final String key;
  final String _rawType;

  const InfluxFieldInfo({required this.key, required String type})
    : _rawType = type;

  /// Returns the normalized lowercase type (e.g. 'float', 'string'), or 'unknown'.
  String get type {
    final trimmed = _rawType.trim();
    return trimmed.isEmpty ? 'unknown' : trimmed.toLowerCase();
  }

  /// Returns true if this field can be used for numeric sensor representations.
  /// Defaults unknown types to true to avoid false-positive blocking.
  bool get isNumeric {
    switch (type) {
      case 'float':
      case 'integer':
      case 'unsigned':
      case 'unknown':
        return true;
      case 'string':
      case 'boolean':
      default:
        return false;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InfluxFieldInfo &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          type == other.type;

  @override
  int get hashCode => Object.hash(key, type);

  @override
  String toString() => 'InfluxFieldInfo(key: $key, type: $type)';
}
