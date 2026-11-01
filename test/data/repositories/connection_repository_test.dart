import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/core/constants/storage_keys.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/storage/secure_token_store.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';

class MockSharedWidgetStore extends Mock implements SharedWidgetStore {}

class MockSecureTokenStore extends Mock implements SecureTokenStore {}

void main() {
  group('ConnectionRepository', () {
    late MockSharedWidgetStore mockSharedStore;
    late MockSecureTokenStore mockTokenStore;
    late ConnectionRepository repository;

    const testConn = InfluxConnection(
      id: 'conn-1',
      name: 'Primary Influx',
      url: 'https://influx.example.com',
      database: 'iot_db',
    );

    setUp(() {
      mockSharedStore = MockSharedWidgetStore();
      mockTokenStore = MockSecureTokenStore();
      repository = ConnectionRepository(
        sharedStore: mockSharedStore,
        tokenStore: mockTokenStore,
      );
    });

    test('returns empty list when no connections stored', () async {
      when(() => mockSharedStore.getString(StorageKeys.connectionsMetadataKey))
          .thenAnswer((_) async => null);

      final list = await repository.getConnections();
      expect(list, isEmpty);
    });

    test('getConnections automatically migrates and syncs missing tokens to sharedStore', () async {
      final jsonList = json.encode([testConn.toJson()]);
      when(() => mockSharedStore.getString(StorageKeys.connectionsMetadataKey))
          .thenAnswer((_) async => jsonList);
      when(() => mockSharedStore.getString(StorageKeys.tokenKey('conn-1')))
          .thenAnswer((_) async => null); // token not yet in shared store!
      when(() => mockTokenStore.getToken('conn-1'))
          .thenAnswer((_) async => 'migrated-secret-token');
      when(() => mockSharedStore.saveString(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockSharedStore.notifyWidgetsUpdated())
          .thenAnswer((_) async => true);

      final list = await repository.getConnections();
      expect(list.length, 1);

      // Verify token was automatically mirrored to sharedStore for native widgets
      verify(
        () => mockSharedStore.saveString(
          StorageKeys.tokenKey('conn-1'),
          'migrated-secret-token',
        ),
      ).called(1);
      verify(() => mockSharedStore.notifyWidgetsUpdated()).called(1);
    });

    test(
      'saves connection metadata to shared store and token to secure store',
      () async {
        when(
          () => mockSharedStore.getString(StorageKeys.connectionsMetadataKey),
        ).thenAnswer((_) async => null);
        when(() => mockSharedStore.saveString(any(), any()))
            .thenAnswer((_) async {});
        when(() => mockTokenStore.saveToken(any(), any()))
            .thenAnswer((_) async {});

        await repository.saveConnection(testConn, token: 'super-secret-token');

        verify(() => mockTokenStore.saveToken('conn-1', 'super-secret-token'))
            .called(1);

        final captured = verify(
          () => mockSharedStore.saveString(
            StorageKeys.connectionsMetadataKey,
            captureAny(),
          ),
        ).captured;

        final savedJson = captured.first as String;
        expect(savedJson.contains('super-secret-token'), isFalse);
        expect(savedJson.contains('Primary Influx'), isTrue);
      },
    );

    test('deletes connection and removes associated token', () async {
      final jsonList = json.encode([testConn.toJson()]);
      when(() => mockSharedStore.getString(StorageKeys.connectionsMetadataKey))
          .thenAnswer((_) async => jsonList);
      when(() => mockSharedStore.saveString(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockTokenStore.deleteToken(any())).thenAnswer((_) async {});

      await repository.deleteConnection('conn-1');

      verify(() => mockTokenStore.deleteToken('conn-1')).called(1);
      verify(
        () => mockSharedStore.saveString(
          StorageKeys.connectionsMetadataKey,
          '[]',
        ),
      ).called(1);
    });
  });
}
