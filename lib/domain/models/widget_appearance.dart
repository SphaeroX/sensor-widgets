import 'package:sensor_widgets/domain/chart/chart_color.dart';

/// Optional per-widget look (contract field `appearance`). Every value is
/// optional; unset values keep the platform default so widgets without
/// `appearance` look exactly as before.
class WidgetAppearance {
  /// Defaults documented in `docs/architecture.md`.
  static const double defaultBackgroundOpacity = 1.0;
  static const double defaultFontScale = 1.0;
  static const double defaultCornerRadius = 16.0;

  static const double minFontScale = 0.8;
  static const double maxFontScale = 1.4;
  static const double maxCornerRadius = 32.0;

  final String? backgroundColor;
  final double? backgroundOpacity;
  final String? textColor;
  final String? accentColor;
  final double? fontScale;
  final double? cornerRadius;

  const WidgetAppearance({
    this.backgroundColor,
    this.backgroundOpacity,
    this.textColor,
    this.accentColor,
    this.fontScale,
    this.cornerRadius,
  });

  bool get isEmpty =>
      backgroundColor == null &&
      backgroundOpacity == null &&
      textColor == null &&
      accentColor == null &&
      fontScale == null &&
      cornerRadius == null;

  bool get isValid {
    bool colorOk(String? c) => c == null || parseHexColor(c) != null;
    return colorOk(backgroundColor) &&
        colorOk(textColor) &&
        colorOk(accentColor) &&
        (backgroundOpacity == null ||
            (backgroundOpacity! >= 0 && backgroundOpacity! <= 1)) &&
        (fontScale == null || (fontScale! >= 0.5 && fontScale! <= 2.0)) &&
        (cornerRadius == null || (cornerRadius! >= 0 && cornerRadius! <= 48));
  }

  factory WidgetAppearance.fromJson(Map<String, dynamic> json) {
    return WidgetAppearance(
      backgroundColor: json['backgroundColor'] as String?,
      backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble(),
      textColor: json['textColor'] as String?,
      accentColor: json['accentColor'] as String?,
      fontScale: (json['fontScale'] as num?)?.toDouble(),
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (backgroundColor != null) map['backgroundColor'] = backgroundColor;
    if (backgroundOpacity != null) map['backgroundOpacity'] = backgroundOpacity;
    if (textColor != null) map['textColor'] = textColor;
    if (accentColor != null) map['accentColor'] = accentColor;
    if (fontScale != null) map['fontScale'] = fontScale;
    if (cornerRadius != null) map['cornerRadius'] = cornerRadius;
    return map;
  }

  WidgetAppearance copyWith({
    String? backgroundColor,
    double? backgroundOpacity,
    String? textColor,
    String? accentColor,
    double? fontScale,
    double? cornerRadius,
    bool clearBackgroundColor = false,
    bool clearTextColor = false,
    bool clearAccentColor = false,
  }) {
    return WidgetAppearance(
      backgroundColor: clearBackgroundColor
          ? null
          : (backgroundColor ?? this.backgroundColor),
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      textColor: clearTextColor ? null : (textColor ?? this.textColor),
      accentColor: clearAccentColor ? null : (accentColor ?? this.accentColor),
      fontScale: fontScale ?? this.fontScale,
      cornerRadius: cornerRadius ?? this.cornerRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetAppearance &&
          backgroundColor == other.backgroundColor &&
          backgroundOpacity == other.backgroundOpacity &&
          textColor == other.textColor &&
          accentColor == other.accentColor &&
          fontScale == other.fontScale &&
          cornerRadius == other.cornerRadius;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    backgroundOpacity,
    textColor,
    accentColor,
    fontScale,
    cornerRadius,
  );
}
