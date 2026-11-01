import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/domain/errors/influx_error_formatter.dart';
import 'package:sensor_widgets/domain/errors/influx_exception.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/presentation/controllers/schema_discovery_state.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';

export 'package:sensor_widgets/presentation/controllers/schema_discovery_state.dart';

/// Controller providing asynchronous schema discovery (measurements, field keys, tags)
/// with graceful fallback on offline or unreachable servers.
class SchemaDiscoveryController {
  final ConnectionRepository connectionRepository;
  final InfluxApiClient apiClient;

  SchemaDiscoveryController({
    required this.connectionRepository,
    required this.apiClient,
  });

  Future<List<String>> getMeasurements(String connectionId) async {
    try {
      final connection = await connectionRepository.getConnection(connectionId);
      if (connection == null) return const [];
      final token = await connectionRepository.getToken(connectionId);
      if (token == null) return const [];
      return await apiClient.fetchMeasurements(
        connection: connection,
        token: token,
      );
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> getFieldKeys(
    String connectionId,
    String measurement,
  ) async {
    if (measurement.trim().isEmpty) return const [];
    try {
      final connection = await connectionRepository.getConnection(connectionId);
      if (connection == null) return const [];
      final token = await connectionRepository.getToken(connectionId);
      if (token == null) return const [];
      return await apiClient.fetchFieldKeys(
        connection: connection,
        token: token,
        measurement: measurement,
      );
    } catch (_) {
      return const [];
    }
  }

  Future<List<InfluxFieldInfo>> getFieldInfos(
    String connectionId,
    String measurement,
  ) async {
    if (measurement.trim().isEmpty) return const [];
    try {
      final connection = await connectionRepository.getConnection(connectionId);
      if (connection == null) return const [];
      final token = await connectionRepository.getToken(connectionId);
      if (token == null) return const [];
      return await apiClient.fetchFieldInfos(
        connection: connection,
        token: token,
        measurement: measurement,
      );
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> getTagKeys(
    String connectionId,
    String measurement,
  ) async {
    if (measurement.trim().isEmpty) return const [];
    try {
      final connection = await connectionRepository.getConnection(connectionId);
      if (connection == null) return const [];
      final token = await connectionRepository.getToken(connectionId);
      if (token == null) return const [];
      return await apiClient.fetchTagKeys(
        connection: connection,
        token: token,
        measurement: measurement,
      );
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> getTagValues(
    String connectionId,
    String measurement,
    String tagKey,
  ) async {
    if (measurement.trim().isEmpty || tagKey.trim().isEmpty) return const [];
    try {
      final connection = await connectionRepository.getConnection(connectionId);
      if (connection == null) return const [];
      final token = await connectionRepository.getToken(connectionId);
      if (token == null) return const [];
      return await apiClient.fetchTagValues(
        connection: connection,
        token: token,
        measurement: measurement,
        tagKey: tagKey,
      );
    } catch (_) {
      return const [];
    }
  }
}

final schemaDiscoveryControllerProvider = Provider<SchemaDiscoveryController>((
  ref,
) {
  return SchemaDiscoveryController(
    connectionRepository: ref.watch(connectionRepositoryProvider),
    apiClient: ref.watch(influxApiClientProvider),
  );
});

/// Reactive controller managing cascaded schema discovery state for the widget editor.
class EditorSchemaController extends StateNotifier<EditorSchemaState> {
  final ConnectionRepository connectionRepository;
  final InfluxApiClient apiClient;
  int _connectionRequestId = 0;
  int _measurementRequestId = 0;

  EditorSchemaController({
    required this.connectionRepository,
    required this.apiClient,
  }) : super(EditorSchemaState.initial());

  Future<void> selectConnection(String? connectionId) async {
    final reqId = ++_connectionRequestId;
    if (connectionId == null || connectionId.trim().isEmpty) {
      state = EditorSchemaState.initial();
      return;
    }

    state = state.copyWith(
      selectedConnectionId: connectionId,
      clearSelectedMeasurement: true,
      measurements: const SchemaListState.loading(),
      fields: const SchemaListState.idle(),
      tagKeys: const SchemaListState.idle(),
      tagValuesByKey: const {},
    );

    String? token;
    try {
      final connection = await connectionRepository.getConnection(connectionId);
      if (connection == null) {
        if (reqId == _connectionRequestId) {
          state = state.copyWith(
            measurements: const SchemaListState.error(
              'Verbindung nicht gefunden.',
            ),
          );
        }
        return;
      }
      token = await connectionRepository.getToken(connectionId);
      if (token == null) {
        if (reqId == _connectionRequestId) {
          state = state.copyWith(
            measurements: const SchemaListState.error(
              'API-Token für diese Verbindung nicht gefunden.',
            ),
          );
        }
        return;
      }

      final items = await _fetchMeasurementsSafe(connection, token);

      if (reqId == _connectionRequestId) {
        state = state.copyWith(measurements: SchemaListState.loaded(items));
      }
    } on InfluxException catch (e) {
      if (reqId == _connectionRequestId) {
        final formatted = InfluxErrorFormatter.format(e, token: token);
        state = state.copyWith(measurements: SchemaListState.error(formatted));
      }
    } catch (e) {
      if (reqId == _connectionRequestId) {
        final formatted = InfluxErrorFormatter.format(e, token: token);
        state = state.copyWith(measurements: SchemaListState.error(formatted));
      }
    }
  }

  Future<List<String>> _fetchMeasurementsSafe(
    InfluxConnection connection,
    String token,
  ) async {
    try {
      return await apiClient.fetchMeasurements(
        connection: connection,
        token: token,
      );
    } on InfluxException {
      rethrow;
    } catch (_) {
      return const [];
    }
  }

  Future<void> selectMeasurement(String? measurement) async {
    final reqId = ++_measurementRequestId;
    if (measurement == null || measurement.trim().isEmpty) {
      state = state.copyWith(
        clearSelectedMeasurement: true,
        fields: const SchemaListState.idle(),
        tagKeys: const SchemaListState.idle(),
        tagValuesByKey: const {},
      );
      return;
    }

    state = state.copyWith(
      selectedMeasurement: measurement,
      fields: const SchemaListState.loading(),
      tagKeys: const SchemaListState.loading(),
      tagValuesByKey: const {},
    );

    final connectionId = state.selectedConnectionId;
    if (connectionId == null) {
      state = state.copyWith(
        fields: const SchemaListState.error('Keine Verbindung ausgewählt.'),
        tagKeys: const SchemaListState.error('Keine Verbindung ausgewählt.'),
      );
      return;
    }

    String? token;
    try {
      final connection = await connectionRepository.getConnection(connectionId);
      token = await connectionRepository.getToken(connectionId);
      if (connection == null || token == null) {
        if (reqId == _measurementRequestId) {
          state = state.copyWith(
            fields: const SchemaListState.error(
              'Verbindung oder Token nicht gefunden.',
            ),
            tagKeys: const SchemaListState.error(
              'Verbindung oder Token nicht gefunden.',
            ),
          );
        }
        return;
      }

      final fieldsFuture = _loadFieldInfos(connection, token, measurement);
      final tagKeysFuture = _loadTagKeysSafe(connection, token, measurement);

      final results = await Future.wait([fieldsFuture, tagKeysFuture]);
      if (reqId == _measurementRequestId) {
        state = state.copyWith(
          fields: SchemaListState.loaded(results[0] as List<InfluxFieldInfo>),
          tagKeys: SchemaListState.loaded(results[1] as List<String>),
        );
      }
    } on InfluxException catch (e) {
      if (reqId == _measurementRequestId) {
        final formatted = InfluxErrorFormatter.format(e, token: token);
        state = state.copyWith(
          fields: SchemaListState.error(formatted),
          tagKeys: SchemaListState.error(formatted),
        );
      }
    } catch (e) {
      if (reqId == _measurementRequestId) {
        final formatted = InfluxErrorFormatter.format(e, token: token);
        state = state.copyWith(
          fields: SchemaListState.error(formatted),
          tagKeys: SchemaListState.error(formatted),
        );
      }
    }
  }

  Future<List<String>> _loadTagKeysSafe(
    InfluxConnection connection,
    String token,
    String measurement,
  ) async {
    try {
      return await apiClient.fetchTagKeys(
        connection: connection,
        token: token,
        measurement: measurement,
      );
    } on InfluxException {
      rethrow;
    } catch (_) {
      return const [];
    }
  }

  Future<List<InfluxFieldInfo>> _loadFieldInfos(
    InfluxConnection connection,
    String token,
    String measurement,
  ) async {
    try {
      return await apiClient.fetchFieldInfos(
        connection: connection,
        token: token,
        measurement: measurement,
      );
    } on InfluxException {
      rethrow;
    } catch (_) {
      try {
        final keys = await apiClient.fetchFieldKeys(
          connection: connection,
          token: token,
          measurement: measurement,
        );
        return keys
            .map((k) => InfluxFieldInfo(key: k, type: 'unknown'))
            .toList();
      } on InfluxException {
        rethrow;
      } catch (_) {
        return const [];
      }
    }
  }

  Future<void> loadTagValues(String tagKey) async {
    if (tagKey.trim().isEmpty) return;
    final connectionId = state.selectedConnectionId;
    final measurement = state.selectedMeasurement;
    if (connectionId == null || measurement == null) return;

    final updatedMap = Map<String, SchemaListState<String>>.from(
      state.tagValuesByKey,
    );
    updatedMap[tagKey] = const SchemaListState.loading();
    state = state.copyWith(tagValuesByKey: updatedMap);

    String? token;
    try {
      final connection = await connectionRepository.getConnection(connectionId);
      token = await connectionRepository.getToken(connectionId);
      if (connection == null || token == null) {
        final errMap = Map<String, SchemaListState<String>>.from(
          state.tagValuesByKey,
        );
        errMap[tagKey] = const SchemaListState.error(
          'Verbindung nicht gefunden.',
        );
        state = state.copyWith(tagValuesByKey: errMap);
        return;
      }

      final values = await apiClient.fetchTagValues(
        connection: connection,
        token: token,
        measurement: measurement,
        tagKey: tagKey,
      );

      final loadedMap = Map<String, SchemaListState<String>>.from(
        state.tagValuesByKey,
      );
      loadedMap[tagKey] = SchemaListState.loaded(values);
      state = state.copyWith(tagValuesByKey: loadedMap);
    } catch (e) {
      final formatted = InfluxErrorFormatter.format(e, token: token);
      final errMap = Map<String, SchemaListState<String>>.from(
        state.tagValuesByKey,
      );
      errMap[tagKey] = SchemaListState.error(formatted);
      state = state.copyWith(tagValuesByKey: errMap);
    }
  }

  Future<void> reloadMeasurements() async {
    await selectConnection(state.selectedConnectionId);
  }

  Future<void> reloadFieldsAndTags() async {
    await selectMeasurement(state.selectedMeasurement);
  }

  Future<void> reloadTagValues(String tagKey) async {
    await loadTagValues(tagKey);
  }
}

final editorSchemaControllerProvider =
    StateNotifierProvider.autoDispose<
      EditorSchemaController,
      EditorSchemaState
    >((ref) {
      return EditorSchemaController(
        connectionRepository: ref.watch(connectionRepositoryProvider),
        apiClient: ref.watch(influxApiClientProvider),
      );
    });
