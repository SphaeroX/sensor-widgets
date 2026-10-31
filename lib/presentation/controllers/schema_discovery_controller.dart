import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';

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
