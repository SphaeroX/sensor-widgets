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

/// Task_21 regression: the list must start below the app bar, scroll cleanly
/// and not hide its last card behind the floating action button, also with
/// system insets (edge-to-edge) on a small screen.
void main() {
  Future<void> pump(WidgetTester tester, int count) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 48, bottom: 48);
    tester.view.viewPadding = tester.view.padding;
    addTearDown(tester.view.reset);

    final widgetRepo = MockWidgetRepo();
    final connRepo = MockConnRepo();
    when(() => widgetRepo.getWidgets()).thenAnswer(
      (_) async => [
        for (var i = 0; i < count; i++)
          WidgetDefinition(
            id: 'w$i',
            type: WidgetType.multiValue,
            title: 'Widget $i',
            connectionId: 'c',
            measurement: 'environment',
          ),
      ],
    );
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

  for (final count in [1, 3, 12]) {
    testWidgets('first card starts below the app bar ($count widgets)', (
      tester,
    ) async {
      await pump(tester, count);

      final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
      final firstCard = tester.getTopLeft(find.byType(Card).first).dy;
      expect(firstCard, greaterThanOrEqualTo(appBarBottom));
    });
  }

  testWidgets('the last card can be scrolled clear of the floating button', (
    tester,
  ) async {
    await pump(tester, 12);

    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();

    final lastCard = tester.getRect(find.text('Widget 11'));
    final fab = tester.getRect(find.byKey(const Key('add_widget_fab')));
    expect(lastCard.bottom, lessThanOrEqualTo(fab.top));
  });
}
