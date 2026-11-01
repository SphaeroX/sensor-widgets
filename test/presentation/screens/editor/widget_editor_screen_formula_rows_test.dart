import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/domain/models/sensor_query_item.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/editor/widget_editor_screen.dart';

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
  late MockStore store;

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
    store = MockStore();
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
    ).thenAnswer((_) async => ['room']);
    when(
      () => api.fetchFieldInfos(
        connection: any(named: 'connection'),
        token: any(named: 'token'),
        measurement: any(named: 'measurement'),
      ),
    ).thenAnswer(
      (_) async => [
        const InfluxFieldInfo(key: 'temp', type: 'float'),
        const InfluxFieldInfo(key: 'voc', type: 'float'),
      ],
    );
    when(
      () => api.fetchTagKeys(
        connection: any(named: 'connection'),
        token: any(named: 'token'),
        measurement: any(named: 'measurement'),
      ),
    ).thenAnswer((_) async => []);
  });

  Widget app(WidgetDefinition? edit) => ProviderScope(
    overrides: [
      widgetDefinitionRepositoryProvider.overrideWithValue(widgetRepo),
      connectionRepositoryProvider.overrideWithValue(connRepo),
      influxApiClientProvider.overrideWithValue(api),
      sharedWidgetStoreProvider.overrideWithValue(store),
    ],
    child: MaterialApp(home: WidgetEditorScreen(widgetToEdit: edit)),
  );

  const multi = WidgetDefinition(
    id: 'w1',
    type: WidgetType.multiValue,
    title: 'Room',
    connectionId: 'conn-1',
    measurement: 'room',
    items: [
      SensorQueryItem(field: 'temp', label: 'Temp'),
      SensorQueryItem(
        field: 'iaq',
        label: 'IAQ',
        formula: 'min(idx, 100)',
        formulaVariables: [FormulaVariable(name: 'A', field: 'voc')],
        formulaSteps: [FormulaStep(name: 'idx', expression: '100 - A')],
      ),
    ],
  );

  testWidgets('multi-value editor lists existing formula rows separately', (
    tester,
  ) async {
    await tester.pumpWidget(app(multi));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('multi_formula_rows_section')),
    );
    expect(find.byKey(const Key('multi_formula_rows_section')), findsOneWidget);
    expect(find.byKey(const Key('formula_row_0')), findsOneWidget);
    expect(find.byKey(const Key('formula_input_field')), findsOneWidget);
  });

  testWidgets('a new formula row can be added and is saved with the widget', (
    tester,
  ) async {
    await tester.pumpWidget(app(multi));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('add_formula_row_button')));
    await tester.tap(find.byKey(const Key('add_formula_row_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('formula_row_1')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('formula_row_label_1')),
      'Komfort',
    );
    await tester.enterText(
      find
          .descendant(
            of: find.byKey(const Key('formula_row_1')),
            matching: find.byKey(const Key('formula_input_field')),
          )
          .first,
      'A * 2',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('save_widget_button')));
    await tester.tap(find.byKey(const Key('save_widget_button')));
    await tester.pumpAndSettle();

    final saved =
        verify(() => widgetRepo.saveWidget(captureAny())).captured.last
            as WidgetDefinition;
    final items = saved.items!;
    expect(items.map((i) => i.field), containsAll(['temp', 'iaq']));
    final newRow = items.firstWhere((i) => i.label == 'Komfort');
    expect(newRow.formula, 'A * 2');
    expect(newRow.formulaVariables, isNotEmpty);
    expect(newRow.field, isNot('temp'));
    expect(items.map((i) => i.field).toSet(), hasLength(items.length));
  });

  testWidgets('formula section is also available for gauge widgets', (
    tester,
  ) async {
    const gauge = WidgetDefinition(
      id: 'g',
      type: WidgetType.gaugeBar,
      title: 'Gauge',
      connectionId: 'conn-1',
      measurement: 'room',
      field: 'temp',
      min: 0,
      max: 100,
    );
    await tester.pumpWidget(app(gauge));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('formula_enabled_switch')), findsOneWidget);
  });
}
