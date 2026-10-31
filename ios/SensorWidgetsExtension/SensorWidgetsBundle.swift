import SwiftUI
import WidgetKit

public struct SensorWidget: Widget {
    public let kind: String = "SensorWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectWidgetIntent.self,
            provider: SensorTimelineProvider()
        ) { entry in
            SensorWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    #if canImport(UIKit)
                    Color(uiColor: .systemBackground)
                    #else
                    Color.clear
                    #endif
                }
        }
        .configurationDisplayName("InfluxDB Sensor")
        .description("Display live InfluxDB sensor data on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct SensorWidgetsBundle: WidgetBundle {
    var body: some Widget {
        SensorWidget()
    }
}
