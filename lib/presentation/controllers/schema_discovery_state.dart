import 'package:flutter/foundation.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';

enum SchemaStatus { idle, loading, loaded, error }

@immutable
class SchemaListState<T> {
  final SchemaStatus status;
  final List<T> items;
  final String? errorMessage;

  const SchemaListState({
    required this.status,
    this.items = const [],
    this.errorMessage,
  });

  const SchemaListState.idle()
    : status = SchemaStatus.idle,
      items = const [],
      errorMessage = null;

  const SchemaListState.loading()
    : status = SchemaStatus.loading,
      items = const [],
      errorMessage = null;

  const SchemaListState.loaded(this.items)
    : status = SchemaStatus.loaded,
      errorMessage = null;

  const SchemaListState.error(this.errorMessage)
    : status = SchemaStatus.error,
      items = const [];

  bool get isIdle => status == SchemaStatus.idle;
  bool get isLoading => status == SchemaStatus.loading;
  bool get isLoaded => status == SchemaStatus.loaded;
  bool get hasError => status == SchemaStatus.error;
  bool get isEmptyLoaded => isLoaded && items.isEmpty;

  SchemaListState<T> copyWith({
    SchemaStatus? status,
    List<T>? items,
    String? errorMessage,
  }) {
    return SchemaListState<T>(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchemaListState<T> &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          listEquals(items, other.items) &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(status, Object.hashAll(items), errorMessage);

  @override
  String toString() =>
      'SchemaListState<$T>(status: $status, items: ${items.length}, error: $errorMessage)';
}

@immutable
class EditorSchemaState {
  final String? selectedConnectionId;
  final String? selectedMeasurement;
  final SchemaListState<String> measurements;
  final SchemaListState<InfluxFieldInfo> fields;
  final SchemaListState<String> tagKeys;
  final Map<String, SchemaListState<String>> tagValuesByKey;

  const EditorSchemaState({
    this.selectedConnectionId,
    this.selectedMeasurement,
    this.measurements = const SchemaListState.idle(),
    this.fields = const SchemaListState.idle(),
    this.tagKeys = const SchemaListState.idle(),
    this.tagValuesByKey = const {},
  });

  factory EditorSchemaState.initial() => const EditorSchemaState();

  EditorSchemaState copyWith({
    String? selectedConnectionId,
    String? selectedMeasurement,
    bool clearSelectedMeasurement = false,
    SchemaListState<String>? measurements,
    SchemaListState<InfluxFieldInfo>? fields,
    SchemaListState<String>? tagKeys,
    Map<String, SchemaListState<String>>? tagValuesByKey,
  }) {
    return EditorSchemaState(
      selectedConnectionId: selectedConnectionId ?? this.selectedConnectionId,
      selectedMeasurement: clearSelectedMeasurement
          ? null
          : (selectedMeasurement ?? this.selectedMeasurement),
      measurements: measurements ?? this.measurements,
      fields: fields ?? this.fields,
      tagKeys: tagKeys ?? this.tagKeys,
      tagValuesByKey: tagValuesByKey ?? this.tagValuesByKey,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorSchemaState &&
          runtimeType == other.runtimeType &&
          selectedConnectionId == other.selectedConnectionId &&
          selectedMeasurement == other.selectedMeasurement &&
          measurements == other.measurements &&
          fields == other.fields &&
          tagKeys == other.tagKeys &&
          mapEquals(tagValuesByKey, other.tagValuesByKey);

  @override
  int get hashCode => Object.hash(
    selectedConnectionId,
    selectedMeasurement,
    measurements,
    fields,
    tagKeys,
    Object.hashAll(tagValuesByKey.entries),
  );
}
