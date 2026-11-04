import Foundation

/// Push notification rule (contract field `alerts`). `target` is `value` for the primary
/// value (with a formula the calculated value, history chart: latest point), a row `field`
/// of a multi-value widget, or `min`/`max`/`mean` of an aggregate.
public struct AlertRule: Codable, Equatable {
    public static let targetValue = "value"

    public let target: String
    public let `operator`: ThresholdOperator
    public let value: Double

    public init(target: String, operator: ThresholdOperator, value: Double) {
        self.target = target
        self.operator = `operator`
        self.value = value
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

public struct AlertHit: Equatable {
    public let rule: AlertRule
    public let actualValue: Double

    public init(rule: AlertRule, actualValue: Double) {
        self.rule = rule
        self.actualValue = actualValue
    }
}

/// Edge-triggered threshold check, same cases as Android: `fixtures/alerts/evaluation_cases.json`.
/// A rule notifies when it starts matching and again only after it stopped matching once.
public enum AlertEvaluator {
    public struct Result: Equatable {
        public let triggered: [AlertHit]
        public let active: [AlertRule]
    }

    public static func evaluate(rules: [AlertRule], data: CachedSensorData, previouslyActive: [AlertRule]) -> Result {
        if data.errorMessage != nil {
            return Result(triggered: [], active: rules.filter { previouslyActive.contains($0) })
        }
        var triggered: [AlertHit] = []
        var active: [AlertRule] = []
        for rule in rules {
            let wasActive = previouslyActive.contains(rule)
            guard let actual = resolveValue(target: rule.target, data: data) else {
                if wasActive { active.append(rule) }
                continue
            }
            if rule.matches(actual) {
                active.append(rule)
                if !wasActive { triggered.append(AlertHit(rule: rule, actualValue: actual)) }
            }
        }
        return Result(triggered: triggered, active: active)
    }

    public static func resolveValue(target: String, data: CachedSensorData) -> Double? {
        if target == AlertRule.targetValue {
            if let value = data.singleValue { return value }
            if let last = data.series?.last { return last.value }
        }
        if let row = data.multiValues?[target] { return row }
        return data.aggregate?[target]
    }
}

/// Notification texts in the device language, e.g. "Temperature: 17.2 °C (below 18.5 °C)".
public enum AlertMessage {
    private static let aggregateNames: [String: WidgetTexts.Key] = [
        "min": .alertTargetMin, "max": .alertTargetMax, "mean": .alertTargetMean
    ]

    public static func title(_ widget: WidgetDefinition) -> String {
        widget.title
    }

    public static func body(_ widget: WidgetDefinition, _ hit: AlertHit) -> String {
        let target = hit.rule.target
        let item = widget.items?.first { $0.field == target }
        let label: String
        if target == AlertRule.targetValue {
            label = widget.title
        } else if let item = item {
            label = item.label ?? item.field
        } else {
            label = aggregateNames[target].map { WidgetTexts.current.text($0) } ?? target
        }
        let unit = (item?.unit ?? widget.unit).map { " \($0)" } ?? ""
        let decimals = min(max(item?.decimalPlaces ?? widget.decimalPlaces ?? 1, 0), 6)
        let direction = WidgetTexts.current.text(hit.rule.operator == .greaterThan ? .alertAbove : .alertBelow)
        return WidgetTexts.current.text(
            .alertBody,
            label,
            format(hit.actualValue, decimals),
            unit,
            direction,
            format(hit.rule.value, decimals),
            unit
        )
    }

    private static func format(_ value: Double, _ decimals: Int) -> String {
        String(format: "%.\(decimals)f", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}

/// Short network outages keep the last values on screen; only after `graceInterval`
/// of consecutive network failures is the error shown (same rule as Android).
public enum NetworkErrorGrace {
    public static let graceInterval: TimeInterval = 3600

    public static func fallback(
        cached: CachedSensorData?,
        errorMessage: String,
        isNetworkError: Bool,
        failureSince: Date,
        now: Date
    ) -> CachedSensorData {
        if isNetworkError, let cached = cached, cached.errorMessage == nil,
           now.timeIntervalSince(failureSince) < graceInterval {
            return cached
        }
        return CachedSensorData(
            singleValue: cached?.singleValue,
            series: cached?.series,
            multiValues: cached?.multiValues,
            aggregate: cached?.aggregate,
            lastUpdated: cached?.lastUpdated ?? now,
            errorMessage: errorMessage
        )
    }
}
