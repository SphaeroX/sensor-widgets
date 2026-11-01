import Foundation

/// One color anchor of a value gradient; `color` is `#RRGGBB`.
public struct ColorStop: Codable, Equatable {
    public let value: Double
    public let color: String

    public init(value: Double, color: String) {
        self.value = value
        self.color = color
    }
}

/// Optional history chart styling (contract field `chartStyle`). Mirrors the Dart `ChartStyle`.
public struct ChartStyle: Codable, Equatable {
    public static let defaultLineWidth: Double = 2.0

    public let colorStops: [ColorStop]
    public let fillArea: Bool
    public let showGrid: Bool
    public let showAxes: Bool
    public let markMinMax: Bool
    public let lineWidth: Double

    public init(
        colorStops: [ColorStop] = [],
        fillArea: Bool = false,
        showGrid: Bool = false,
        showAxes: Bool = false,
        markMinMax: Bool = false,
        lineWidth: Double = ChartStyle.defaultLineWidth
    ) {
        self.colorStops = colorStops
        self.fillArea = fillArea
        self.showGrid = showGrid
        self.showAxes = showAxes
        self.markMinMax = markMinMax
        self.lineWidth = lineWidth
    }

    private enum CodingKeys: String, CodingKey {
        case colorStops, fillArea, showGrid, showAxes, markMinMax, lineWidth
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        colorStops = try container.decodeIfPresent([ColorStop].self, forKey: .colorStops) ?? []
        fillArea = try container.decodeIfPresent(Bool.self, forKey: .fillArea) ?? false
        showGrid = try container.decodeIfPresent(Bool.self, forKey: .showGrid) ?? false
        showAxes = try container.decodeIfPresent(Bool.self, forKey: .showAxes) ?? false
        markMinMax = try container.decodeIfPresent(Bool.self, forKey: .markMinMax) ?? false
        lineWidth = try container.decodeIfPresent(Double.self, forKey: .lineWidth) ?? ChartStyle.defaultLineWidth
    }
}

/// Colors (ARGB) and 0...1 positions of a vertical gradient; position 0 is the bottom of the chart.
public struct ChartGradient: Equatable {
    public let colors: [UInt32]
    public let positions: [Double]
}

/// Color gradient helpers shared with Dart and Kotlin
/// (contract: `fixtures/chart/color_interpolation_cases.json`).
public enum ChartColor {
    public static func parseHex(_ text: String) -> UInt32? {
        var hex = text.trimmingCharacters(in: .whitespaces)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, hex.allSatisfy({ $0.isHexDigit }), let rgb = UInt32(hex, radix: 16) else {
            return nil
        }
        return 0xFF00_0000 | rgb
    }

    public static func formatHex(_ argb: UInt32) -> String {
        String(format: "#%06X", argb & 0x00FF_FFFF)
    }

    private static func validSorted(_ stops: [ColorStop]) -> [ColorStop] {
        stops.filter { parseHex($0.color) != nil }.sorted { $0.value < $1.value }
    }

    private static func lerp(_ from: UInt32, _ to: UInt32, _ fraction: Double) -> UInt32 {
        let start = Double(from)
        let end = Double(to)
        return UInt32((start + (end - start) * fraction).rounded(.toNearestOrAwayFromZero))
    }

    /// Color for `value`; channels are interpolated linearly and rounded half away from zero.
    public static func interpolate(_ stops: [ColorStop], value: Double) -> UInt32? {
        let sorted = validSorted(stops)
        guard let first = sorted.first, let last = sorted.last else { return nil }
        if value <= first.value { return parseHex(first.color) }
        if value >= last.value { return parseHex(last.color) }

        for index in 0..<(sorted.count - 1) {
            let low = sorted[index]
            let high = sorted[index + 1]
            if value >= low.value && value <= high.value {
                let span = high.value - low.value
                let fraction = span == 0 ? 0 : (value - low.value) / span
                guard let from = parseHex(low.color), let to = parseHex(high.color) else { return nil }
                let red = lerp((from >> 16) & 0xFF, (to >> 16) & 0xFF, fraction)
                let green = lerp((from >> 8) & 0xFF, (to >> 8) & 0xFF, fraction)
                let blue = lerp(from & 0xFF, to & 0xFF, fraction)
                return 0xFF00_0000 | (red << 16) | (green << 8) | blue
            }
        }
        return parseHex(last.color)
    }

    public static func buildGradient(_ stops: [ColorStop], minValue: Double, maxValue: Double) -> ChartGradient? {
        let sorted = validSorted(stops)
        guard !sorted.isEmpty else { return nil }

        if maxValue <= minValue {
            guard let color = interpolate(sorted, value: minValue) else { return nil }
            return ChartGradient(colors: [color, color], positions: [0, 1])
        }

        let span = maxValue - minValue
        guard let startColor = interpolate(sorted, value: minValue),
              let endColor = interpolate(sorted, value: maxValue) else { return nil }
        var colors: [UInt32] = [startColor]
        var positions: [Double] = [0]
        for stop in sorted where stop.value > minValue && stop.value < maxValue {
            if let color = parseHex(stop.color) {
                positions.append((stop.value - minValue) / span)
                colors.append(color)
            }
        }
        colors.append(endColor)
        positions.append(1)
        return ChartGradient(colors: colors, positions: positions)
    }
}
