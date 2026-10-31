import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';

class MockConnectionRepository extends Mock implements ConnectionRepository {}

class MockWidgetDefinitionRepository extends Mock
    implements WidgetDefinitionRepository {}

void main() {
  group('Storage Providers', () {
    late MockConnectionRepository mockConnRepo;
    late MockWidgetDefinitionRepository mockWidgetRepo;

    const testConn = InfluxConnection(
      id: 'conn-1',
      name: 'Primary',
      url: 'https://influx.example.com',
      database: 'db1',
    );

    const testWidget = WidgetDefinition(
      id: 'w-1',
      type: WidgetType.singleValue,
      title: 'Living Room',
      connectionId: 'conn-1',
      measurement: 'temp',
      field: 'val',
    );

    setUp(() {
      mockConnRepo = MockConnectionRepository();
      mockWidgetRepo = MockWidgetDefinitionRepository();
    });

    test('ConnectionsListNotifier loads and saves connections', () async {
      when(() => mockConnRepo.getConnections())
          .thenAnswer((_) async => [testConn]);
      when(() => mockConnRepo.saveConnection(testConn, token: 'tok'))
          .thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          connectionRepositoryProvider.overrideWithValue(mockConnRepo),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(connectionsListProvider.future);
      expect(state, [testConn]);

      await container
          .read(connectionsListProvider.notifier)
          .save(testConn, token: 'tok');
      verify(() => mockConnRepo.saveConnection(testConn, token: 'tok'))
          .called(1);
    });

    test('WidgetsListNotifier loads and saves widgets', () async {
      when(() => mockWidgetRepo.getWidgets())
          .thenAnswer((_) async => [testWidget]);
      when(() => mockWidgetRepo.saveWidget(testWidget))
          .thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          widgetDefinitionRepositoryProvider.overrideWithValue(mockWidgetRepo),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(widgetDefinitionsListProvider.future);
      expect(state, [testWidget]);

      await container
          .read(widgetDefinitionsListProvider.notifier)
          .save(testWidget);
      verify(() => mockWidgetRepo.saveWidget(testWidget)).called(1);
    });
  });
}
