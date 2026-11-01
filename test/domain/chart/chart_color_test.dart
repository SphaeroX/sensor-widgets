import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/chart/chart_color.dart';
import 'package:sensor_widgets/domain/models/chart_style.dart';

void main() {
  group('hex color parsing', () {
    test('parses #RRGGBB to opaque ARGB', () {
      expect(parseHexColor('#FF8000'), 0xFFFF8000);
      expect(parseHexColor('ff8000'), 0xFFFF8000);
    });

    test('returns null for invalid input', () {
      expect(parseHexColor('#12345'), isNull);
      expect(parseHexColor('red'), isNull);
      expect(parseHexColor(''), isNull);
    });

    test('formats ARGB back to #RRGGBB', () {
      expect(formatHexColor(0xFF66FF00), '#66FF00');
    });
  });

  group('interpolateColor (shared fixture)', () {
    final data = json.decode(
      File('fixtures/chart/color_interpolation_cases.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    test('matches every fixture case', () {
      final cases = data['cases'] as List<dynamic>;
      expect(cases, isNotEmpty);
      for (final c in cases) {
        final stops = (c['stops'] as List<dynamic>)
            .map((s) => ColorStop.fromJson(s as Map<String, dynamic>))
            .toList();
        final result = interpolateColor(stops, (c['value'] as num).toDouble());
        final expected = c['expected'] as String?;
        expect(
          result == null ? null : formatHexColor(result),
          expected,
          reason: 'case ${c['name']}',
        );
      }
    });
  });

  group('buildGradient', () {
    const stops = [
      ColorStop(value: 0, color: '#FF0000'),
      ColorStop(value: 50, color: '#FFFF00'),
      ColorStop(value: 100, color: '#00FF00'),
    ];

    test('maps stop values into 0..1 positions of the visible range', () {
      final g = buildGradient(stops, minValue: 0, maxValue: 100)!;
      expect(g.positions, [0.0, 0.5, 1.0]);
      expect(g.colors.map(formatHexColor), ['#FF0000', '#FFFF00', '#00FF00']);
    });

    test(
      'adds interpolated edge colors when the range is inside the stops',
      () {
        final g = buildGradient(stops, minValue: 25, maxValue: 75)!;
        expect(g.positions.first, 0.0);
        expect(g.positions.last, 1.0);
        expect(g.positions, contains(0.5));
        // 25 lies between red and yellow, 75 between yellow and green.
        expect(formatHexColor(g.colors.first), isNot('#FF0000'));
        expect(g.colors.length, g.positions.length);
      },
    );

    test('returns null without stops', () {
      expect(buildGradient(const [], minValue: 0, maxValue: 10), isNull);
    });

    test('a flat range falls back to a single color', () {
      final g = buildGradient(stops, minValue: 50, maxValue: 50)!;
      expect(g.colors.toSet(), hasLength(1));
      expect(formatHexColor(g.colors.first), '#FFFF00');
    });
  });
}
