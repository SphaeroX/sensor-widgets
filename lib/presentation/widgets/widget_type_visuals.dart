import 'package:flutter/material.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';

/// Icon and short description of each widget type (shared by dashboard and editor).
class WidgetTypeVisuals {
  const WidgetTypeVisuals._();

  static IconData icon(WidgetType type) {
    switch (type) {
      case WidgetType.singleValue:
        return Icons.looks_one_outlined;
      case WidgetType.historyChart:
        return Icons.show_chart;
      case WidgetType.indicatorLamp:
        return Icons.lightbulb_outline;
      case WidgetType.multiValue:
        return Icons.grid_view;
      case WidgetType.aggregate:
        return Icons.functions;
      case WidgetType.gaugeBar:
        return Icons.speed;
    }
  }

  static String description(WidgetType type) {
    switch (type) {
      case WidgetType.singleValue:
        return 'Ein aktueller Messwert';
      case WidgetType.historyChart:
        return 'Verlauf über die Zeit';
      case WidgetType.indicatorLamp:
        return 'Lampe mit Schwellenwert';
      case WidgetType.multiValue:
        return 'Mehrere Werte im Überblick';
      case WidgetType.aggregate:
        return 'Min, Max und Mittelwert';
      case WidgetType.gaugeBar:
        return 'Pegel mit Farbzonen';
    }
  }
}
