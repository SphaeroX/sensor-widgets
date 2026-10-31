import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/presentation/controllers/schema_discovery_controller.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';

class MockConnectionRepository extends Mock implements ConnectionRepository {}

class MockInfluxApiClient extends Mock implements InfluxApiClient {}

void main() {
  group('SchemaDiscoveryController', () {
    late MockConnectionRepository mockConnRepo;
    late MockInfluxApiClient mockApiClient;
    late ProviderContainer container;

    const testConn = InfluxConnection(
      id: 'conn-1',
      name: 'Server',
      url: 'https://example.com',
      database: 'sensors',
    );

    setUp(() {
      mockConnRepo = MockConnectionRepository();
      mockApiClient = MockInfluxApiClient();

      container = ProviderContainer(
        overrides: [
          connectionRepositoryProvider.overrideWithValue(mockConnRepo),
          influxApiClientProvider.overrideWithValue(mockApiClient),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loads measurements, fields and tags for a connection', () async {
      when(() => mockConnRepo.getConnection('conn-1'))
          .thenAnswer((_) async => testConn);
      when(() => mockConnRepo.getToken('conn-1'))
          .thenAnswer((_) async => 'token-123');

      when(
        () => mockApiClient.fetchMeasurements(
          connection: testConn,
          token: 'token-123',
        ),
      ).thenAnswer((_) async => ['climate', 'power']);

      when(
        () => mockApiClient.fetchFieldKeys(
          connection: testConn,
          token: 'token-123',
          measurement: 'climate',
        ),
      ).thenAnswer((_) async => ['temperature', 'humidity']);

      when(
        () => mockApiClient.fetchTagKeys(
          connection: testConn,
          token: 'token-123',
          measurement: 'climate',
        ),
      ).thenAnswer((_) async => ['room']);

      when(
        () => mockApiClient.fetchTagValues(
          connection: testConn,
          token: 'token-123',
          measurement: 'climate',
          tagKey: 'room',
        ),
      ).thenAnswer((_) async => ['living_room', 'office']);

      final controller = container.read(schemaDiscoveryControllerProvider);

      final measurements = await controller.getMeasurements('conn-1');
      expect(measurements, ['climate', 'power']);

      final fields = await controller.getFieldKeys('conn-1', 'climate');
      expect(fields, ['temperature', 'humidity']);

      final tagKeys = await controller.getTagKeys('conn-1', 'climate');
      expect(tagKeys, ['room']);

      final tagValues = await controller.getTagValues(
        'conn-1',
        'climate',
        'room',
      );
      expect(tagValues, ['living_room', 'office']);
    });

    test(
      'returns empty lists on error (offline / network error resilience)',
      () async {
        when(() => mockConnRepo.getConnection('conn-err'))
            .thenThrow(Exception('Server unreachable'));

        final controller = container.read(schemaDiscoveryControllerProvider);

        final measurements = await controller.getMeasurements('conn-err');
        expect(measurements, isEmpty);

        final fields = await controller.getFieldKeys('conn-err', 'm1');
        expect(fields, isEmpty);

        final tagKeys = await controller.getTagKeys('conn-err', 'm1');
        expect(tagKeys, isEmpty);

        final tagValues = await controller.getTagValues('conn-err', 'm1', 't1');
        expect(tagValues, isEmpty);
      },
    );
  });
}
