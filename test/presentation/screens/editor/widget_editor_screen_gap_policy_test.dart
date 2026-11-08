import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/editor/widget_editor_screen.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

import '../../../helpers/editor_sections.dart';

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
    measurement: 'climate',
    field: 'iaq',
    timeRange: '24h',
    aggregationInterval: '1h',
    formula: 'A',
    formulaVariables: [FormulaVariable(name: 'A', field: 'temp')],
  );

  Future<WidgetDefinition> saveAndCapture(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('save_widget_button')));
    await tester.tap(find.byKey(const Key('save_widget_button')));
    await tester.pumpAndSettle();
    return verify(() => widgetRepo.saveWidget(captureAny())).captured.last
        as WidgetDefinition;
  }

  testWidgets('"previous" can be chosen and is saved', (tester) async {
    await tester.pumpWidget(app(history));
    await tester.pumpAndSettle();

    await openEditorSection(tester, 'type_settings');
    await tester.ensureVisible(find.byKey(const Key('gap_policy_previous')));
    await tester.tap(find.byKey(const Key('gap_policy_previous')));
    await tester.pumpAndSettle();

    expect((await saveAndCapture(tester)).gapPolicy, 'previous');
  });

  testWidgets('the default (skip) is not written to the definition', (
    tester,
  ) async {
    await tester.pumpWidget(app(history));
    await tester.pumpAndSettle();
    await openEditorSection(tester, 'type_settings');
    expect(find.byKey(const Key('gap_policy_skip')), findsOneWidget);

    expect((await saveAndCapture(tester)).gapPolicy, isNull);
  });

  testWidgets('an existing gap policy is shown as selected', (tester) async {
    await tester.pumpWidget(app(history.copyWith(gapPolicy: 'previous')));
    await tester.pumpAndSettle();

    await openEditorSection(tester, 'type_settings');
    final chip = tester.widget<ChoiceChip>(
      find.byKey(const Key('gap_policy_previous')),
    );
    expect(chip.selected, isTrue);
    expect((await saveAndCapture(tester)).gapPolicy, 'previous');
  });

  testWidgets('hidden for widgets without time buckets or formula', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const WidgetDefinition(
          id: 's',
          type: WidgetType.singleValue,
          title: 'S',
          connectionId: 'conn-1',
          measurement: 'climate',
          field: 'temp',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('gap_policy_previous'), skipOffstage: false),
      findsNothing,
    );

    await tester.pumpWidget(
      app(history.copyWith(formula: '', formulaVariables: const []).copyWith()),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('gap_policy_previous'), skipOffstage: false),
      findsNothing,
    );
  });
}
