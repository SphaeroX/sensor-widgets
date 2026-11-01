import Foundation

/// Helpers for InfluxQL duration literals (`30m`, `24h`, `7d`). Mirrors the Dart `DurationUtils`.
public enum DurationUtils {
    public static let maxBuckets = 300
    public static let defaultTargetBuckets = 60

    private static let unitSeconds: [Character: Int] = ["s": 1, "m": 60, "h": 3600, "d": 86400, "w": 604800]
    private static let ladder = ["1m", "5m", "10m", "15m", "30m", "1h", "3h", "6h", "12h", "1d", "7d"]

    public static func parseSeconds(_ duration: String) -> Int? {
        let trimmed = duration.trimmingCharacters(in: .whitespaces)
        guard let unit = trimmed.last, let multiplier = unitSeconds[unit] else { return nil }
        let digits = trimmed.dropLast()
        guard !digits.isEmpty, digits.allSatisfy({ $0 >= "0" && $0 <= "9" }), let amount = Int(digits) else {
            return nil
        }
        return amount * multiplier
    }

    public static func effectiveBucketInterval(timeRange: String, requested: String?) -> String {
        guard let range = parseSeconds(timeRange) else { return "1h" }
        if let requested = requested, let requestedSeconds = parseSeconds(requested), requestedSeconds > 0 {
            return Double(range) / Double(requestedSeconds) <= Double(maxBuckets)
                ? requested
                : coarsest(range: range, maxCount: maxBuckets)
        }
        return coarsest(range: range, maxCount: defaultTargetBuckets)
    }

    private static func coarsest(range: Int, maxCount: Int) -> String {
        for candidate in ladder {
            if let seconds = parseSeconds(candidate), Double(range) / Double(seconds) <= Double(maxCount) {
                return candidate
            }
        }
        return "\(Int((Double(range) / Double(maxCount)).rounded(.up)))s"
    }
}
