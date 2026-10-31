import Foundation
import WidgetKit

public struct SensorTimelineEntry: TimelineEntry {
    public let date: Date
    public let widget: WidgetDefinition?
    public let data: CachedSensorData?
    public let isPreview: Bool

    public init(
        date: Date = Date(),
        widget: WidgetDefinition? = nil,
        data: CachedSensorData? = nil,
        isPreview: Bool = false
    ) {
        self.date = date
        self.widget = widget
        self.data = data
        self.isPreview = isPreview
    }
}

public struct SensorTimelineProvider: AppIntentTimelineProvider {
    public typealias Entry = SensorTimelineEntry
    public typealias Intent = SelectWidgetIntent

    private let storage: SharedGroupStorage
    private let httpClient: InfluxHttpClient

    public init(
        storage: SharedGroupStorage = .shared,
        httpClient: InfluxHttpClient = InfluxHttpClient()
    ) {
        self.storage = storage
        self.httpClient = httpClient
    }

    public func placeholder(in context: Context) -> SensorTimelineEntry {
        SensorTimelineEntry(
            date: Date(),
            widget: WidgetDefinition(
                id: "placeholder",
                type: .singleValue,
                title: "Living Room",
                connectionId: "conn-1",
                measurement: "temperature",
                field: "temp",
                unit: "°C",
                decimalPlaces: 1
            ),
            data: CachedSensorData(singleValue: 21.5, lastUpdated: Date()),
            isPreview: true
        )
    }

    public func snapshot(for configuration: SelectWidgetIntent, in context: Context) async -> SensorTimelineEntry {
        if context.isPreview {
            return placeholder(in: context)
        }
        let (widget, data) = await resolveWidgetAndData(for: configuration)
        return SensorTimelineEntry(date: Date(), widget: widget, data: data, isPreview: false)
    }

    public func timeline(for configuration: SelectWidgetIntent, in context: Context) async -> Timeline<SensorTimelineEntry> {
        let (widget, data) = await resolveWidgetAndData(for: configuration)
        let intervalMinutes = max(15, widget?.refreshIntervalMinutes ?? 15)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: intervalMinutes, to: Date())
            ?? Date().addingTimeInterval(TimeInterval(intervalMinutes * 60))

        let entry = SensorTimelineEntry(date: Date(), widget: widget, data: data, isPreview: false)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func resolveWidgetAndData(for configuration: SelectWidgetIntent) async -> (WidgetDefinition?, CachedSensorData?) {
        let widget: WidgetDefinition?
        if let widgetId = configuration.widget?.id {
            widget = storage.loadWidgetDefinition(id: widgetId)
        } else {
            widget = storage.loadWidgetDefinitions().first
        }

        guard let widget = widget else {
            return (nil, nil)
        }

        var cached = storage.loadCachedData(widgetId: widget.id)
        guard let connection = storage.loadConnection(id: widget.connectionId),
              let token = storage.loadToken(connectionId: widget.connectionId),
              !token.isEmpty else {
            return (widget, cached)
        }

        do {
            let refreshed = try await fetchSensorData(widget: widget, connection: connection, token: token)
            storage.saveCachedData(widgetId: widget.id, data: refreshed)
            return (widget, refreshed)
        } catch {
            let errorMsg = InfluxHttpClient.maskToken(error.localizedDescription, token: token)
            let fallback = CachedSensorData(
                singleValue: cached?.singleValue,
                series: cached?.series,
                multiValues: cached?.multiValues,
                aggregate: cached?.aggregate,
                lastUpdated: cached?.lastUpdated ?? Date(),
                errorMessage: errorMsg
            )
            return (widget, fallback)
        }
    }

    private func fetchSensorData(
        widget: WidgetDefinition,
        connection: InfluxConnection,
        token: String
    ) async throws -> CachedSensorData {
        switch widget.type {
        case .singleValue, .indicatorLamp, .gaugeBar:
            let field = widget.field ?? "value"
            let q = InfluxQlBuilder.buildSingleValueQuery(
                measurement: widget.measurement,
                field: field,
                tagFilters: widget.tagFilters
            )
            let data = try await httpClient.query(connection: connection, token: token, influxQl: q)
            let pt = try InfluxResponseParser.parseSingleValue(data: data, fieldName: field)
            return CachedSensorData(singleValue: pt?.value, lastUpdated: pt?.timestamp ?? Date())

        case .historyChart:
            let field = widget.field ?? "value"
            let timeRange = widget.timeRange ?? "24h"
            let bucket = widget.aggregationInterval ?? "15m"
            let q = InfluxQlBuilder.buildHistoryQuery(
                measurement: widget.measurement,
                field: field,
                timeRange: timeRange,
                bucketInterval: bucket,
                tagFilters: widget.tagFilters
            )
            let data = try await httpClient.query(connection: connection, token: token, influxQl: q)
            let points = try InfluxResponseParser.parseTimeSeries(data: data, fieldName: field)
            return CachedSensorData(
                singleValue: points.last?.value,
                series: points,
                lastUpdated: points.last?.timestamp ?? Date()
            )

        case .aggregate:
            let field = widget.field ?? "value"
            let timeRange = widget.timeRange ?? "24h"
            let q = InfluxQlBuilder.buildAggregateQuery(
                measurement: widget.measurement,
                field: field,
                timeRange: timeRange,
                tagFilters: widget.tagFilters
            )
            let data = try await httpClient.query(connection: connection, token: token, influxQl: q)
            let agg = try InfluxResponseParser.parseAggregate(data: data)
            return CachedSensorData(aggregate: agg, lastUpdated: Date())

        case .multiValue:
            let fields = widget.items?.map { $0.field } ?? [widget.field ?? "value"]
            let q = InfluxQlBuilder.buildMultiValueQuery(
                measurement: widget.measurement,
                fields: fields,
                tagFilters: widget.tagFilters
            )
            let data = try await httpClient.query(connection: connection, token: token, influxQl: q)
            let multiMap = try InfluxResponseParser.parseMultiValues(data: data, fields: fields)
            var values: [String: Double] = [:]
            for (k, v) in multiMap {
                values[k] = v.value
            }
            return CachedSensorData(multiValues: values, lastUpdated: Date())
        }
    }
}
