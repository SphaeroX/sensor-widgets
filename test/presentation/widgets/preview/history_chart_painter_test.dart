import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/chart_style.dart';
import 'package:sensor_widgets/domain/models/sensor_data_point.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/widgets/preview/history_chart_painter.dart';
import 'package:sensor_widgets/presentation/widgets/preview/widget_live_preview_card.dart';

class _Call {
  final String kind;
  final Paint? paint;
  const _Call(this.kind, [this.paint]);
}

/// Canvas that only records the primitives the painter is allowed to use.
class _RecordingCanvas extends Fake implements Canvas {
  final calls = <_Call>[];

  @override
  void drawPath(Path path, Paint paint) => calls.add(_Call('path', paint));

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) =>
      calls.add(_Call('line', paint));

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      calls.add(_Call('circle', paint));

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) =>
      calls.add(const _Call('text'));

  int count(String kind) => calls.where((c) => c.kind == kind).length;
}

const _stops = [
  ColorStop(value: 0, color: '#FF0000'),
  ColorStop(value: 100, color: '#00FF00'),
];

_RecordingCanvas _paint(ChartStyle style, [List<double>? values]) {
  final canvas = _RecordingCanvas();
  HistoryChartPainter(
    values: values ?? const [10, 40, 30, 90, 60],
    style: style,
    lineColor: const Color(0xFF2196F3),
    labelColor: Colors.black,
    gridColor: Colors.grey,
  ).paint(canvas, const Size(300, 120));
  return canvas;
}

void main() {
  group('HistoryChartPainter', () {
    test('strokes the line with a vertical gradient when stops are set', () {
      final canvas = _paint(const ChartStyle(colorStops: _stops));
      final line = canvas.calls.firstWhere((c) => c.kind == 'path');
      expect(line.paint!.shader, isNotNull);
      expect(line.paint!.style, PaintingStyle.stroke);
    });

    test('uses the plain line color without stops', () {
      final canvas = _paint(const ChartStyle());
      final line = canvas.calls.firstWhere((c) => c.kind == 'path');
      expect(line.paint!.shader, isNull);
      expect(line.paint!.color.toARGB32(), 0xFF2196F3);
    });

    test('line width follows the style', () {
      final canvas = _paint(const ChartStyle(lineWidth: 4));
      expect(canvas.calls.first.paint!.strokeWidth, 4);
    });

    test('fillArea draws an additional filled path', () {
      expect(_paint(const ChartStyle()).count('path'), 1);
      final filled = _paint(const ChartStyle(fillArea: true));
      expect(filled.count('path'), 2);
      expect(
        filled.calls
            .where((c) => c.kind == 'path')
            .any((c) => c.paint!.style == PaintingStyle.fill),
        isTrue,
      );
    });

    test('grid and axes draw lines and labels only when enabled', () {
      final none = _paint(const ChartStyle());
      expect(none.count('line'), 0);
      expect(none.count('text'), 0);

      final grid = _paint(const ChartStyle(showGrid: true));
      expect(grid.count('line'), greaterThan(0));

      final axes = _paint(const ChartStyle(showAxes: true));
      expect(axes.count('text'), greaterThanOrEqualTo(2));
    });

    test('min/max markers are two circles', () {
      expect(_paint(const ChartStyle(markMinMax: true)).count('circle'), 2);
      expect(_paint(const ChartStyle()).count('circle'), 0);
    });

    test('too few points draw nothing and a flat series does not crash', () {
      expect(_paint(const ChartStyle(), const [5]).calls, isEmpty);
      expect(
        _paint(const ChartStyle(fillArea: true), const [5, 5, 5]).count('path'),
        2,
      );
    });

    test('shouldRepaint reacts to data and style changes', () {
      HistoryChartPainter make(List<double> v, ChartStyle s) =>
          HistoryChartPainter(
            values: v,
            style: s,
            lineColor: const Color(0xFF2196F3),
            labelColor: Colors.black,
            gridColor: Colors.grey,
          );
      final base = make(const [1, 2, 3], const ChartStyle());
      expect(
        base.shouldRepaint(make(const [1, 2, 3], const ChartStyle())),
        isFalse,
      );
      expect(
        base.shouldRepaint(make(const [1, 2, 4], const ChartStyle())),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          make(const [1, 2, 3], const ChartStyle(showGrid: true)),
        ),
        isTrue,
      );
    });
  });

  group('WidgetLivePreviewCard history chart', () {
    WidgetPreviewData data() => WidgetPreviewData(
      historyPoints: [
        for (var i = 0; i < 5; i++)
          SensorDataPoint(
            timestamp: DateTime.utc(2026, 1, 1, i),
            value: i * 10.0,
            field: 'f',
          ),
      ],
    );

    WidgetDefinition def({ChartStyle? style}) => WidgetDefinition(
      id: 'w',
      type: WidgetType.historyChart,
      title: 'IAQ',
      connectionId: 'c',
      measurement: 'm',
      field: 'f',
      chartStyle: style,
    );

    testWidgets('uses the gradient painter when a chart style is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetLivePreviewCard(
              widgetDef: def(style: const ChartStyle(colorStops: _stops)),
              previewData: data(),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('history_chart_canvas')), findsOneWidget);
    });

    testWidgets('keeps the unchanged bar preview without a chart style', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetLivePreviewCard(widgetDef: def(), previewData: data()),
          ),
        ),
      );
      expect(find.byKey(const Key('history_chart_canvas')), findsNothing);
    });
  });
}
