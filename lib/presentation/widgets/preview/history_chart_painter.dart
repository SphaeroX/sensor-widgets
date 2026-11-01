import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensor_widgets/domain/chart/chart_color.dart';
import 'package:sensor_widgets/domain/models/chart_style.dart';

/// Paints a history line chart with optional value-dependent line color
/// (vertical gradient), filled area, grid, axis labels and min/max markers.
class HistoryChartPainter extends CustomPainter {
  final List<double> values;
  final ChartStyle style;
  final Color lineColor;
  final Color labelColor;
  final Color gridColor;

  const HistoryChartPainter({
    required this.values,
    required this.style,
    required this.lineColor,
    required this.labelColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    var minValue = values.reduce((a, b) => a < b ? a : b);
    var maxValue = values.reduce((a, b) => a > b ? a : b);
    final dataMin = minValue;
    final dataMax = maxValue;
    if (maxValue == minValue) {
      minValue -= 1;
      maxValue += 1;
    }

    final left = style.showAxes ? 34.0 : 6.0;
    final bottom = size.height - (style.showAxes ? 6.0 : 6.0);
    const top = 6.0;
    final right = size.width - 6.0;
    final width = right - left;
    final height = bottom - top;

    double xAt(int i) => left + width * i / (values.length - 1);
    double yAt(double v) =>
        bottom - height * (v - minValue) / (maxValue - minValue);

    if (style.showGrid) {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 1;
      for (var i = 0; i <= 3; i++) {
        final y = top + height * i / 3;
        canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
      }
    }

    final gradient = buildGradient(
      style.colorStops,
      minValue: minValue,
      maxValue: maxValue,
    );
    ui.Gradient? shaderWith(int alpha) {
      if (gradient == null) return null;
      return ui.Gradient.linear(Offset(0, bottom), const Offset(0, top), [
        for (final c in gradient.colors) Color(c).withAlpha(alpha),
      ], gradient.positions);
    }

    final linePath = Path()..moveTo(xAt(0), yAt(values.first));
    for (var i = 1; i < values.length; i++) {
      linePath.lineTo(xAt(i), yAt(values[i]));
    }

    if (style.fillArea) {
      final fillPath = Path.from(linePath)
        ..lineTo(xAt(values.length - 1), bottom)
        ..lineTo(xAt(0), bottom)
        ..close();
      final fillPaint = Paint()..style = PaintingStyle.fill;
      final shader = shaderWith(0x59);
      if (shader != null) {
        fillPaint.shader = shader;
      } else {
        fillPaint.color = lineColor.withAlpha(0x40);
      }
      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final lineShader = shaderWith(0xFF);
    if (lineShader != null) {
      linePaint.shader = lineShader;
    } else {
      linePaint.color = lineColor;
    }
    canvas.drawPath(linePath, linePaint);

    if (style.markMinMax) {
      final minIndex = values.indexOf(dataMin);
      final maxIndex = values.indexOf(dataMax);
      canvas.drawCircle(
        Offset(xAt(minIndex), yAt(dataMin)),
        style.lineWidth + 1.5,
        Paint()..color = lineColor,
      );
      canvas.drawCircle(
        Offset(xAt(maxIndex), yAt(dataMax)),
        style.lineWidth + 1.5,
        Paint()..color = lineColor,
      );
    }

    if (style.showAxes) {
      _label(canvas, dataMax.toStringAsFixed(1), const Offset(0, top - 4));
      _label(canvas, dataMin.toStringAsFixed(1), Offset(0, bottom - 10));
    }
  }

  void _label(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: labelColor, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 32);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant HistoryChartPainter oldDelegate) =>
      !listEquals(values, oldDelegate.values) ||
      style != oldDelegate.style ||
      lineColor != oldDelegate.lineColor ||
      labelColor != oldDelegate.labelColor ||
      gridColor != oldDelegate.gridColor;
}
