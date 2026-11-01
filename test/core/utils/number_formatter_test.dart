import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/core/utils/number_formatter.dart';

void main() {
  group('NumberFormatter', () {
    test('format returns -- for null', () {
      expect(NumberFormatter.format(null), '--');
    });

    test('format respects specified decimalPlaces clamped to max 2', () {
      expect(NumberFormatter.format(22.44, decimalPlaces: 1), '22.4');
      expect(NumberFormatter.format(22.44, decimalPlaces: 0), '22');
      expect(NumberFormatter.format(22.4444, decimalPlaces: 2), '22.44');
      // Max 2 numbers after comma even if higher requested
      expect(NumberFormatter.format(22.4444, decimalPlaces: 4), '22.44');
    });

    test('format handles normal data and average calculations without rounding errors', () {
      // Average calculation producing IEEE float noise: (10.1 + 20.2) / 2 = 15.150000000000002
      const avg1 = (10.1 + 20.2) / 2;
      expect(NumberFormatter.format(avg1), '15.15');

      // Average calculation: 50 / 3 = 16.666666666666668 -> 16.67
      const avg2 = 50.0 / 3.0;
      expect(NumberFormatter.format(avg2), '16.67');

      // Integer-like value: 20.0 -> 20
      expect(NumberFormatter.format(20.0), '20');

      // Single decimal value: 20.5 -> 20.5
      expect(NumberFormatter.format(20.5), '20.5');

      // Two decimals: 20.25 -> 20.25
      expect(NumberFormatter.format(20.25), '20.25');

      // Negative average: (-10.1 - 20.2) / 2 -> -15.15
      const avgNeg = (-10.1 - 20.2) / 2;
      expect(NumberFormatter.format(avgNeg), '-15.15');
    });

    test('roundToMaxDecimals rounds doubles to at most 2 decimal places', () {
      expect(NumberFormatter.roundToMaxDecimals(15.150000000000002), 15.15);
      expect(NumberFormatter.roundToMaxDecimals(16.666666666666668), 16.67);
      expect(NumberFormatter.roundToMaxDecimals(20.0), 20.0);
      expect(NumberFormatter.roundToMaxDecimals(20.1234), 20.12);
    });
  });
}
