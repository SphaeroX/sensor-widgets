import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/widget_appearance.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/editor/widget_editor_screen.dart';
import 'package:sensor_widgets/presentation/widgets/editor/appearance_editor.dart';
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

  Widget app(WidgetDefinition edit) {
    widgetRepo = MockWidgetRepo();
    final connRepo = MockConnRepo();
    final api = MockApi();
    final store = MockStore();
    when(() => connRepo.getConnections()).thenAnswer((_) async => [conn]);
    when(() => connRepo.getConnection('conn-1')).thenAnswer((_) async => conn);
    when(() => connRepo.getToken('conn-1')).thenAnswer((_) async => 'tok');
    when(() => widgetRepo.getWidgets()).thenAnswer((_) async => []);
    when(() => widgetRepo.saveWidget(any())).thenAnswer((_) async {});
    when(() => store.notifyWidgetsUpdated()).thenAnswer((_) async {});
    when(
      () => api.fetchMeasurements(
        connection: any(named: 'connection'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => ['climate']);
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
    return ProviderScope(
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

  const base = WidgetDefinition(
    id: 'w1',
    type: WidgetType.singleValue,
    title: 'Wohnzimmer',
    connectionId: 'conn-1',
    measurement: 'climate',
    field: 'temp',
  );

  testWidgets('appearance can be edited and is saved with the widget', (
    tester,
  ) async {
    await tester.pumpWidget(app(base));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('appearance_editor')));
    await tester.ensureVisible(find.byKey(const Key('palette_accent_3')));
    await tester.tap(find.byKey(const Key('palette_accent_3')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('save_widget_button')));
    await tester.tap(find.byKey(const Key('save_widget_button')));
    await tester.pumpAndSettle();

    final saved =
        verify(() => widgetRepo.saveWidget(captureAny())).captured.last
            as WidgetDefinition;
    expect(saved.appearance!.accentColor, AppearanceEditor.palette[3]);
  });

  testWidgets('an existing appearance is loaded and kept when saving', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        base.copyWith(
          appearance: const WidgetAppearance(
            backgroundColor: '#102030',
            fontScale: 1.2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('save_widget_button')));
    await tester.tap(find.byKey(const Key('save_widget_button')));
    await tester.pumpAndSettle();

    final saved =
        verify(() => widgetRepo.saveWidget(captureAny())).captured.last
            as WidgetDefinition;
    expect(saved.appearance!.backgroundColor, '#102030');
    expect(saved.appearance!.fontScale, 1.2);
  });

  testWidgets('untouched widgets save without an appearance block', (
    tester,
  ) async {
    await tester.pumpWidget(app(base));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('save_widget_button')));
    await tester.tap(find.byKey(const Key('save_widget_button')));
    await tester.pumpAndSettle();

    final saved =
        verify(() => widgetRepo.saveWidget(captureAny())).captured.last
            as WidgetDefinition;
    expect(saved.appearance, isNull);
  });
}
