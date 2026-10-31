/// Supported native widget types across Android and iOS.
enum WidgetType {
  singleValue('single_value'),
  historyChart('history_chart'),
  indicatorLamp('indicator_lamp'),
  multiValue('multi_value'),
  aggregate('aggregate'),
  gaugeBar('gauge_bar');

  final String wireName;
  const WidgetType(this.wireName);

  String get label {
    switch (this) {
      case WidgetType.singleValue:
        return 'Single Value';
      case WidgetType.historyChart:
        return 'History Chart';
      case WidgetType.indicatorLamp:
        return 'Indicator Lamp';
      case WidgetType.multiValue:
        return 'Multi Value';
      case WidgetType.aggregate:
        return 'Aggregate';
      case WidgetType.gaugeBar:
        return 'Gauge Bar';
    }
  }

  static WidgetType fromString(String value) {
    return WidgetType.values.firstWhere(
      (type) => type.wireName == value,
      orElse: () => throw ArgumentError('Unknown WidgetType wire name: $value'),
    );
  }

  String toJson() => wireName;
}
