import Charts
import SwiftUI
import WidgetKit

// MARK: - Color Hex Extension

extension Color {
    public init(hexString: String) {
        var hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hex.hasPrefix("0x") || hex.hasPrefix("0X") {
            hex = String(hex.dropFirst(2))
        }
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Formatters & Evaluators

public enum WidgetViewHelpers {
    public static func formatValue(_ value: Double?, decimalPlaces: Int?, unit: String?) -> String {
        guard let val = value else { return "--" }
        let decimals = decimalPlaces ?? 1
        let formatted = String(format: "%.\(decimals)f", val)
        if let u = unit, !u.isEmpty {
            return "\(formatted) \(u)"
        }
        return formatted
    }

    public static func evaluateThresholdColor(widget: WidgetDefinition, value: Double?) -> Color? {
        guard let value = value else { return nil }

        // Multiple thresholds
        if let thresholds = widget.thresholds, !thresholds.isEmpty {
            for t in thresholds where t.matches(value) {
                if let c = t.color { return Color(hexString: c) }
            }
        }

        // Single threshold
        if let t = widget.threshold {
            if t.matches(value) {
                if let c = t.color ?? t.activeColor { return Color(hexString: c) }
            } else {
                if let c = t.inactiveColor { return Color(hexString: c) }
            }
        }

        return nil
    }
}

// MARK: - Subviews for Widget Types

public struct SingleValueWidgetView: View {
    public let widget: WidgetDefinition
    public let data: CachedSensorData?

    public var body: some View {
        let value = data?.singleValue
        let color = WidgetViewHelpers.evaluateThresholdColor(widget: widget, value: value) ?? .primary

        VStack(alignment: .leading, spacing: 4) {
            Text(widget.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Text(WidgetViewHelpers.formatValue(value, decimalPlaces: widget.decimalPlaces, unit: widget.unit))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Spacer()

            if let error = data?.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            } else {
                Text(data?.lastUpdated.formatted(date: .omitted, time: .shortened) ?? "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

public struct HistoryChartWidgetView: View {
    public let widget: WidgetDefinition
    public let data: CachedSensorData?

    public var body: some View {
        let series = data?.series ?? []
        let latest = series.last?.value ?? data?.singleValue

        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(widget.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Text(WidgetViewHelpers.formatValue(latest, decimalPlaces: widget.decimalPlaces, unit: widget.unit))
                    .font(.caption)
                    .fontWeight(.bold)
            }

            if series.isEmpty {
                Spacer()
                Text("No data available")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                Chart(series, id: \.timestamp) { item in
                    LineMark(
                        x: .value("Time", item.timestamp),
                        y: .value("Value", item.value)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.accentColor)

                    AreaMark(
                        x: .value("Time", item.timestamp),
                        y: .value("Value", item.value)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

public struct IndicatorLampWidgetView: View {
    public let widget: WidgetDefinition
    public let data: CachedSensorData?

    public var body: some View {
        let value = data?.singleValue
        let indicatorColor = WidgetViewHelpers.evaluateThresholdColor(widget: widget, value: value) ?? .green

        VStack(spacing: 8) {
            Text(widget.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Circle()
                .fill(indicatorColor)
                .frame(width: 32, height: 32)
                .shadow(color: indicatorColor.opacity(0.6), radius: 6, x: 0, y: 0)

            Text(WidgetViewHelpers.formatValue(value, decimalPlaces: widget.decimalPlaces, unit: widget.unit))
                .font(.footnote)
                .fontWeight(.semibold)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct GaugeBarWidgetView: View {
    public let widget: WidgetDefinition
    public let data: CachedSensorData?

    public var body: some View {
        let value = data?.singleValue ?? 0
        let minVal = widget.min ?? 0
        let maxVal = widget.max ?? 100
        let fraction = max(0.0, min(1.0, (value - minVal) / (maxVal - minVal > 0 ? (maxVal - minVal) : 1)))
        let barColor = WidgetViewHelpers.evaluateThresholdColor(widget: widget, value: value) ?? .blue

        VStack(alignment: .leading, spacing: 6) {
            Text(widget.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Text(WidgetViewHelpers.formatValue(value, decimalPlaces: widget.decimalPlaces, unit: widget.unit))
                .font(.title2)
                .fontWeight(.bold)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(fraction), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text(String(format: "%.0f", minVal))
                Spacer()
                Text(String(format: "%.0f", maxVal))
            }
            .font(.system(size: 9))
            .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

public struct AggregateWidgetView: View {
    public let widget: WidgetDefinition
    public let data: CachedSensorData?

    public var body: some View {
        let agg = data?.aggregate ?? [:]
        let minVal = agg["min"]
        let meanVal = agg["mean"]
        let maxVal = agg["max"]
        let dec = widget.decimalPlaces ?? 1

        VStack(alignment: .leading, spacing: 4) {
            Text(widget.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 8) {
                aggItem(label: "MIN", value: minVal, decimals: dec, color: .blue)
                aggItem(label: "AVG", value: meanVal, decimals: dec, color: .primary)
                aggItem(label: "MAX", value: maxVal, decimals: dec, color: .red)
            }

            Spacer()

            Text(widget.timeRange ?? "24h")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func aggItem(label: String, value: Double?, decimals: Int, color: Color) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value != nil ? String(format: "%.\(decimals)f", value!) : "--")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

public struct MultiValueWidgetView: View {
    public let widget: WidgetDefinition
    public let data: CachedSensorData?

    public var body: some View {
        let multi = data?.multiValues ?? [:]
        let items = widget.items ?? []

        VStack(alignment: .leading, spacing: 4) {
            Text(widget.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            ForEach(items.prefix(3), id: \.field) { item in
                let val = multi[item.field]
                HStack {
                    Text(item.label ?? item.field)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Text(WidgetViewHelpers.formatValue(val, decimalPlaces: item.decimalPlaces ?? widget.decimalPlaces, unit: item.unit ?? widget.unit))
                        .font(.caption)
                        .fontWeight(.bold)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Root Entry View

public struct SensorWidgetEntryView: View {
    public let entry: SensorTimelineEntry

    public var body: some View {
        if let widget = entry.widget {
            contentView(for: widget)
                .widgetURL(URL(string: "influxwidget://widget/\(widget.id)"))
        } else {
            VStack(spacing: 4) {
                Image(systemName: "gauge.with.needle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Select Widget")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("Long press to configure")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func contentView(for widget: WidgetDefinition) -> some View {
        switch widget.type {
        case .singleValue:
            SingleValueWidgetView(widget: widget, data: entry.data)
        case .historyChart:
            HistoryChartWidgetView(widget: widget, data: entry.data)
        case .indicatorLamp:
            IndicatorLampWidgetView(widget: widget, data: entry.data)
        case .gaugeBar:
            GaugeBarWidgetView(widget: widget, data: entry.data)
        case .aggregate:
            AggregateWidgetView(widget: widget, data: entry.data)
        case .multiValue:
            MultiValueWidgetView(widget: widget, data: entry.data)
        }
    }
}
