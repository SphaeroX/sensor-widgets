import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/core/utils/duration_utils.dart';

void main() {
  group('DurationUtils.parseSeconds', () {
    test('parses InfluxQL durations', () {
      expect(DurationUtils.parseSeconds('90s'), 90);
      expect(DurationUtils.parseSeconds('30m'), 1800);
      expect(DurationUtils.parseSeconds('24h'), 86400);
      expect(DurationUtils.parseSeconds('7d'), 604800);
      expect(DurationUtils.parseSeconds('2w'), 1209600);
    });

    test('returns null for invalid input', () {
      expect(DurationUtils.parseSeconds(''), isNull);
      expect(DurationUtils.parseSeconds('abc'), isNull);
      expect(DurationUtils.parseSeconds('10x'), isNull);
    });
  });

  group('DurationUtils.effectiveBucketInterval', () {
    test('keeps requested interval when bucket count is small enough', () {
      expect(
        DurationUtils.effectiveBucketInterval(
          timeRange: '24h',
          requested: '1h',
        ),
        '1h',
      );
    });

    test('coarsens the interval above the maximum bucket count', () {
      // 7d / 1m = 10080 buckets -> must be coarsened to <= 300 buckets.
      final interval = DurationUtils.effectiveBucketInterval(
        timeRange: '7d',
        requested: '1m',
      );
      final buckets =
          DurationUtils.parseSeconds('7d')! /
          DurationUtils.parseSeconds(interval)!;
      expect(buckets, lessThanOrEqualTo(300));
    });

    test('derives a sensible default when nothing is requested', () {
      final interval = DurationUtils.effectiveBucketInterval(timeRange: '24h');
      final buckets =
          DurationUtils.parseSeconds('24h')! /
          DurationUtils.parseSeconds(interval)!;
      expect(buckets, lessThanOrEqualTo(60));
      expect(buckets, greaterThan(5));
    });

    test('falls back to 1h for unparseable input', () {
      expect(DurationUtils.effectiveBucketInterval(timeRange: 'garbage'), '1h');
    });
  });
}
