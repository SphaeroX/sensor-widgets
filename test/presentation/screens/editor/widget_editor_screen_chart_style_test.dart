import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/chart_style.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/editor/widget_editor_screen.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

class MockWidgetRepo extends Mock implements WidgetDefinitionRepository {}

class MockConnRepo extends Mock implements ConnectionRepository {}

class MockApi extends Mock implements InfluxApiClient {}

class MockStore extends Mock implements SharedWidgetStore {}

void main() {
  const conn = InfluxConnection(
    id: 'conn-1',
    name: 'Server',
    url: 'https://example.com',
    database: 'sensors',
  );
  late MockWidgetRepo widgetRepo;
  late MockConnRepo connRepo;
  late MockApi api;

  setUpAll(() {
    registerFallbackValue(conn);
    registerFallbackValue(
      const WidgetDefinition(
        id: 'd',
        type: WidgetType.singleValue,
        title: 'D',
        connectionId: 'conn-1',
        measurement: 'm',
      ),
    );
  });

  setUp(() {
    widgetRepo = MockWidgetRepo();
    connRepo = MockConnRepo();
    api = MockApi();
    when(() => connRepo.getConnections()).thenAnswer((_) async => [conn]);
    when(() => connRepo.getConnection('conn-1')).thenAnswer((_) async => conn);
    when(() => connRepo.getToken('conn-1')).thenAnswer((_) async => 'tok');
    when(() => widgetRepo.getWidgets()).thenAnswer((_) async => []);
    when(() => widgetRepo.saveWidget(any())).thenAnswer((_) async {});
    when(
      () => api.fetchMeasurements(
        connection: any(named: 'connection'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => ['sen66']);
    when(
      () => api.fetchFieldInfos(
        connection: any(named: 'connection'),
        token: any(named: 'token'),
        measurement: any(named: 'measurement'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => api.fetchTagKeys(
        connection: any(named: 'connection'),
        token: any(named: 'token'),
        measurement: any(named: 'measurement'),
      ),
    ).thenAnswer((_) async => []);
  });

  Widget app(WidgetDefinition edit) {
    final store = MockStore();
    when(() => store.notifyWidgetsUpdated()).thenAnswer((_) async {});
    return ProviderScope(
      key: UniqueKey(),
      overrides: [
        widgetDefinitionRepositoryProvider.overrideWithValue(widgetRepo),
        connectionRepositoryProvider.overrideWithValue(connRepo),
        influxApiClientProvider.overrideWithValue(api),
        sharedWidgetStoreProvider.overrideWithValue(store),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WidgetEditorScreen(widgetToEdit: edit),
      ),
    );
  }

  const history = WidgetDefinition(
    id: 'h',
    type: WidgetType.historyChart,
    title: 'IAQ',
    connectionId: 'conn-1',
    measurement: 'sen66',
    field: 'iaq',
    timeRange: '24h',
    aggregationInterval: '1h',
  );

  testWidgets('history editor offers the chart style and saves it', (
    tester,
  ) async {
    await tester.pumpWidget(app(history));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('chart_style_editor')));
    expect(find.byKey(const Key('chart_style_editor')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('preset_green_to_red')));
    await tester.tap(find.byKey(const Key('preset_green_to_red')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('chart_fill_switch')));
    await tester.tap(find.byKey(const Key('chart_fill_switch')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('save_widget_button')));
    await tester.tap(find.byKey(const Key('save_widget_button')));
    await tester.pumpAndSettle();

    final saved =
        verify(() => widgetRepo.saveWidget(captureAny())).captured.last
            as WidgetDefinition;
    expect(saved.chartStyle!.fillArea, isTrue);
    expect(saved.chartStyle!.colorStops.first.color, '#4CAF50');
  });

  testWidgets('other widget types do not show or save a chart style', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(history.copyWith(chartStyle: const ChartStyle(fillArea: true))),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chart_style_editor')), findsOneWidget);

    await tester.pumpWidget(
      app(
        const WidgetDefinition(
          id: 's',
          type: WidgetType.singleValue,
          title: 'S',
          connectionId: 'conn-1',
          measurement: 'sen66',
          field: 'iaq',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chart_style_editor')), findsNothing);
  });
}
