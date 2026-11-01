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
    public let formula: String?
    public let formulaVariables: [FormulaVariable]?
    public let formulaSteps: [FormulaStep]?

    public var hasFormula: Bool {
        guard let formula = formula else { return false }
        return !formula.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public init(
        field: String,
        label: String? = nil,
        unit: String? = nil,
        decimalPlaces: Int? = nil,
        formula: String? = nil,
        formulaVariables: [FormulaVariable]? = nil,
        formulaSteps: [FormulaStep]? = nil
    ) {
        self.field = field
        self.label = label
        self.unit = unit
        self.decimalPlaces = decimalPlaces
        self.formula = formula
        self.formulaVariables = formulaVariables
        self.formulaSteps = formulaSteps
    }
}

public struct FormulaVariable: Codable, Equatable {
    public let name: String
    public let field: String
    public let measurement: String?
    public let tagFilters: [String: String]?
    public let label: String?

    public init(
        name: String,
        field: String,
        measurement: String? = nil,
        tagFilters: [String: String]? = nil,
        label: String? = nil
    ) {
        self.name = name
        self.field = field
        self.measurement = measurement
        self.tagFilters = tagFilters
        self.label = label
    }
}

public struct FormulaStep: Codable, Equatable {
    public let name: String
    public let expression: String
    public let label: String?

    public init(name: String, expression: String, label: String? = nil) {
        self.name = name
        self.expression = expression
        self.label = label
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
    public let formula: String?
    public let formulaVariables: [FormulaVariable]?
    public let formulaSteps: [FormulaStep]?
    public let gapPolicy: String?
    public let chartStyle: ChartStyle?
    public let appearance: WidgetAppearance?

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
        items: [SensorQueryItem]? = nil,
        formula: String? = nil,
        formulaVariables: [FormulaVariable]? = nil,
        formulaSteps: [FormulaStep]? = nil,
        gapPolicy: String? = nil,
        chartStyle: ChartStyle? = nil,
        appearance: WidgetAppearance? = nil
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
        self.formula = formula
        self.formulaVariables = formulaVariables
        self.formulaSteps = formulaSteps
        self.gapPolicy = gapPolicy
        self.chartStyle = chartStyle
        self.appearance = appearance
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
