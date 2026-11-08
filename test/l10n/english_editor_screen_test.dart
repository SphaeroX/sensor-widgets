import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/editor/widget_editor_screen.dart';
import 'package:sensor_widgets/presentation/widgets/preview/widget_live_preview_card.dart';

import 'english_locale.dart';

import '../helpers/editor_sections.dart';

class _MockWidgetRepo extends Mock implements WidgetDefinitionRepository {}

class _MockConnectionRepo extends Mock implements ConnectionRepository {}

class _MockApiClient extends Mock implements InfluxApiClient {}

class _MockSharedStore extends Mock implements SharedWidgetStore {}

const _conn = InfluxConnection(
  id: 'conn-1',
  name: 'Server',
  url: 'https://example.com',
  database: 'sensors',
);

void main() {
  useEnglishDeviceLocale();

  late _MockConnectionRepo connectionRepo;
  late _MockApiClient apiClient;

  setUp(() {
    connectionRepo = _MockConnectionRepo();
    apiClient = _MockApiClient();
    when(() => connectionRepo.getConnections())
        .thenAnswer((_) async => [_conn]);
    when(() => connectionRepo.getConnection('conn-1'))
        .thenAnswer((_) async => null);
    when(() => connectionRepo.getToken('conn-1'))
        .thenAnswer((_) async => 'token');
  });

  ProviderScope app(Widget home) {
    final widgetRepo = _MockWidgetRepo();
    when(() => widgetRepo.getWidgets()).thenAnswer((_) async => []);
    return ProviderScope(
      overrides: [
        widgetDefinitionRepositoryProvider.overrideWithValue(widgetRepo),
        connectionRepositoryProvider.overrideWithValue(connectionRepo),
        influxApiClientProvider.overrideWithValue(apiClient),
        sharedWidgetStoreProvider.overrideWithValue(_MockSharedStore()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  testWidgets('editor screen is English', (tester) async {
    await tester.pumpWidget(app(const WidgetEditorScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Configure widget'), findsOneWidget);
    expect(find.text('Basic settings'), findsOneWidget);
    expect(find.text('Widget title'), findsOneWidget);
    expect(find.text('Data source (InfluxQL)'), findsOneWidget);
    expect(find.text('Load preview'), findsOneWidget);
    expect(find.textContaining('No preview loaded yet.'), findsOneWidget);
    // The connection lookup fails, so schema discovery reports it in English.
    await openEditorSection(tester, 'data_source');
    expect(find.textContaining('Connection not found.'), findsWidgets);
    expect(find.textContaining('Verbindung'), findsNothing);
  });

  testWidgets('history settings list English durations', (tester) async {
    await tester.pumpWidget(
      app(
        const WidgetEditorScreen(
          widgetToEdit: WidgetDefinition(
            id: 'w',
            type: WidgetType.historyChart,
            title: 'Temp',
            connectionId: 'conn-1',
            measurement: 'climate',
            field: 'temp',
            timeRange: '24h',
            aggregationInterval: '1h',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await openEditorSection(tester, 'type_settings');
    expect(find.text('History settings'), findsOneWidget);
    expect(find.text('24 hours'), findsOneWidget);
    expect(find.text('1 hour'), findsOneWidget);
  });

  testWidgets('preview reports a missing connection in English', (
    tester,
  ) async {
    late WidgetPreviewData preview;
    await tester.pumpWidget(
      app(
        Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () async {
              preview = await ref
                  .read(widgetsControllerProvider.notifier)
                  .fetchPreviewData(
                    const WidgetDefinition(
                      id: 'w',
                      type: WidgetType.singleValue,
                      title: 'T',
                      connectionId: 'conn-1',
                      measurement: 'm',
                      field: 'f',
                    ),
                  );
            },
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(preview.errorMessage, 'Connection not found.');

    await tester.pumpWidget(
      app(
        Scaffold(
          body: WidgetLivePreviewCard(
            widgetDef: const WidgetDefinition(
              id: 'w',
              type: WidgetType.indicatorLamp,
              title: '',
              connectionId: 'conn-1',
              measurement: 'm',
              field: 'f',
            ),
            previewData: WidgetPreviewData(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Widget preview'), findsOneWidget);
    expect(find.text('No threshold configured'), findsOneWidget);
  });
}
