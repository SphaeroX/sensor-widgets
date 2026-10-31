import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/threshold_rule.dart';

void main() {
  group('ThresholdOperator & ThresholdRule', () {
    test('greaterThan evaluation', () {
      const rule = ThresholdRule(
        operator: ThresholdOperator.greaterThan,
        value: 25.0,
        color: '#FF0000',
        activeColor: '#FF0000',
        inactiveColor: '#00FF00',
      );

      expect(rule.matches(26.0), isTrue);
      expect(rule.matches(25.0), isFalse);
      expect(rule.matches(24.0), isFalse);
    });

    test('lessThan evaluation', () {
      const rule = ThresholdRule(
        operator: ThresholdOperator.lessThan,
        value: 10.0,
        color: '#FFA500',
      );

      expect(rule.matches(9.9), isTrue);
      expect(rule.matches(10.0), isFalse);
      expect(rule.matches(10.1), isFalse);
    });

    test('JSON roundtrip', () {
      const rule = ThresholdRule(
        operator: ThresholdOperator.greaterThan,
        value: 1000.0,
        activeColor: '#FF0000',
        inactiveColor: '#00FF00',
        color: '#FF0000',
      );

      final json = rule.toJson();
      final restored = ThresholdRule.fromJson(json);

      expect(restored.operator, ThresholdOperator.greaterThan);
      expect(restored.value, 1000.0);
      expect(restored.activeColor, '#FF0000');
      expect(restored.inactiveColor, '#00FF00');
    });
  });
}
