import 'package:flutter/material.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

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

  static String description(WidgetType type, AppLocalizations l10n) {
    switch (type) {
      case WidgetType.singleValue:
        return l10n.widgetTypeSingleValueDescription;
      case WidgetType.historyChart:
        return l10n.widgetTypeHistoryChartDescription;
      case WidgetType.indicatorLamp:
        return l10n.widgetTypeIndicatorLampDescription;
      case WidgetType.multiValue:
        return l10n.widgetTypeMultiValueDescription;
      case WidgetType.aggregate:
        return l10n.widgetTypeAggregateDescription;
      case WidgetType.gaugeBar:
        return l10n.widgetTypeGaugeBarDescription;
    }
  }
}
