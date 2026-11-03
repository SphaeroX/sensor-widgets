import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/editor/widget_editor_screen.dart';

class _MockWidgetRepo extends Mock implements WidgetDefinitionRepository {}

class _MockConnRepo extends Mock implements ConnectionRepository {}

class _MockApi extends Mock implements InfluxApiClient {}

class _MockStore extends Mock implements SharedWidgetStore {}

const _code = '''
{
  "type": "history_chart",
  "title": "Luft",
  "measurement": "sensors",
  "timeRange": "7d",
  "aggregationInterval": "1h",
  "formula": "min(s_a, s_b)",
  "formulaSteps": [
    {"name": "s_a", "expression": "clamp(t1, 0, 100)"},
    {"name": "s_b", "expression": "clamp(t2, 0, 100)"}
  ],
  "formulaVariables": [
    {"name": "t1", "field": "t1"},
    {"name": "t2", "field": "t2"}
  ]
}''';

void main() {
  late _MockWidgetRepo repo;
  late _MockConnRepo connRepo;
  late _MockApi api;
  late _MockStore store;

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
    api = _MockApi();
    store = _MockStore();
    when(() => connRepo.getConnections()).thenAnswer((_) async => [conn]);
    when(() => connRepo.getConnection('conn-1')).thenAnswer((_) async => conn);
    when(() => connRepo.getToken('conn-1')).thenAnswer((_) async => 't');
    when(() => repo.getWidgets()).thenAnswer((_) async => []);
    when(() => repo.saveWidget(any())).thenAnswer((_) async {});
    when(() => store.notifyWidgetsUpdated()).thenAnswer((_) async {});
    when(() => api.fetchMeasurements(connection: conn, token: 't'))
        .thenAnswer((_) async => ['sensors']);
    when(
      () => api.fetchFieldInfos(
        connection: conn,
        token: 't',
        measurement: 'sensors',
      ),
    ).thenAnswer(
      (_) async => [
        const InfluxFieldInfo(key: 't1', type: 'float'),
        const InfluxFieldInfo(key: 't2', type: 'float'),
      ],
    );
  });

  Widget app() => ProviderScope(
    overrides: [
      widgetDefinitionRepositoryProvider.overrideWithValue(repo),
      connectionRepositoryProvider.overrideWithValue(connRepo),
      influxApiClientProvider.overrideWithValue(api),
      sharedWidgetStoreProvider.overrideWithValue(store),
    ],
    child: const MaterialApp(home: WidgetEditorScreen()),
  );

  Future<void> enableFormula(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    final field = find.byKey(const Key('widget_code_field'));
    await tester.ensureVisible(field);
    await tester.enterText(field, code);
    await tester.pump();
  }

  String formulaText(WidgetTester tester) => tester
      .widget<TextFormField>(find.byKey(const Key('formula_input_field')))
      .controller!
      .text;

  testWidgets('code area only appears once the formula is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('widget_code_field')), findsNothing);

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('widget_code_field')), findsOneWidget);
  });

  testWidgets('code area is multi-line and shows the current widget', (
    tester,
  ) async {
    await enableFormula(tester);
    final field = tester.widget<TextField>(
      find.byKey(const Key('widget_code_field')),
    );
    expect(field.minLines, greaterThanOrEqualTo(8));
    expect(field.maxLines, greaterThan(field.minLines!));
    expect(field.controller!.text, contains('"type": "single_value"'));
  });

  testWidgets('applying valid code fills the editor and saves the widget', (
    tester,
  ) async {
    await enableFormula(tester);
    await enterCode(tester, _code);
    final apply = find.byKey(const Key('widget_code_apply_button'));
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();

    expect(find.text('Variable t1'), findsOneWidget);
    expect(find.text('Variable t2'), findsOneWidget);
    expect(formulaText(tester), 'min(s_a, s_b)');

    await tester.tap(find.byKey(const Key('save_widget_button')));
    await tester.pumpAndSettle();

    final saved =
        verify(() => repo.saveWidget(captureAny())).captured.last
            as WidgetDefinition;
    expect(saved.type, WidgetType.historyChart);
    expect(saved.title, 'Luft');
    expect(saved.connectionId, 'conn-1');
    expect(saved.measurement, 'sensors');
    expect(saved.timeRange, '7d');
    expect(saved.formula, 'min(s_a, s_b)');
    expect(saved.formulaSteps!.map((s) => s.name), ['s_a', 's_b']);
    expect(saved.formulaVariables!.map((v) => v.field), ['t1', 't2']);
  });

  testWidgets('invalid code shows the errors and changes nothing', (
    tester,
  ) async {
    await enableFormula(tester);
    await enterCode(
      tester,
      '{"type":"single_value","formula":"A +","formulaVariables":'
      '[{"name":"A","field":"t1"}]}',
    );
    final apply = find.byKey(const Key('widget_code_apply_button'));
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('widget_code_errors')), findsOneWidget);
    expect(find.textContaining('Syntaxfehler'), findsWidgets);
    expect(formulaText(tester), isEmpty);
  });

  testWidgets('copy button puts a widget-code prompt on the clipboard', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await enableFormula(tester);
    final button = find.byKey(const Key('copy_widget_prompt_button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(copied, contains('Widget-Code (JSON)'));
    expect(copied, contains('Antworte jetzt nur mit "OK"'));
    expect(copied, contains('"type": "single_value"'));
  });
}
