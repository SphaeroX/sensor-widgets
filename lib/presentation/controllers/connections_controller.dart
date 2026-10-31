import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';

/// Riverpod provider for managing InfluxDB connections.
final connectionsControllerProvider =
    AsyncNotifierProvider<ConnectionsController, List<InfluxConnection>>(
      ConnectionsController.new,
    );

class ConnectionsController extends AsyncNotifier<List<InfluxConnection>> {
  late final ConnectionRepository _repo;
  late final InfluxApiClient _apiClient;

  @override
  Future<List<InfluxConnection>> build() async {
    _repo = ref.watch(connectionRepositoryProvider);
    _apiClient = ref.watch(influxApiClientProvider);
    return _repo.getConnections();
  }

  /// Saves or updates a connection and invalidates state.
  Future<void> saveConnection(
    InfluxConnection connection, {
    String? token,
  }) async {
    await _repo.saveConnection(connection, token: token);
    ref.invalidateSelf();
  }

  /// Deletes a connection and its associated token.
  Future<void> deleteConnection(String id) async {
    await _repo.deleteConnection(id);
    ref.invalidateSelf();
  }

  /// Tests connectivity against InfluxDB using the provided connection and token.
  Future<bool> testConnection({
    required InfluxConnection connection,
    required String token,
  }) async {
    return _apiClient.testConnection(connection: connection, token: token);
  }

  /// Retrieves the existing token for an existing connection.
  Future<String?> getToken(String connectionId) {
    return _repo.getToken(connectionId);
  }
}
