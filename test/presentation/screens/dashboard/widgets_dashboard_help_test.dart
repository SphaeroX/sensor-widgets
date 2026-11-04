import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/dashboard/widgets_dashboard_screen.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

class MockWidgetRepo extends Mock implements WidgetDefinitionRepository {}

class MockConnRepo extends Mock implements ConnectionRepository {}

class MockApi extends Mock implements InfluxApiClient {}

class MockStore extends Mock implements SharedWidgetStore {}

void main() {
  testWidgets('dashboard app bar opens the formula help', (tester) async {
    final widgetRepo = MockWidgetRepo();
    final connRepo = MockConnRepo();
    when(() => widgetRepo.getWidgets()).thenAnswer((_) async => []);
    when(() => connRepo.getConnections()).thenAnswer((_) async => []);

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
          home: WidgetsDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_formula_help_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Formel-Hilfe'), findsOneWidget);
  });
}
