import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';

void main() {
  group('InfluxConnection', () {
    const connection = InfluxConnection(
      id: 'conn-1',
      name: 'Home InfluxDB',
      url: 'https://influx.example.com:8086',
      database: 'sensors',
      organization: 'my-org',
    );

    test('roundtrips toJson and fromJson without token', () {
      final json = connection.toJson();
      expect(json['id'], 'conn-1');
      expect(json['name'], 'Home InfluxDB');
      expect(json['url'], 'https://influx.example.com:8086');
      expect(json['database'], 'sensors');
      expect(json['organization'], 'my-org');
      expect(json.containsKey('token'), isFalse);

      final restored = InfluxConnection.fromJson(json);
      expect(restored, connection);
    });

    test('toString never leaks sensitive data', () {
      final str = connection.toString();
      expect(str.contains('token'), isFalse);
      expect(str.contains('conn-1'), isTrue);
    });

    test('validates URL and database', () {
      expect(connection.isValid, isTrue);

      const invalidUrl = InfluxConnection(
        id: 'conn-2',
        name: 'Bad URL',
        url: 'invalid-url',
        database: 'sensors',
      );
      expect(invalidUrl.isValid, isFalse);

      const emptyDb = InfluxConnection(
        id: 'conn-3',
        name: 'Empty DB',
        url: 'https://influx.example.com',
        database: '',
      );
      expect(emptyDb.isValid, isFalse);
    });
  });
}
