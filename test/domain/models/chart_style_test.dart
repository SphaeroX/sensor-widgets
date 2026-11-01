import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/chart_style.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';

void main() {
  group('ChartStyle', () {
    const style = ChartStyle(
      colorStops: [
        ColorStop(value: 0, color: '#FF0000'),
        ColorStop(value: 100, color: '#00FF00'),
      ],
      fillArea: true,
      showGrid: true,
      showAxes: true,
      markMinMax: true,
      lineWidth: 3,
    );

    test('json roundtrip', () {
      expect(ChartStyle.fromJson(style.toJson()), style);
    });

    test('defaults: all flags off, line width 2', () {
      final s = ChartStyle.fromJson({});
      expect(s.colorStops, isEmpty);
      expect(s.fillArea, isFalse);
      expect(s.showGrid, isFalse);
      expect(s.showAxes, isFalse);
      expect(s.markMinMax, isFalse);
      expect(s.lineWidth, 2.0);
    });

    test('copyWith replaces single values', () {
      expect(style.copyWith(fillArea: false).fillArea, isFalse);
      expect(style.copyWith(fillArea: false).showGrid, isTrue);
    });

    test('presets run green to red and red to green', () {
      expect(ChartStyle.greenToRedStops.first.color, '#4CAF50');
      expect(ChartStyle.greenToRedStops.last.color, '#F44336');
      expect(ChartStyle.redToGreenStops.first.color, '#F44336');
      expect(ChartStyle.redToGreenStops.last.color, '#4CAF50');
    });

    test('isValid requires parseable colors', () {
      expect(style.isValid, isTrue);
      expect(
        const ChartStyle(colorStops: [ColorStop(value: 0, color: 'nope')])
            .isValid,
        isFalse,
      );
    });
  });

  group('WidgetDefinition.chartStyle', () {
    final fixture = json.decode(
      File('fixtures/widget_definitions/widget_definition_chart_style.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final widgets = (fixture['widgets'] as List<dynamic>)
        .map((e) => WidgetDefinition.fromJson(e as Map<String, dynamic>))
        .toList();

    test('is parsed from the shared fixture', () {
      final style = widgets.first.chartStyle!;
      expect(style.colorStops, hasLength(3));
      expect(style.fillArea, isTrue);
      expect(style.lineWidth, 3.0);
    });

    test('old definitions have no chartStyle and do not serialize it', () {
      final plain = widgets.last;
      expect(plain.chartStyle, isNull);
      expect(plain.toJson().containsKey('chartStyle'), isFalse);
    });

    test('json roundtrip and copyWith keep the style', () {
      final w = widgets.first;
      expect(WidgetDefinition.fromJson(w.toJson()).chartStyle, w.chartStyle);
      expect(w.copyWith(title: 'x').chartStyle, w.chartStyle);
    });

    test('isValid rejects an unparseable color', () {
      const bad = WidgetDefinition(
        id: 'w',
        type: WidgetType.historyChart,
        title: 't',
        connectionId: 'c',
        measurement: 'm',
        field: 'f',
        chartStyle: ChartStyle(colorStops: [ColorStop(value: 0, color: 'zzz')]),
      );
      expect(bad.isValid, isFalse);
    });
  });
}
