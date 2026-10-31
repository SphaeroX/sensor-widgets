import 'dart:convert';

import 'package:sensor_widgets/core/constants/storage_keys.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';

/// Repository managing widget configurations persisted in shared storage.
class WidgetDefinitionRepository {
  final SharedWidgetStore _sharedStore;

  WidgetDefinitionRepository({SharedWidgetStore? sharedStore})
    : _sharedStore = sharedStore ?? SharedWidgetStore();

  /// Loads all configured widget definitions.
  Future<List<WidgetDefinition>> getWidgets() async {
    final jsonStr = await _sharedStore.getString(
      StorageKeys.widgetDefinitionsKey,
    );
    if (jsonStr == null || jsonStr.trim().isEmpty) {
      return [];
    }

    try {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final list = map['widgets'] as List<dynamic>?;
      if (list == null) return [];

      return list
          .map(
            (item) => WidgetDefinition.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Retrieves a single widget configuration by [id].
  Future<WidgetDefinition?> getWidget(String id) async {
    final list = await getWidgets();
    try {
      return list.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Finds all widgets bound to a specific [connectionId].
  Future<List<WidgetDefinition>> getWidgetsForConnection(
    String connectionId,
  ) async {
    final list = await getWidgets();
    return list.where((w) => w.connectionId == connectionId).toList();
  }

  Future<void> _saveWidgetsEnvelope(List<WidgetDefinition> widgets) async {
    final envelope = <String, dynamic>{
      'schemaVersion': StorageKeys.schemaVersion,
      'widgets': widgets.map((w) => w.toJson()).toList(),
    };
    final jsonStr = json.encode(envelope);
    await _sharedStore.saveString(StorageKeys.widgetDefinitionsKey, jsonStr);
    await _sharedStore.notifyWidgetsUpdated();
  }

  /// Saves or updates a widget definition and triggers native widget reloads.
  Future<void> saveWidget(WidgetDefinition widget) async {
    final list = await getWidgets();
    final updatedList = List<WidgetDefinition>.from(list);
    final index = updatedList.indexWhere((w) => w.id == widget.id);

    if (index != -1) {
      updatedList[index] = widget;
    } else {
      updatedList.add(widget);
    }

    await _saveWidgetsEnvelope(updatedList);
  }

  /// Deletes a widget configuration and triggers native widget reloads.
  Future<void> deleteWidget(String id) async {
    final list = await getWidgets();
    final updatedList = list.where((w) => w.id != id).toList();
    await _saveWidgetsEnvelope(updatedList);
  }

  /// Reorders widgets to match the specified [orderedIds].
  Future<void> reorderWidgets(List<String> orderedIds) async {
    final list = await getWidgets();
    final map = {for (final w in list) w.id: w};

    final reordered = <WidgetDefinition>[];
    for (final id in orderedIds) {
      if (map.containsKey(id)) {
        reordered.add(map[id]!);
      }
    }
    // Include any that might not have been in orderedIds
    for (final w in list) {
      if (!orderedIds.contains(w.id)) {
        reordered.add(w);
      }
    }

    await _saveWidgetsEnvelope(reordered);
  }
}
