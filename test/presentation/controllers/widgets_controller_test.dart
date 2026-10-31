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
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';

class MockWidgetDefinitionRepository extends Mock
    implements WidgetDefinitionRepository {}

class MockConnectionRepository extends Mock implements ConnectionRepository {}

class MockInfluxApiClient extends Mock implements InfluxApiClient {}

class MockSharedWidgetStore extends Mock implements SharedWidgetStore {}

void main() {
  group('WidgetsController', () {
    late MockWidgetDefinitionRepository mockWidgetRepo;
    late MockConnectionRepository mockConnRepo;
    late MockInfluxApiClient mockApiClient;
    late MockSharedWidgetStore mockSharedStore;
    late ProviderContainer container;

    const testWidget = WidgetDefinition(
      id: 'w-1',
      type: WidgetType.singleValue,
      title: 'Temp Living Room',
      connectionId: 'conn-1',
      measurement: 'temperature',
      field: 'value',
    );

    const testConn = InfluxConnection(
      id: 'conn-1',
      name: 'Server',
      url: 'https://example.com',
      database: 'sensors',
    );

    setUpAll(() {
      registerFallbackValue(testWidget);
    });

    setUp(() {
      mockWidgetRepo = MockWidgetDefinitionRepository();
      mockConnRepo = MockConnectionRepository();
      mockApiClient = MockInfluxApiClient();
      mockSharedStore = MockSharedWidgetStore();
      when(() => mockSharedStore.notifyWidgetsUpdated())
          .thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          widgetDefinitionRepositoryProvider.overrideWithValue(mockWidgetRepo),
          connectionRepositoryProvider.overrideWithValue(mockConnRepo),
          influxApiClientProvider.overrideWithValue(mockApiClient),
          sharedWidgetStoreProvider.overrideWithValue(mockSharedStore),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loads widgets from repository', () async {
      when(() => mockWidgetRepo.getWidgets())
          .thenAnswer((_) async => [testWidget]);

      final state = await container.read(widgetsControllerProvider.future);
      expect(state, [testWidget]);
    });

    test(
      'saveWidget, duplicateWidget and deleteWidget call repository',
      () async {
        when(() => mockWidgetRepo.getWidgets()).thenAnswer((_) async => []);
        when(() => mockWidgetRepo.saveWidget(any())).thenAnswer((_) async {});
        when(() => mockWidgetRepo.deleteWidget('w-1')).thenAnswer((_) async {});

        final controller = container.read(widgetsControllerProvider.notifier);

        await controller.saveWidget(testWidget);
        verify(() => mockWidgetRepo.saveWidget(testWidget)).called(1);

        await controller.duplicateWidget(testWidget);
        verify(() => mockWidgetRepo.saveWidget(any(that: isNot(testWidget))))
            .called(1);

        await controller.deleteWidget('w-1');
        verify(() => mockWidgetRepo.deleteWidget('w-1')).called(1);
      },
    );

    test('fetchPreviewData queries InfluxApiClient', () async {
      when(() => mockConnRepo.getConnection('conn-1'))
          .thenAnswer((_) async => testConn);
      when(() => mockConnRepo.getToken('conn-1'))
          .thenAnswer((_) async => 'tok');
      when(
        () => mockApiClient.query(
          connection: testConn,
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
                  'name': 'temperature',
                  'columns': ['time', 'value'],
                  'values': [
                    [1730370000000, 22.4],
                  ],
                },
              ],
            },
          ],
        },
      );

      final controller = container.read(widgetsControllerProvider.notifier);
      final preview = await controller.fetchPreviewData(testWidget);

      expect(preview.singleValue?.value, 22.4);
    });

    test('triggerNativeRefresh calls sharedWidgetStore', () async {
      when(() => mockSharedStore.notifyWidgetsUpdated())
          .thenAnswer((_) async {});

      final controller = container.read(widgetsControllerProvider.notifier);
      await controller.triggerNativeRefresh();

      verify(() => mockSharedStore.notifyWidgetsUpdated()).called(1);
    });

    test('fetchPreviewData returns error when connection not found', () async {
      when(() => mockConnRepo.getConnection('conn-missing'))
          .thenAnswer((_) async => null);

      final brokenWidget = testWidget.copyWith(connectionId: 'conn-missing');
      final controller = container.read(widgetsControllerProvider.notifier);
      final preview = await controller.fetchPreviewData(brokenWidget);

      expect(preview.errorMessage, isNotNull);
    });
  });
}
