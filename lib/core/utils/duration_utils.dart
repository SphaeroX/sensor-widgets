/// Helpers for InfluxQL duration literals (`30m`, `24h`, `7d`).
class DurationUtils {
  const DurationUtils._();

  /// Maximum number of time buckets requested per query.
  static const int maxBuckets = 300;

  /// Bucket count targeted when no interval is configured.
  static const int defaultTargetBuckets = 60;

  static const Map<String, int> _unitSeconds = {
    's': 1,
    'm': 60,
    'h': 3600,
    'd': 86400,
    'w': 604800,
  };

  /// Intervals tried (smallest first) when a bucket size must be derived.
  static const List<String> _ladder = [
    '1m',
    '5m',
    '10m',
    '15m',
    '30m',
    '1h',
    '3h',
    '6h',
    '12h',
    '1d',
    '7d',
  ];

  /// Parses an InfluxQL duration into seconds, or null if it is not valid.
  static int? parseSeconds(String duration) {
    final match = RegExp(r'^(\d+)([smhdw])$').firstMatch(duration.trim());
    if (match == null) return null;
    return int.parse(match.group(1)!) * _unitSeconds[match.group(2)!]!;
  }

  /// Returns the bucket interval to use for [timeRange].
  ///
  /// Uses [requested] if given and valid, otherwise derives one aiming for
  /// [defaultTargetBuckets]. The result never yields more than [maxBuckets].
  static String effectiveBucketInterval({
    required String timeRange,
    String? requested,
  }) {
    final rangeSeconds = parseSeconds(timeRange);
    if (rangeSeconds == null) return '1h';

    final requestedSeconds = requested == null ? null : parseSeconds(requested);
    if (requestedSeconds != null && requestedSeconds > 0) {
      if (rangeSeconds / requestedSeconds <= maxBuckets) return requested!;
      return _coarsest(rangeSeconds, maxBuckets);
    }
    return _coarsest(rangeSeconds, defaultTargetBuckets);
  }

  static String _coarsest(int rangeSeconds, int maxCount) {
    for (final candidate in _ladder) {
      if (rangeSeconds / parseSeconds(candidate)! <= maxCount) return candidate;
    }
    return '${(rangeSeconds / maxCount).ceil()}s';
  }
}
