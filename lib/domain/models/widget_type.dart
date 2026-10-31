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

  static WidgetType fromString(String value) {
    return WidgetType.values.firstWhere(
      (type) => type.wireName == value,
      orElse: () => throw ArgumentError('Unknown WidgetType wire name: $value'),
    );
  }

  String toJson() => wireName;
}
