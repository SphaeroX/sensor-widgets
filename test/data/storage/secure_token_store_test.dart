import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/core/constants/storage_keys.dart';
import 'package:sensor_widgets/data/storage/secure_token_store.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SecureTokenStore', () {
    late MockFlutterSecureStorage mockStorage;
    late SecureTokenStore tokenStore;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      tokenStore = SecureTokenStore(storage: mockStorage);
    });

    test('saves token under StorageKeys.tokenKey', () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async {});

      await tokenStore.saveToken('conn-1', 'secret-token-123');

      verify(
        () => mockStorage.write(
          key: StorageKeys.tokenKey('conn-1'),
          value: 'secret-token-123',
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).called(1);
    });

    test('retrieves token by connectionId', () async {
      when(
        () => mockStorage.read(
          key: StorageKeys.tokenKey('conn-1'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async => 'secret-token-123');

      final token = await tokenStore.getToken('conn-1');
      expect(token, 'secret-token-123');
    });

    test('deletes token by connectionId', () async {
      when(
        () => mockStorage.delete(
          key: StorageKeys.tokenKey('conn-1'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async {});

      await tokenStore.deleteToken('conn-1');

      verify(
        () => mockStorage.delete(
          key: StorageKeys.tokenKey('conn-1'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).called(1);
    });
  });
}
