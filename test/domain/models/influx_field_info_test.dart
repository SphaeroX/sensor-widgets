import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';

void main() {
  group('InfluxFieldInfo', () {
    test(
      'normalizes type to lowercase and defaults empty/null-like to unknown',
      () {
        const info1 = InfluxFieldInfo(key: 'temperature', type: 'Float');
        expect(info1.key, equals('temperature'));
        expect(info1.type, equals('float'));

        const info2 = InfluxFieldInfo(key: 'status', type: 'STRING');
        expect(info2.type, equals('string'));

        const info3 = InfluxFieldInfo(key: 'raw', type: '');
        expect(info3.type, equals('unknown'));
      },
    );

    test(
      'isNumeric returns true for float, integer, unsigned, and unknown',
      () {
        expect(
          const InfluxFieldInfo(key: 'f', type: 'float').isNumeric,
          isTrue,
        );
        expect(
          const InfluxFieldInfo(key: 'i', type: 'integer').isNumeric,
          isTrue,
        );
        expect(
          const InfluxFieldInfo(key: 'u', type: 'unsigned').isNumeric,
          isTrue,
        );
        expect(
          const InfluxFieldInfo(key: 'unk', type: 'unknown').isNumeric,
          isTrue,
        );
      },
    );

    test('isNumeric returns false for string and boolean', () {
      expect(
        const InfluxFieldInfo(key: 's', type: 'string').isNumeric,
        isFalse,
      );
      expect(
        const InfluxFieldInfo(key: 'b', type: 'boolean').isNumeric,
        isFalse,
      );
    });

    test('supports value equality and hashCode', () {
      const a = InfluxFieldInfo(key: 'temp', type: 'float');
      const b = InfluxFieldInfo(key: 'temp', type: 'float');
      const c = InfluxFieldInfo(key: 'temp', type: 'integer');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString returns readable string representation', () {
      const info = InfluxFieldInfo(key: 'humidity', type: 'float');
      expect(
        info.toString(),
        equals('InfluxFieldInfo(key: humidity, type: float)'),
      );
    });
  });
}
