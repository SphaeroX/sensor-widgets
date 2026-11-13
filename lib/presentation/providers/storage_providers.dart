import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/platform/external_link_launcher.dart';
import 'package:sensor_widgets/data/platform/notification_permission.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/secure_token_store.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';

/// Provider for the secure token store.
final secureTokenStoreProvider = Provider<SecureTokenStore>((ref) {
  return SecureTokenStore();
});

/// Provider for the shared widget store (home_widget).
final sharedWidgetStoreProvider = Provider<SharedWidgetStore>((ref) {
  return SharedWidgetStore();
});

/// Provider for the InfluxQL API Client.
final influxApiClientProvider = Provider<InfluxApiClient>((ref) {
  return InfluxApiClient();
});

/// Provider for the notification permission request (platform channel).
final notificationPermissionProvider = Provider<NotificationPermission>((ref) {
  return NotificationPermission();
});

/// Provider for opening external links (system browser).
final externalLinkLauncherProvider = Provider<ExternalLinkLauncher>((ref) {
  return ExternalLinkLauncher();
});

/// Provider for the ConnectionRepository.
final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  final sharedStore = ref.watch(sharedWidgetStoreProvider);
  final tokenStore = ref.watch(secureTokenStoreProvider);
  return ConnectionRepository(sharedStore: sharedStore, tokenStore: tokenStore);
});

/// Provider for the WidgetDefinitionRepository.
final widgetDefinitionRepositoryProvider = Provider<WidgetDefinitionRepository>(
  (ref) {
    final sharedStore = ref.watch(sharedWidgetStoreProvider);
    return WidgetDefinitionRepository(sharedStore: sharedStore);
  },
);

/// Reactive list of connections.
final connectionsListProvider =
    AsyncNotifierProvider<ConnectionsListNotifier, List<InfluxConnection>>(
      ConnectionsListNotifier.new,
    );

class ConnectionsListNotifier extends AsyncNotifier<List<InfluxConnection>> {
  @override
  Future<List<InfluxConnection>> build() async {
    final repo = ref.watch(connectionRepositoryProvider);
    return repo.getConnections();
  }

  Future<void> save(InfluxConnection connection, {String? token}) async {
    final repo = ref.read(connectionRepositoryProvider);
    await repo.saveConnection(connection, token: token);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final repo = ref.read(connectionRepositoryProvider);
    await repo.deleteConnection(id);
    ref.invalidateSelf();
  }
}

/// Reactive list of widget definitions.
final widgetDefinitionsListProvider =
    AsyncNotifierProvider<WidgetsListNotifier, List<WidgetDefinition>>(
      WidgetsListNotifier.new,
    );

class WidgetsListNotifier extends AsyncNotifier<List<WidgetDefinition>> {
  @override
  Future<List<WidgetDefinition>> build() async {
    final repo = ref.watch(widgetDefinitionRepositoryProvider);
    return repo.getWidgets();
  }

  Future<void> save(WidgetDefinition widget) async {
    final repo = ref.read(widgetDefinitionRepositoryProvider);
    await repo.saveWidget(widget);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final repo = ref.read(widgetDefinitionRepositoryProvider);
    await repo.deleteWidget(id);
    ref.invalidateSelf();
  }

  Future<void> reorder(List<String> orderedIds) async {
    final repo = ref.read(widgetDefinitionRepositoryProvider);
    await repo.reorderWidgets(orderedIds);
    ref.invalidateSelf();
  }
}
