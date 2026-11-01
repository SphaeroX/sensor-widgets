import 'package:sensor_widgets/domain/chart/chart_color.dart';

/// One color anchor of a value gradient. [color] is `#RRGGBB`.
class ColorStop {
  final double value;
  final String color;

  const ColorStop({required this.value, required this.color});

  factory ColorStop.fromJson(Map<String, dynamic> json) => ColorStop(
    value: (json['value'] as num).toDouble(),
    color: json['color'] as String,
  );

  Map<String, dynamic> toJson() => {'value': value, 'color': color};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorStop && value == other.value && color == other.color;

  @override
  int get hashCode => Object.hash(value, color);

  @override
  String toString() => 'ColorStop($value, $color)';
}

/// Optional styling of the history chart (contract field `chartStyle`).
///
/// With [colorStops] the line is colored by the Y value (continuous gradient
/// between the stops); without stops the widget's default color is used.
class ChartStyle {
  static const double defaultLineWidth = 2.0;

  final List<ColorStop> colorStops;
  final bool fillArea;
  final bool showGrid;
  final bool showAxes;
  final bool markMinMax;
  final double lineWidth;

  const ChartStyle({
    this.colorStops = const [],
    this.fillArea = false,
    this.showGrid = false,
    this.showAxes = false,
    this.markMinMax = false,
    this.lineWidth = defaultLineWidth,
  });

  static const List<ColorStop> greenToRedStops = [
    ColorStop(value: 0, color: '#4CAF50'),
    ColorStop(value: 50, color: '#FFC107'),
    ColorStop(value: 100, color: '#F44336'),
  ];

  static const List<ColorStop> redToGreenStops = [
    ColorStop(value: 0, color: '#F44336'),
    ColorStop(value: 50, color: '#FFC107'),
    ColorStop(value: 100, color: '#4CAF50'),
  ];

  bool get isValid =>
      lineWidth > 0 && colorStops.every((s) => parseHexColor(s.color) != null);

  factory ChartStyle.fromJson(Map<String, dynamic> json) {
    return ChartStyle(
      colorStops: ((json['colorStops'] as List<dynamic>?) ?? const [])
          .map((e) => ColorStop.fromJson(e as Map<String, dynamic>))
          .toList(),
      fillArea: json['fillArea'] as bool? ?? false,
      showGrid: json['showGrid'] as bool? ?? false,
      showAxes: json['showAxes'] as bool? ?? false,
      markMinMax: json['markMinMax'] as bool? ?? false,
      lineWidth: (json['lineWidth'] as num?)?.toDouble() ?? defaultLineWidth,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (colorStops.isNotEmpty) {
      map['colorStops'] = colorStops.map((s) => s.toJson()).toList();
    }
    if (fillArea) map['fillArea'] = true;
    if (showGrid) map['showGrid'] = true;
    if (showAxes) map['showAxes'] = true;
    if (markMinMax) map['markMinMax'] = true;
    if (lineWidth != defaultLineWidth) map['lineWidth'] = lineWidth;
    return map;
  }

  ChartStyle copyWith({
    List<ColorStop>? colorStops,
    bool? fillArea,
    bool? showGrid,
    bool? showAxes,
    bool? markMinMax,
    double? lineWidth,
  }) {
    return ChartStyle(
      colorStops: colorStops ?? this.colorStops,
      fillArea: fillArea ?? this.fillArea,
      showGrid: showGrid ?? this.showGrid,
      showAxes: showAxes ?? this.showAxes,
      markMinMax: markMinMax ?? this.markMinMax,
      lineWidth: lineWidth ?? this.lineWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartStyle &&
          _listEquals(colorStops, other.colorStops) &&
          fillArea == other.fillArea &&
          showGrid == other.showGrid &&
          showAxes == other.showAxes &&
          markMinMax == other.markMinMax &&
          lineWidth == other.lineWidth;

  static bool _listEquals(List<ColorStop> a, List<ColorStop> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(colorStops),
    fillArea,
    showGrid,
    showAxes,
    markMinMax,
    lineWidth,
  );
}
