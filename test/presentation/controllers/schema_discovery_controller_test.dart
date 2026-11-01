import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/domain/errors/influx_exception.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/presentation/controllers/schema_discovery_controller.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';

class MockConnectionRepository extends Mock implements ConnectionRepository {}

class MockInfluxApiClient extends Mock implements InfluxApiClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const InfluxConnection(
        id: 'fallback',
        name: 'Fallback',
        url: 'https://fallback.com',
        database: 'db',
      ),
    );
  });

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

    test('EditorSchemaController loads measurements and handles cascading selection', () async {
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
        () => mockApiClient.fetchFieldInfos(
          connection: testConn,
          token: 'token-123',
          measurement: 'climate',
        ),
      ).thenAnswer(
        (_) async => [
          const InfluxFieldInfo(key: 'temp', type: 'float'),
          const InfluxFieldInfo(key: 'active', type: 'boolean'),
        ],
      );

      when(
        () => mockApiClient.fetchTagKeys(
          connection: testConn,
          token: 'token-123',
          measurement: 'climate',
        ),
      ).thenAnswer((_) async => ['room', 'sensor']);

      when(
        () => mockApiClient.fetchTagValues(
          connection: testConn,
          token: 'token-123',
          measurement: 'climate',
          tagKey: 'room',
        ),
      ).thenAnswer((_) async => ['living_room', 'bedroom']);

      final editorController = container.read(
        editorSchemaControllerProvider.notifier,
      );

      await editorController.selectConnection('conn-1');
      var state = container.read(editorSchemaControllerProvider);

      expect(state.selectedConnectionId, equals('conn-1'));
      expect(state.measurements.isLoaded, isTrue);
      expect(state.measurements.items, equals(['climate', 'power']));
      expect(state.fields.isIdle, isTrue);

      await editorController.selectMeasurement('climate');
      state = container.read(editorSchemaControllerProvider);

      expect(state.selectedMeasurement, equals('climate'));
      expect(state.fields.isLoaded, isTrue);
      expect(state.fields.items.length, equals(2));
      expect(state.fields.items.first.key, equals('temp'));
      expect(state.fields.items.first.type, equals('float'));
      expect(state.tagKeys.isLoaded, isTrue);
      expect(state.tagKeys.items, equals(['room', 'sensor']));

      await editorController.loadTagValues('room');
      state = container.read(editorSchemaControllerProvider);

      expect(state.tagValuesByKey['room']?.isLoaded, isTrue);
      expect(
        state.tagValuesByKey['room']?.items,
        equals(['living_room', 'bedroom']),
      );
    });

    test('EditorSchemaController handles InfluxDB errors with InfluxErrorFormatter without token leak', () async {
      when(() => mockConnRepo.getConnection('conn-1'))
          .thenAnswer((_) async => testConn);
      when(() => mockConnRepo.getToken('conn-1'))
          .thenAnswer((_) async => 'secret-leak-token');

      when(
        () => mockApiClient.fetchMeasurements(
          connection: testConn,
          token: 'secret-leak-token',
        ),
      ).thenThrow(
        const InfluxQueryException(
          'database not found: sensors with secret-leak-token',
        ),
      );

      final editorController = container.read(
        editorSchemaControllerProvider.notifier,
      );
      await editorController.selectConnection('conn-1');
      final state = container.read(editorSchemaControllerProvider);

      expect(state.measurements.hasError, isTrue);
      expect(state.measurements.errorMessage, contains('DBRP-Mapping'));
      expect(
        state.measurements.errorMessage?.contains('secret-leak-token'),
        isFalse,
      );
    });

    test('EditorSchemaController supports reload on all levels', () async {
      when(() => mockConnRepo.getConnection('conn-1'))
          .thenAnswer((_) async => testConn);
      when(() => mockConnRepo.getToken('conn-1'))
          .thenAnswer((_) async => 'token-123');

      var failFirst = true;
      when(
        () => mockApiClient.fetchMeasurements(
          connection: testConn,
          token: 'token-123',
        ),
      ).thenAnswer((_) async {
        if (failFirst) {
          failFirst = false;
          throw const InfluxNetworkException('Temporary network glitch');
        }
        return ['climate'];
      });

      final editorController = container.read(
        editorSchemaControllerProvider.notifier,
      );
      await editorController.selectConnection('conn-1');
      var state = container.read(editorSchemaControllerProvider);
      expect(state.measurements.hasError, isTrue);

      await editorController.reloadMeasurements();
      state = container.read(editorSchemaControllerProvider);
      expect(state.measurements.isLoaded, isTrue);
      expect(state.measurements.items, equals(['climate']));
    });

    test('EditorSchemaController falls back to fetchFieldKeys if fetchFieldInfos is not mocked', () async {
      when(() => mockConnRepo.getConnection('conn-1'))
          .thenAnswer((_) async => testConn);
      when(() => mockConnRepo.getToken('conn-1'))
          .thenAnswer((_) async => 'token-123');

      when(
        () => mockApiClient.fetchMeasurements(
          connection: testConn,
          token: 'token-123',
        ),
      ).thenAnswer((_) async => ['climate']);

      // fetchFieldInfos throws NoSuchMethodError (unmocked)
      when(
        () => mockApiClient.fetchFieldInfos(
          connection: testConn,
          token: 'token-123',
          measurement: 'climate',
        ),
      ).thenThrow(
        NoSuchMethodError.withInvocation(
          null,
          Invocation.method(#fetchFieldInfos, []),
        ),
      );

      when(
        () => mockApiClient.fetchFieldKeys(
          connection: testConn,
          token: 'token-123',
          measurement: 'climate',
        ),
      ).thenAnswer((_) async => ['temp', 'co2']);

      when(
        () => mockApiClient.fetchTagKeys(
          connection: testConn,
          token: 'token-123',
          measurement: 'climate',
        ),
      ).thenAnswer((_) async => []);

      final editorController = container.read(
        editorSchemaControllerProvider.notifier,
      );
      await editorController.selectConnection('conn-1');
      await editorController.selectMeasurement('climate');
      final state = container.read(editorSchemaControllerProvider);

      expect(state.fields.isLoaded, isTrue);
      expect(state.fields.items.length, equals(2));
      expect(
        state.fields.items[0],
        equals(const InfluxFieldInfo(key: 'temp', type: 'unknown')),
      );
      expect(
        state.fields.items[1],
        equals(const InfluxFieldInfo(key: 'co2', type: 'unknown')),
      );
    });

    test('EditorSchemaController protects against race conditions when changing selection quickly', () async {
      final sub = container.listen(editorSchemaControllerProvider, (_, _) {});
      when(() => mockConnRepo.getConnection('conn-1'))
          .thenAnswer((_) async => testConn);
      when(() => mockConnRepo.getConnection('conn-2')).thenAnswer(
        (_) async => const InfluxConnection(
          id: 'conn-2',
          name: 'Server 2',
          url: 'https://example2.com',
          database: 'db2',
        ),
      );
      when(() => mockConnRepo.getToken(any()))
          .thenAnswer((_) async => 'token-123');

      when(
        () => mockApiClient.fetchMeasurements(
          connection: any(named: 'connection'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((invocation) async {
        final conn = invocation.namedArguments[#connection] as InfluxConnection;
        if (conn.id == 'conn-1') {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return ['conn1_measurement'];
        } else {
          return ['conn2_measurement'];
        }
      });

      final editorController = container.read(
        editorSchemaControllerProvider.notifier,
      );

      // Trigger conn-1 (slow), then immediately conn-2 (fast)
      final future1 = editorController.selectConnection('conn-1');
      final future2 = editorController.selectConnection('conn-2');

      await Future.wait<void>([future1, future2]);
      final state = container.read(editorSchemaControllerProvider);

      expect(state.selectedConnectionId, equals('conn-2'));
      expect(state.measurements.items, equals(['conn2_measurement']));
      sub.close();
    });
  });
}
