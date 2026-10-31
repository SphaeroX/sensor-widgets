import Foundation

public enum WidgetType: String, Codable {
    case singleValue = "single_value"
    case historyChart = "history_chart"
    case indicatorLamp = "indicator_lamp"
    case multiValue = "multi_value"
    case aggregate = "aggregate"
    case gaugeBar = "gauge_bar"

    public var label: String {
        switch self {
        case .singleValue: return "Single Value"
        case .historyChart: return "History Chart"
        case .indicatorLamp: return "Indicator Lamp"
        case .multiValue: return "Multi Value"
        case .aggregate: return "Aggregate"
        case .gaugeBar: return "Gauge Bar"
        }
    }
}

public enum ThresholdOperator: String, Codable {
    case greaterThan = "greaterThan"
    case lessThan = "lessThan"
}

public struct ThresholdRule: Codable, Equatable {
    public let `operator`: ThresholdOperator
    public let value: Double
    public let color: String?
    public let activeColor: String?
    public let inactiveColor: String?

    public init(
        operator: ThresholdOperator,
        value: Double,
        color: String? = nil,
        activeColor: String? = nil,
        inactiveColor: String? = nil
    ) {
        self.operator = `operator`
        self.value = value
        self.color = color
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
    }

    public func matches(_ actualValue: Double) -> Bool {
        switch `operator` {
        case .greaterThan:
            return actualValue > value
        case .lessThan:
            return actualValue < value
        }
    }
}

public struct SensorQueryItem: Codable, Equatable {
    public let field: String
    public let label: String?
    public let unit: String?
    public let decimalPlaces: Int?

    public init(
        field: String,
        label: String? = nil,
        unit: String? = nil,
        decimalPlaces: Int? = nil
    ) {
        self.field = field
        self.label = label
        self.unit = unit
        self.decimalPlaces = decimalPlaces
    }
}

public struct SensorDataPoint: Codable, Equatable {
    public let timestamp: Date
    public let value: Double
    public let field: String

    public init(timestamp: Date, value: Double, field: String) {
        self.timestamp = timestamp
        self.value = value
        self.field = field
    }
}

public struct InfluxConnection: Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let url: String
    public let database: String

    public init(id: String, name: String, url: String, database: String) {
        self.id = id
        self.name = name
        self.url = url
        self.database = database
    }
}

public struct WidgetDefinition: Codable, Equatable, Identifiable {
    public let id: String
    public let type: WidgetType
    public let title: String
    public let connectionId: String
    public let measurement: String
    public let field: String?
    public let tagFilters: [String: String]?
    public let unit: String?
    public let decimalPlaces: Int?
    public let refreshIntervalMinutes: Int?
    public let timeRange: String?
    public let aggregationInterval: String?
    public let aggregateFunction: String?
    public let threshold: ThresholdRule?
    public let min: Double?
    public let max: Double?
    public let thresholds: [ThresholdRule]?
    public let items: [SensorQueryItem]?

    public init(
        id: String,
        type: WidgetType,
        title: String,
        connectionId: String,
        measurement: String,
        field: String? = nil,
        tagFilters: [String: String]? = nil,
        unit: String? = nil,
        decimalPlaces: Int? = nil,
        refreshIntervalMinutes: Int? = 15,
        timeRange: String? = nil,
        aggregationInterval: String? = nil,
        aggregateFunction: String? = nil,
        threshold: ThresholdRule? = nil,
        min: Double? = nil,
        max: Double? = nil,
        thresholds: [ThresholdRule]? = nil,
        items: [SensorQueryItem]? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.connectionId = connectionId
        self.measurement = measurement
        self.field = field
        self.tagFilters = tagFilters
        self.unit = unit
        self.decimalPlaces = decimalPlaces
        self.refreshIntervalMinutes = refreshIntervalMinutes
        self.timeRange = timeRange
        self.aggregationInterval = aggregationInterval
        self.aggregateFunction = aggregateFunction
        self.threshold = threshold
        self.min = min
        self.max = max
        self.thresholds = thresholds
        self.items = items
    }
}

public struct WidgetDefinitionsEnvelope: Codable {
    public let schemaVersion: Int?
    public let widgets: [WidgetDefinition]

    public init(schemaVersion: Int? = nil, widgets: [WidgetDefinition]) {
        self.schemaVersion = schemaVersion
        self.widgets = widgets
    }
}
