import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/core/constants/storage_keys.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';

class MockSharedWidgetStore extends Mock implements SharedWidgetStore {}

void main() {
  group('WidgetDefinitionRepository', () {
    late MockSharedWidgetStore mockSharedStore;
    late WidgetDefinitionRepository repository;

    const widget1 = WidgetDefinition(
      id: 'w-1',
      type: WidgetType.singleValue,
      title: 'Temp Living Room',
      connectionId: 'conn-1',
      measurement: 'temperature',
      field: 'value',
    );

    setUp(() {
      mockSharedStore = MockSharedWidgetStore();
      repository = WidgetDefinitionRepository(sharedStore: mockSharedStore);
    });

    test('returns empty list when storage is empty or invalid', () async {
      when(() => mockSharedStore.getString(StorageKeys.widgetDefinitionsKey))
          .thenAnswer((_) async => null);

      final result = await repository.getWidgets();
      expect(result, isEmpty);

      when(() => mockSharedStore.getString(StorageKeys.widgetDefinitionsKey))
          .thenAnswer((_) async => 'not-valid-json');

      final corruptResult = await repository.getWidgets();
      expect(corruptResult, isEmpty);
    });

    test('saves widget and triggers notifyWidgetsUpdated', () async {
      when(() => mockSharedStore.getString(StorageKeys.widgetDefinitionsKey))
          .thenAnswer((_) async => null);
      when(() => mockSharedStore.saveString(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockSharedStore.notifyWidgetsUpdated())
          .thenAnswer((_) async {});

      await repository.saveWidget(widget1);

      verify(() => mockSharedStore.notifyWidgetsUpdated()).called(1);

      final captured = verify(
        () => mockSharedStore.saveString(
          StorageKeys.widgetDefinitionsKey,
          captureAny(),
        ),
      ).captured;

      final saved =
          json.decode(captured.first as String) as Map<String, dynamic>;
      expect(saved['schemaVersion'], 1);
      final list = saved['widgets'] as List<dynamic>;
      expect(list.length, 1);
      expect(list.first['id'], 'w-1');
    });

    test('deletes widget and triggers notifyWidgetsUpdated', () async {
      final envelope = {
        'schemaVersion': 1,
        'widgets': [widget1.toJson()],
      };
      when(() => mockSharedStore.getString(StorageKeys.widgetDefinitionsKey))
          .thenAnswer((_) async => json.encode(envelope));
      when(() => mockSharedStore.saveString(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockSharedStore.notifyWidgetsUpdated())
          .thenAnswer((_) async {});

      await repository.deleteWidget('w-1');

      verify(() => mockSharedStore.notifyWidgetsUpdated()).called(1);

      final captured = verify(
        () => mockSharedStore.saveString(
          StorageKeys.widgetDefinitionsKey,
          captureAny(),
        ),
      ).captured;

      final saved =
          json.decode(captured.first as String) as Map<String, dynamic>;
      final list = saved['widgets'] as List<dynamic>;
      expect(list, isEmpty);
    });
  });
}
