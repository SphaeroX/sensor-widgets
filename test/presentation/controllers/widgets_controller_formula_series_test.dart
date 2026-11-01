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
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';

class MockWidgetRepo extends Mock implements WidgetDefinitionRepository {}

class MockConnRepo extends Mock implements ConnectionRepository {}

class MockApi extends Mock implements InfluxApiClient {}

class MockStore extends Mock implements SharedWidgetStore {}

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
    ).thenAnswer(
      (_) async => {
        'results': [
          {
            'statement_id': 0,
            'series': [
              {
                'name': 'm',
                'columns': ['time', 'a', 'b'],
                'values': [
                  [1000, 10.0, 2.0],
                  [2000, 10.0, 0.0],
                  [3000, 9.0, 3.0],
                ],
              },
            ],
          },
        ],
      },
    );
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

  WidgetDefinition widget(WidgetType type) => WidgetDefinition(
    id: 'w',
    type: type,
    title: 'ratio',
    connectionId: 'c',
    measurement: 'm',
    timeRange: '6h',
    formula: 'a / b',
    formulaVariables: const [
      FormulaVariable(name: 'a', field: 'a'),
      FormulaVariable(name: 'b', field: 'b'),
    ],
  );

  test(
    'history chart with formula returns calculated series and errors',
    () async {
      final controller = container.read(widgetsControllerProvider.notifier);
      await container.read(widgetsControllerProvider.future);

      final preview = await controller.fetchPreviewData(
        widget(WidgetType.historyChart),
      );

      expect(preview.hasError, isFalse);
      expect(preview.historyPoints!.map((p) => p.value), [5.0, 3.0]);
      expect(preview.bucketErrors, hasLength(1));
      expect(preview.bucketErrors!.single, contains('Division durch Null'));
    },
  );

  test('aggregate with formula aggregates the calculated series', () async {
    final controller = container.read(widgetsControllerProvider.notifier);
    await container.read(widgetsControllerProvider.future);

    final preview = await controller.fetchPreviewData(
      widget(WidgetType.aggregate),
    );

    expect(preview.aggregateValues, {'min': 3.0, 'max': 5.0, 'mean': 4.0});
  });
}
