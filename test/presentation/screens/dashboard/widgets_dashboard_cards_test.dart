import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/app.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/dashboard/widgets_dashboard_screen.dart';

class MockWidgetRepo extends Mock implements WidgetDefinitionRepository {}

class MockConnRepo extends Mock implements ConnectionRepository {}

class MockApi extends Mock implements InfluxApiClient {}

class MockStore extends Mock implements SharedWidgetStore {}

void main() {
  final widgets = [
    for (final type in WidgetType.values)
      WidgetDefinition(
        id: 'w-${type.wireName}',
        type: type,
        title: 'Card ${type.label}',
        connectionId: 'c',
        measurement: 'climate',
        field: 'temp',
        refreshIntervalMinutes: 30,
      ),
  ];

  Future<void> pump(WidgetTester tester, Brightness brightness) async {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final widgetRepo = MockWidgetRepo();
    final connRepo = MockConnRepo();
    when(() => widgetRepo.getWidgets()).thenAnswer((_) async => widgets);
    when(() => connRepo.getConnections()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          widgetDefinitionRepositoryProvider.overrideWithValue(widgetRepo),
          connectionRepositoryProvider.overrideWithValue(connRepo),
          influxApiClientProvider.overrideWithValue(MockApi()),
          sharedWidgetStoreProvider.overrideWithValue(MockStore()),
        ],
        child: const SensorWidgetsApp(home: WidgetsDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    testWidgets('dashboard cards render for every type ($brightness)', (
      tester,
    ) async {
      await pump(tester, brightness);

      for (final type in WidgetType.values) {
        expect(find.text('Card ${type.label}'), findsOneWidget);
        expect(
          find.byKey(Key('dashboard_card_preview_w-${type.wireName}')),
          findsOneWidget,
          reason: 'mini preview for ${type.label}',
        );
      }
      // Type label chip plus refresh info are part of every card.
      expect(find.textContaining('alle 30m'), findsNWidgets(6));
    });
  }

  testWidgets('empty state offers creating the first widget', (tester) async {
    widgets.clear();
    addTearDown(() {});
    await pump(tester, Brightness.light);
    expect(find.text('Noch keine Widgets konfiguriert'), findsOneWidget);
    expect(find.text('Neues Widget anlegen'), findsOneWidget);
  });
}
