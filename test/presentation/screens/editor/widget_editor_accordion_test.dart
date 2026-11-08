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
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/editor/widget_editor_screen.dart';

import '../../../helpers/editor_sections.dart';

class _MockWidgetRepo extends Mock implements WidgetDefinitionRepository {}

class _MockConnRepo extends Mock implements ConnectionRepository {}

class _MockApi extends Mock implements InfluxApiClient {}

class _MockStore extends Mock implements SharedWidgetStore {}

void main() {
  late _MockWidgetRepo repo;
  late _MockConnRepo connRepo;

  const conn = InfluxConnection(
    id: 'conn-1',
    name: 'Server',
    url: 'https://example.com',
    database: 'sensors',
  );

  setUpAll(() {
    registerFallbackValue(
      const WidgetDefinition(
        id: 'dummy',
        type: WidgetType.singleValue,
        title: 'Dummy',
        connectionId: 'conn-1',
        measurement: 'temp',
      ),
    );
  });

  setUp(() {
    repo = _MockWidgetRepo();
    connRepo = _MockConnRepo();
    when(() => connRepo.getConnections()).thenAnswer((_) async => [conn]);
    when(() => connRepo.getConnection('conn-1')).thenAnswer((_) async => conn);
    when(() => connRepo.getToken('conn-1')).thenAnswer((_) async => 't');
    when(() => repo.getWidgets()).thenAnswer((_) async => []);
    when(() => repo.saveWidget(any())).thenAnswer((_) async {});
  });

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          widgetDefinitionRepositoryProvider.overrideWithValue(repo),
          connectionRepositoryProvider.overrideWithValue(connRepo),
          influxApiClientProvider.overrideWithValue(_MockApi()),
          sharedWidgetStoreProvider.overrideWithValue(_MockStore()),
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

  Finder header(String id) => find.byKey(Key('editor_section_$id'));

  testWidgets('every section has a header and only the basics are open', (
    tester,
  ) async {
    await pumpEditor(tester);

    for (final id in [
      'basics',
      'data_source',
      'code',
      'appearance',
      'alerts',
    ]) {
      await tester.ensureVisible(header(id));
      expect(header(id), findsOneWidget, reason: id);
    }
    expect(find.byKey(const Key('widget_title_field')), findsOneWidget);
    expect(find.byKey(const Key('widget_measurement_field')), findsNothing);
    expect(find.byKey(const Key('widget_code_field')), findsNothing);
    expect(find.byKey(const Key('appearance_editor')), findsNothing);
    expect(find.byKey(const Key('alert_add_button')), findsNothing);
  });

  testWidgets('opening a section closes the one that was open', (tester) async {
    await pumpEditor(tester);

    await openEditorSection(tester, 'data_source');

    expect(find.byKey(const Key('widget_measurement_field')), findsOneWidget);
    expect(find.byKey(const Key('widget_title_field')), findsNothing);

    await openEditorSection(tester, 'code');

    expect(find.byKey(const Key('widget_code_field')), findsOneWidget);
    expect(find.byKey(const Key('widget_measurement_field')), findsNothing);
  });

  testWidgets('tapping the open section closes it', (tester) async {
    await pumpEditor(tester);

    await tester.tap(header('basics'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('widget_title_field')), findsNothing);
  });

  testWidgets('values typed in a closed section are kept', (tester) async {
    await pumpEditor(tester);
    await tester.enterText(
      find.byKey(const Key('widget_title_field')),
      'Wohnzimmer',
    );
    await openEditorSection(tester, 'data_source');
    await openEditorSection(tester, 'basics');

    expect(find.text('Wohnzimmer'), findsWidgets);
  });

  testWidgets('saving with a missing measurement opens the data source', (
    tester,
  ) async {
    await pumpEditor(tester);
    await tester.enterText(
      find.byKey(const Key('widget_title_field')),
      'Wohnzimmer',
    );

    await tester.tap(find.byKey(const Key('save_widget_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('widget_measurement_field')), findsOneWidget);
    expect(find.text('Bitte Measurement eingeben'), findsOneWidget);
    verifyNever(() => repo.saveWidget(any()));
  });

  testWidgets('saving without a title opens the basics', (tester) async {
    await pumpEditor(tester);
    await openEditorSection(tester, 'data_source');

    await tester.tap(find.byKey(const Key('save_widget_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('widget_title_field')), findsOneWidget);
    verifyNever(() => repo.saveWidget(any()));
  });

  testWidgets('type settings only appear for types that have some', (
    tester,
  ) async {
    await pumpEditor(tester);
    expect(header('type_settings'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const Key('type_tile_history_chart')),
    );
    await tester.tap(find.byKey(const Key('type_tile_history_chart')));
    await tester.pumpAndSettle();
    await openEditorSection(tester, 'type_settings');

    expect(find.byKey(const Key('history_timerange_field')), findsOneWidget);
    expect(find.byKey(const Key('chart_style_editor')), findsOneWidget);
  });
}
