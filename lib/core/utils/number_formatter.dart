/// Utilities for consistent decimal rounding and formatting across the app.
class NumberFormatter {
  const NumberFormatter._();

  /// Formats [value] to at most [maxDecimals] decimal places (default 2).
  ///
  /// - Returns `'--'` if [value] is null.
  /// - If [decimalPlaces] is explicitly provided, it is clamped to `0..maxDecimals`.
  /// - If [decimalPlaces] is omitted, up to [maxDecimals] are displayed without
  ///   trailing zeros for integers (e.g. `20` instead of `20.00`).
  /// - Floating point arithmetic artifacts (e.g. `15.150000000000002`) are rounded cleanly.
  static String format(
    double? value, {
    int? decimalPlaces,
    int maxDecimals = 2,
  }) {
    if (value == null) return '--';

    if (decimalPlaces != null) {
      final clamped = decimalPlaces.clamp(0, maxDecimals);
      return value.toStringAsFixed(clamped);
    }

    // Default: round to maxDecimals without IEEE floating point noise
    final rounded = roundToMaxDecimals(value, maxDecimals: maxDecimals);
    if (rounded == rounded.truncateToDouble()) {
      return rounded.truncate().toString();
    }

    final formatted = rounded.toStringAsFixed(maxDecimals);
    if (formatted.endsWith('.00')) {
      return formatted.substring(0, formatted.length - 3);
    }
    if (formatted.endsWith('0') && formatted.contains('.')) {
      return formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  /// Rounds a double to at most [maxDecimals] (default 2) decimal places,
  /// avoiding IEEE-754 precision artifacts.
  static double roundToMaxDecimals(double value, {int maxDecimals = 2}) {
    final fixed = value.toStringAsFixed(maxDecimals);
    return double.parse(fixed);
  }
}
