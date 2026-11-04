import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/dashboard/widgets_dashboard_screen.dart';

import 'english_locale.dart';

class _MockWidgetRepo extends Mock implements WidgetDefinitionRepository {}

class _MockConnectionRepo extends Mock implements ConnectionRepository {}

class _MockApiClient extends Mock implements InfluxApiClient {}

class _MockSharedStore extends Mock implements SharedWidgetStore {}

void main() {
  useEnglishDeviceLocale();

  late _MockWidgetRepo widgetRepo;
  late _MockConnectionRepo connectionRepo;

  setUp(() {
    widgetRepo = _MockWidgetRepo();
    connectionRepo = _MockConnectionRepo();
    when(() => connectionRepo.getConnections()).thenAnswer((_) async => []);
  });

  Widget app() => ProviderScope(
    overrides: [
      widgetDefinitionRepositoryProvider.overrideWithValue(widgetRepo),
      connectionRepositoryProvider.overrideWithValue(connectionRepo),
      influxApiClientProvider.overrideWithValue(_MockApiClient()),
      sharedWidgetStoreProvider.overrideWithValue(_MockSharedStore()),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: WidgetsDashboardScreen(),
    ),
  );

  testWidgets('empty dashboard is English', (tester) async {
    when(() => widgetRepo.getWidgets()).thenAnswer((_) async => []);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('No widgets configured yet'), findsOneWidget);
    expect(find.text('Create your first home-screen widget!'), findsOneWidget);
    expect(find.text('Create widget'), findsOneWidget);
    expect(find.byTooltip('Sync native widgets'), findsOneWidget);
    expect(find.byTooltip('Formula help'), findsOneWidget);
    expect(find.byTooltip('InfluxDB connections'), findsOneWidget);
  });

  testWidgets('widget card and its menu are English', (tester) async {
    when(() => widgetRepo.getWidgets()).thenAnswer(
      (_) async => const [
        WidgetDefinition(
          id: 'w-1',
          type: WidgetType.singleValue,
          title: 'Living Room',
          connectionId: 'c-1',
          measurement: 'climate',
          field: 'temp',
          refreshIntervalMinutes: 15,
        ),
      ],
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('climate • every 15 min'), findsOneWidget);
    await tester.tap(find.byTooltip('Actions'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });
}
