import 'dart:convert';

import 'package:sensor_widgets/core/constants/storage_keys.dart';
import 'package:sensor_widgets/data/storage/secure_token_store.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';

/// Repository managing InfluxDB connections metadata and secure tokens.
class ConnectionRepository {
  final SharedWidgetStore _sharedStore;
  final SecureTokenStore _tokenStore;

  ConnectionRepository({
    SharedWidgetStore? sharedStore,
    SecureTokenStore? tokenStore,
  }) : _sharedStore = sharedStore ?? SharedWidgetStore(),
       _tokenStore = tokenStore ?? SecureTokenStore();

  /// Loads all configured InfluxDB connections (without tokens).
  Future<List<InfluxConnection>> getConnections() async {
    final jsonStr = await _sharedStore.getString(
      StorageKeys.connectionsMetadataKey,
    );
    if (jsonStr == null || jsonStr.trim().isEmpty) {
      return [];
    }

    try {
      final list = json.decode(jsonStr) as List<dynamic>;
      final connections = list
          .map(
            (item) => InfluxConnection.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      var migratedAny = false;
      for (final c in connections) {
        final existingShared = await _sharedStore.getString(
          StorageKeys.tokenKey(c.id),
        );
        if (existingShared == null || existingShared.isEmpty) {
          final secureToken = await _tokenStore.getToken(c.id);
          if (secureToken != null && secureToken.isNotEmpty) {
            await _sharedStore.saveString(
              StorageKeys.tokenKey(c.id),
              secureToken,
            );
            migratedAny = true;
          }
        }
      }

      if (migratedAny) {
        await _sharedStore.notifyWidgetsUpdated();
      }

      return connections;
    } catch (_) {
      return [];
    }
  }

  /// Retrieves a single connection by [id].
  Future<InfluxConnection?> getConnection(String id) async {
    final list = await getConnections();
    try {
      return list.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Saves or updates a connection. If [token] is provided, persists it securely.
  Future<void> saveConnection(
    InfluxConnection connection, {
    String? token,
  }) async {
    final list = await getConnections();
    final updatedList = List<InfluxConnection>.from(list);
    final index = updatedList.indexWhere((c) => c.id == connection.id);

    if (index != -1) {
      updatedList[index] = connection;
    } else {
      updatedList.add(connection);
    }

    final jsonStr = json.encode(updatedList.map((c) => c.toJson()).toList());
    await _sharedStore.saveString(StorageKeys.connectionsMetadataKey, jsonStr);

    if (token != null && token.isNotEmpty) {
      await _tokenStore.saveToken(connection.id, token);
      await _sharedStore.saveString(StorageKeys.tokenKey(connection.id), token);
    } else {
      final existing = await _tokenStore.getToken(connection.id);
      if (existing != null && existing.isNotEmpty) {
        await _sharedStore.saveString(
          StorageKeys.tokenKey(connection.id),
          existing,
        );
      }
    }
  }

  /// Deletes a connection and its associated secure token.
  Future<void> deleteConnection(String id) async {
    final list = await getConnections();
    final updatedList = list.where((c) => c.id != id).toList();

    final jsonStr = json.encode(updatedList.map((c) => c.toJson()).toList());
    await _sharedStore.saveString(StorageKeys.connectionsMetadataKey, jsonStr);
    await _tokenStore.deleteToken(id);
    await _sharedStore.saveString(StorageKeys.tokenKey(id), '');
  }

  /// Retrieves the secure token for the connection.
  Future<String?> getToken(String connectionId) {
    return _tokenStore.getToken(connectionId);
  }

  /// Checks if a token exists for the connection.
  Future<bool> hasToken(String connectionId) {
    return _tokenStore.hasToken(connectionId);
  }
}
