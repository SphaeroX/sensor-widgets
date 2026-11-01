import 'package:sensor_widgets/domain/models/chart_style.dart';

/// Parses `#RRGGBB` (the `#` is optional) to an opaque ARGB int, or null.
int? parseHexColor(String text) {
  final match = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(text.trim());
  if (match == null) return null;
  return 0xFF000000 | int.parse(match.group(1)!, radix: 16);
}

/// Formats an ARGB int as upper-case `#RRGGBB` (alpha is dropped).
String formatHexColor(int argb) {
  final rgb = (argb & 0xFFFFFF).toRadixString(16).toUpperCase();
  return '#${rgb.padLeft(6, '0')}';
}

List<ColorStop> _sortedValid(List<ColorStop> stops) {
  final valid = stops.where((s) => parseHexColor(s.color) != null).toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  return valid;
}

int _lerp(int a, int b, double t) => (a + (b - a) * t).round();

/// Color for [value] on the gradient defined by [stops] (any order).
///
/// Channels are interpolated linearly and rounded half away from zero; values
/// outside the range use the nearest stop. Returns null without usable stops.
/// Shared contract: `fixtures/chart/color_interpolation_cases.json`.
int? interpolateColor(List<ColorStop> stops, double value) {
  final sorted = _sortedValid(stops);
  if (sorted.isEmpty) return null;
  if (value <= sorted.first.value) return parseHexColor(sorted.first.color);
  if (value >= sorted.last.value) return parseHexColor(sorted.last.color);

  for (var i = 0; i < sorted.length - 1; i++) {
    final lo = sorted[i];
    final hi = sorted[i + 1];
    if (value >= lo.value && value <= hi.value) {
      final span = hi.value - lo.value;
      final t = span == 0 ? 0.0 : (value - lo.value) / span;
      final a = parseHexColor(lo.color)!;
      final b = parseHexColor(hi.color)!;
      final r = _lerp((a >> 16) & 0xFF, (b >> 16) & 0xFF, t);
      final g = _lerp((a >> 8) & 0xFF, (b >> 8) & 0xFF, t);
      final bl = _lerp(a & 0xFF, b & 0xFF, t);
      return 0xFF000000 | (r << 16) | (g << 8) | bl;
    }
  }
  return parseHexColor(sorted.last.color);
}

/// Colors and 0..1 positions (bottom = [ChartGradient.positions] 0) of a
/// vertical gradient covering the visible value range.
class ChartGradient {
  final List<int> colors;
  final List<double> positions;

  const ChartGradient({required this.colors, required this.positions});
}

/// Builds the vertical gradient for a chart whose Y axis spans
/// [minValue]..[maxValue]; returns null without usable stops.
ChartGradient? buildGradient(
  List<ColorStop> stops, {
  required double minValue,
  required double maxValue,
}) {
  final sorted = _sortedValid(stops);
  if (sorted.isEmpty) return null;

  if (maxValue <= minValue) {
    final c = interpolateColor(sorted, minValue)!;
    return ChartGradient(colors: [c, c], positions: const [0.0, 1.0]);
  }

  final span = maxValue - minValue;
  final colors = <int>[interpolateColor(sorted, minValue)!];
  final positions = <double>[0.0];
  for (final stop in sorted) {
    if (stop.value > minValue && stop.value < maxValue) {
      positions.add((stop.value - minValue) / span);
      colors.add(parseHexColor(stop.color)!);
    }
  }
  colors.add(interpolateColor(sorted, maxValue)!);
  positions.add(1.0);
  return ChartGradient(colors: colors, positions: positions);
}
