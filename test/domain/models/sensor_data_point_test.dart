import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/sensor_data_point.dart';

void main() {
  group('SensorDataPoint', () {
    test('instantiation and formatting', () {
      final now = DateTime.fromMillisecondsSinceEpoch(1730370000000);
      final point = SensorDataPoint(
        timestamp: now,
        value: 21.5,
        field: 'temperature',
      );

      expect(point.timestamp, now);
      expect(point.value, 21.5);
      expect(point.field, 'temperature');
    });

    test('JSON roundtrip', () {
      final now = DateTime.fromMillisecondsSinceEpoch(
        1730370000000,
        isUtc: true,
      );
      final point = SensorDataPoint(
        timestamp: now,
        value: 48.0,
        field: 'humidity',
      );

      final json = point.toJson();
      expect(json['timestampEpochMs'], 1730370000000);
      expect(json['value'], 48.0);
      expect(json['field'], 'humidity');

      final restored = SensorDataPoint.fromJson(json);
      expect(restored.timestamp, now);
      expect(restored.value, 48.0);
      expect(restored.field, 'humidity');
    });
  });
}
