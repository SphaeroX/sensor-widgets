import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/presentation/controllers/connections_controller.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';

class MockConnectionRepository extends Mock implements ConnectionRepository {}

class MockInfluxApiClient extends Mock implements InfluxApiClient {}

void main() {
  group('ConnectionsController', () {
    late MockConnectionRepository mockRepo;
    late MockInfluxApiClient mockApiClient;
    late ProviderContainer container;

    const testConn = InfluxConnection(
      id: 'conn-1',
      name: 'Local Influx',
      url: 'https://localhost:8086',
      database: 'sensors',
    );

    setUp(() {
      mockRepo = MockConnectionRepository();
      mockApiClient = MockInfluxApiClient();

      container = ProviderContainer(
        overrides: [
          connectionRepositoryProvider.overrideWithValue(mockRepo),
          influxApiClientProvider.overrideWithValue(mockApiClient),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state loads connections from repository', () async {
      when(() => mockRepo.getConnections()).thenAnswer((_) async => [testConn]);

      final state = await container.read(connectionsControllerProvider.future);
      expect(state, [testConn]);
      verify(() => mockRepo.getConnections()).called(1);
    });

    test('saveConnection saves to repository and updates state', () async {
      when(() => mockRepo.getConnections()).thenAnswer((_) async => []);
      when(() => mockRepo.saveConnection(testConn, token: 'secret-tok'))
          .thenAnswer((_) async {});

      final controller = container.read(connectionsControllerProvider.notifier);
      await controller.saveConnection(testConn, token: 'secret-tok');

      verify(() => mockRepo.saveConnection(testConn, token: 'secret-tok'))
          .called(1);
    });

    test(
      'deleteConnection deletes from repository and updates state',
      () async {
        when(() => mockRepo.getConnections())
            .thenAnswer((_) async => [testConn]);
        when(() => mockRepo.deleteConnection('conn-1'))
            .thenAnswer((_) async {});

        final controller = container.read(
          connectionsControllerProvider.notifier,
        );
        await controller.deleteConnection('conn-1');

        verify(() => mockRepo.deleteConnection('conn-1')).called(1);
      },
    );

    test('testConnection delegates to InfluxApiClient', () async {
      when(
        () => mockApiClient.testConnection(
          connection: testConn,
          token: 'token-123',
        ),
      ).thenAnswer((_) async => true);

      final controller = container.read(connectionsControllerProvider.notifier);
      final success = await controller.testConnection(
        connection: testConn,
        token: 'token-123',
      );

      expect(success, isTrue);
      verify(
        () => mockApiClient.testConnection(
          connection: testConn,
          token: 'token-123',
        ),
      ).called(1);
    });
  });
}
