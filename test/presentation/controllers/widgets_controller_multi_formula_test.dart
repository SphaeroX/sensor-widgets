import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/sensor_query_item.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';

class MockWidgetRepo extends Mock implements WidgetDefinitionRepository {}

class MockConnRepo extends Mock implements ConnectionRepository {}

class MockApi extends Mock implements InfluxApiClient {}

class MockStore extends Mock implements SharedWidgetStore {}

Map<String, dynamic> _latest(List<String> columns, List<Object?> row) => {
  'results': [
    {
      'statement_id': 0,
      'series': [
        {
          'name': 'room',
          'columns': ['time', ...columns],
          'values': [
            [1730370000000, ...row],
          ],
        },
      ],
    },
  ],
};

void main() {
  const conn = InfluxConnection(
    id: 'c',
    name: 'x',
    url: 'https://example.com',
    database: 'db',
  );
  late MockApi api;
  late ProviderContainer container;

  setUp(() {
    api = MockApi();
    final widgetRepo = MockWidgetRepo();
    final connRepo = MockConnRepo();
    final store = MockStore();
    when(() => widgetRepo.getWidgets()).thenAnswer((_) async => []);
    when(() => connRepo.getConnection('c')).thenAnswer((_) async => conn);
    when(() => connRepo.getToken('c')).thenAnswer((_) async => 'tok');
    when(() => store.notifyWidgetsUpdated()).thenAnswer((_) async {});
    when(
      () => api.query(
        connection: conn,
        token: 'tok',
        influxQl: any(named: 'influxQl'),
      ),
    ).thenAnswer((invocation) async {
      final q = invocation.namedArguments[#influxQl] as String;
      if (q.contains('"zero"')) return _latest(['zero'], [0.0]);
      if (q.contains('"voc"')) return _latest(['voc'], [50.0]);
      return _latest(['temp', 'hum'], [21.5, 40.0]);
    });
    container = ProviderContainer(
      overrides: [
        widgetDefinitionRepositoryProvider.overrideWithValue(widgetRepo),
        connectionRepositoryProvider.overrideWithValue(connRepo),
        influxApiClientProvider.overrideWithValue(api),
        sharedWidgetStoreProvider.overrideWithValue(store),
      ],
    );
  });

  tearDown(() => container.dispose());

  WidgetDefinition widget(List<SensorQueryItem> items) => WidgetDefinition(
    id: 'w',
    type: WidgetType.multiValue,
    title: 'Room',
    connectionId: 'c',
    measurement: 'room',
    items: items,
  );

  Future<WidgetPreviewData> preview(List<SensorQueryItem> items) async {
    final controller = container.read(widgetsControllerProvider.notifier);
    await container.read(widgetsControllerProvider.future);
    return controller.fetchPreviewData(widget(items));
  }

  test('formula row shows its result, plain rows stay unchanged', () async {
    final data = await preview(const [
      SensorQueryItem(field: 'temp'),
      SensorQueryItem(field: 'hum'),
      SensorQueryItem(
        field: 'iaq',
        formula: '100 - a * 0.6',
        formulaVariables: [FormulaVariable(name: 'a', field: 'voc')],
      ),
    ]);

    expect(data.hasError, isFalse);
    expect(data.multiValues!['temp']!.value, 21.5);
    expect(data.multiValues!['hum']!.value, 40.0);
    expect(data.multiValues!['iaq']!.value, 70.0);
    expect(data.multiErrors, anyOf(isNull, isEmpty));
  });

  test('error in one row does not block the other rows', () async {
    final data = await preview(const [
      SensorQueryItem(field: 'temp'),
      SensorQueryItem(
        field: 'ratio',
        formula: '1 / z',
        formulaVariables: [FormulaVariable(name: 'z', field: 'zero')],
      ),
    ]);

    expect(data.hasError, isFalse);
    expect(data.multiValues!['temp']!.value, 21.5);
    expect(data.multiValues!.containsKey('ratio'), isFalse);
    expect(data.multiErrors!['ratio'], contains('Division durch Null'));
  });
}
