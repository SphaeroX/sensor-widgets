import Foundation

/// Evaluates a widget formula over time buckets. Mirrors the Dart
/// `FormulaCalculationService.calculateSeries/calculateAggregate`.
public enum FormulaSeriesCalculator {
    public struct BucketError: Equatable {
        public let timestamp: Int64
        public let error: FormulaError
    }

    public struct SeriesResult {
        public let points: [SensorDataPoint]
        public let errors: [BucketError]
    }

    private struct VariableGroup {
        let measurement: String
        let tagFilters: [String: String]?
        var variables: [FormulaVariable]
    }

    public static func calculateSeries(
        widget: WidgetDefinition,
        connection: InfluxConnection,
        token: String,
        httpClient: InfluxHttpClient
    ) async throws -> SeriesResult {
        let timeRange = widget.timeRange ?? "24h"
        let interval = DurationUtils.effectiveBucketInterval(timeRange: timeRange, requested: widget.aggregationInterval)
        var byVariable: [String: [Int64: Double]] = [:]

        for group in groupVariables(widget) {
            var fields: [String] = []
            for variable in group.variables where !fields.contains(variable.field) {
                fields.append(variable.field)
            }
            let query = InfluxQlBuilder.buildBucketedMultiFieldQuery(
                measurement: group.measurement,
                fields: fields,
                timeRange: timeRange,
                bucketInterval: interval,
                tagFilters: group.tagFilters
            )
            let data = try await httpClient.query(connection: connection, token: token, influxQl: query)
            let parsed = try InfluxResponseParser.parseBucketedFields(data: data, fields: fields)
            for variable in group.variables {
                byVariable[variable.name] = parsed[variable.field] ?? [:]
            }
        }
        return try combine(widget: widget, byVariable: byVariable)
    }

    /// Merges per-variable buckets, honours `gapPolicy` and evaluates the formula per bucket.
    public static func combine(
        widget: WidgetDefinition,
        byVariable: [String: [Int64: Double]]
    ) throws -> SeriesResult {
        guard let formula = widget.formula else {
            throw FormulaError.syntaxError("Widget besitzt keine Formel")
        }
        // Stable order independent of dictionary hashing.
        let names = (widget.formulaVariables ?? []).map { $0.name }.filter { byVariable[$0] != nil }
        for name in names where byVariable[name]?.isEmpty ?? true {
            throw FormulaError.missingVariable(name)
        }

        let carryForward = widget.gapPolicy == "previous"
        var timestamps = Set<Int64>()
        for name in names {
            if let series = byVariable[name] { timestamps.formUnion(series.keys) }
        }

        var last: [String: Double] = [:]
        var points: [SensorDataPoint] = []
        var errors: [BucketError] = []

        for timestamp in timestamps.sorted() {
            var values: [String: Double] = [:]
            var complete = true
            for name in names {
                let current = byVariable[name]?[timestamp]
                if let current = current { last[name] = current }
                if let resolved = current ?? (carryForward ? last[name] : nil) {
                    values[name] = resolved
                } else {
                    complete = false
                }
            }
            if !complete { continue }

            do {
                let raw = try FormulaEvaluator.evaluate(formula, variables: values, steps: widget.formulaSteps ?? [])
                points.append(SensorDataPoint(
                    timestamp: Date(timeIntervalSince1970: Double(timestamp) / 1000.0),
                    value: round(raw, widget: widget),
                    field: widget.field ?? "formula"
                ))
            } catch let error as FormulaError {
                errors.append(BucketError(timestamp: timestamp, error: error))
            }
        }

        if points.isEmpty, let first = errors.first { throw first.error }
        return SeriesResult(points: points, errors: errors)
    }

    /// Calculates the formula of one multi-value row from the latest values of its variables.
    public static func calculateItemLatest(
        widget: WidgetDefinition,
        item: SensorQueryItem,
        connection: InfluxConnection,
        token: String,
        httpClient: InfluxHttpClient
    ) async throws -> Double {
        let rowWidget = rowWidgetDefinition(widget: widget, item: item)
        var latest: [String: Double] = [:]
        for group in groupVariables(rowWidget) {
            var fields: [String] = []
            for variable in group.variables where !fields.contains(variable.field) {
                fields.append(variable.field)
            }
            let query = InfluxQlBuilder.buildMultiValueQuery(
                measurement: group.measurement,
                fields: fields,
                tagFilters: group.tagFilters
            )
            let data = try await httpClient.query(connection: connection, token: token, influxQl: query)
            let points = try InfluxResponseParser.parseMultiValues(data: data, fields: fields)
            for variable in group.variables {
                guard let point = points[variable.field] else {
                    throw FormulaError.missingVariable(variable.name)
                }
                latest[variable.name] = point.value
            }
        }
        return try evaluateItem(widget: widget, item: item, latest: latest)
    }

    /// Evaluates a row formula from already resolved variable values.
    public static func evaluateItem(
        widget: WidgetDefinition,
        item: SensorQueryItem,
        latest: [String: Double]
    ) throws -> Double {
        let raw = try FormulaEvaluator.evaluate(item.formula ?? "", variables: latest, steps: item.formulaSteps ?? [])
        return round(raw, widget: rowWidgetDefinition(widget: widget, item: item))
    }

    private static func rowWidgetDefinition(widget: WidgetDefinition, item: SensorQueryItem) -> WidgetDefinition {
        WidgetDefinition(
            id: widget.id,
            type: widget.type,
            title: widget.title,
            connectionId: widget.connectionId,
            measurement: widget.measurement,
            tagFilters: widget.tagFilters,
            decimalPlaces: item.decimalPlaces ?? widget.decimalPlaces,
            formula: item.formula,
            formulaVariables: item.formulaVariables,
            formulaSteps: item.formulaSteps
        )
    }

    public static func aggregate(_ result: SeriesResult, widget: WidgetDefinition) -> [String: Double] {
        let values = result.points.map { $0.value }
        guard let minValue = values.min(), let maxValue = values.max() else { return [:] }
        let mean = values.reduce(0, +) / Double(values.count)
        return ["min": minValue, "max": maxValue, "mean": round(mean, widget: widget)]
    }

    /// Short German summary of failed buckets, or nil if all buckets succeeded.
    public static func summarizeErrors(_ errors: [BucketError]) -> String? {
        guard let first = errors.first else { return nil }
        let message = first.error.errorDescription ?? "Fehler"
        if errors.count == 1 {
            return "1 Zeit-Bucket nicht berechenbar: \(message)"
        }
        return "\(errors.count) Zeit-Buckets nicht berechenbar: \(message)"
    }

    private static func groupVariables(_ widget: WidgetDefinition) -> [VariableGroup] {
        func tagsKey(_ tags: [String: String]?) -> String {
            guard let tags = tags else { return "" }
            return tags.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        }

        var order: [String] = []
        var groups: [String: VariableGroup] = [:]
        for variable in widget.formulaVariables ?? [] {
            let measurement = variable.measurement ?? widget.measurement
            let tags = variable.tagFilters ?? widget.tagFilters
            let key = "\(measurement)||\(tagsKey(tags))"
            if groups[key] == nil {
                groups[key] = VariableGroup(measurement: measurement, tagFilters: tags, variables: [])
                order.append(key)
            }
            groups[key]?.variables.append(variable)
        }
        return order.compactMap { groups[$0] }
    }

    /// Rounds half away from zero to at most 2 decimals, like the Dart `NumberFormatter`.
    private static func round(_ value: Double, widget: WidgetDefinition) -> Double {
        let decimals = min(max(widget.decimalPlaces ?? 2, 0), 2)
        let factor = Foundation.pow(10.0, Double(decimals))
        return (value * factor).rounded(.toNearestOrAwayFromZero) / factor
    }
}
