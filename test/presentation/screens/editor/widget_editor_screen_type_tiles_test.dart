import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/editor/widget_editor_screen.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

class MockWidgetRepo extends Mock implements WidgetDefinitionRepository {}

class MockConnRepo extends Mock implements ConnectionRepository {}

class MockApi extends Mock implements InfluxApiClient {}

class MockStore extends Mock implements SharedWidgetStore {}

void main() {
  Future<void> pump(WidgetTester tester) async {
    final widgetRepo = MockWidgetRepo();
    final connRepo = MockConnRepo();
    when(() => widgetRepo.getWidgets()).thenAnswer((_) async => []);
    when(() => connRepo.getConnections()).thenAnswer(
      (_) async => [
        const InfluxConnection(
          id: 'conn-1',
          name: 'Server',
          url: 'https://example.com',
          database: 'db',
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          widgetDefinitionRepositoryProvider.overrideWithValue(widgetRepo),
          connectionRepositoryProvider.overrideWithValue(connRepo),
          influxApiClientProvider.overrideWithValue(MockApi()),
          sharedWidgetStoreProvider.overrideWithValue(MockStore()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WidgetEditorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('type tiles switch the type-specific settings', (tester) async {
    await pump(tester);

    await tester.ensureVisible(
      find.byKey(const Key('type_tile_history_chart')),
    );
    await tester.tap(find.byKey(const Key('type_tile_history_chart')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history_timerange_field')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('type_tile_indicator_lamp')),
    );
    await tester.tap(find.byKey(const Key('type_tile_indicator_lamp')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('indicator_threshold_field')), findsOneWidget);
  });

  testWidgets('editor sections have headings', (tester) async {
    await pump(tester);
    expect(find.text('Basis-Einstellungen'), findsOneWidget);
    expect(find.text('Widget-Typ'), findsOneWidget);
    expect(find.byKey(const Key('widget_type_dropdown')), findsNothing);
  });
}
