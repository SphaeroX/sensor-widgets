import Foundation

public enum InfluxQlBuilder {
    public static func escapeIdentifier(_ identifier: String) -> String {
        identifier.replacingOccurrences(of: "\"", with: "\\\"")
    }

    public static func escapeLiteral(_ literal: String) -> String {
        literal.replacingOccurrences(of: "'", with: "\\'")
    }

    private static func buildTagFilterClause(_ tagFilters: [String: String]?) -> String {
        guard let tagFilters = tagFilters, !tagFilters.isEmpty else { return "" }
        let sortedKeys = tagFilters.keys.sorted()
        return sortedKeys.map { key in
            let escapedKey = escapeIdentifier(key)
            let escapedVal = escapeLiteral(tagFilters[key] ?? "")
            return "\"\(escapedKey)\" = '\(escapedVal)'"
        }.joined(separator: " AND ")
    }

    public static func buildSingleValueQuery(
        measurement: String,
        field: String,
        tagFilters: [String: String]? = nil
    ) -> String {
        let m = escapeIdentifier(measurement)
        let f = escapeIdentifier(field)
        let tagClause = buildTagFilterClause(tagFilters)
        if tagClause.isEmpty {
            return "SELECT \"\(f)\" FROM \"\(m)\" ORDER BY time DESC LIMIT 1"
        } else {
            return "SELECT \"\(f)\" FROM \"\(m)\" WHERE \(tagClause) ORDER BY time DESC LIMIT 1"
        }
    }

    public static func buildHistoryQuery(
        measurement: String,
        field: String,
        timeRange: String,
        bucketInterval: String,
        tagFilters: [String: String]? = nil
    ) -> String {
        let m = escapeIdentifier(measurement)
        let f = escapeIdentifier(field)
        let tagClause = buildTagFilterClause(tagFilters)
        let whereClause = tagClause.isEmpty
            ? "time > now() - \(timeRange)"
            : "time > now() - \(timeRange) AND \(tagClause)"
        return "SELECT MEAN(\"\(f)\") AS \"mean\" FROM \"\(m)\" WHERE \(whereClause) GROUP BY time(\(bucketInterval)) fill(none)"
    }

    public static func buildAggregateQuery(
        measurement: String,
        field: String,
        timeRange: String,
        tagFilters: [String: String]? = nil
    ) -> String {
        let m = escapeIdentifier(measurement)
        let f = escapeIdentifier(field)
        let tagClause = buildTagFilterClause(tagFilters)
        let whereClause = tagClause.isEmpty
            ? "time > now() - \(timeRange)"
            : "time > now() - \(timeRange) AND \(tagClause)"
        return "SELECT MIN(\"\(f)\") AS \"min\", MAX(\"\(f)\") AS \"max\", MEAN(\"\(f)\") AS \"mean\" FROM \"\(m)\" WHERE \(whereClause)"
    }

    public static func buildMultiValueQuery(
        measurement: String,
        fields: [String],
        tagFilters: [String: String]? = nil
    ) -> String {
        let m = escapeIdentifier(measurement)
        let escapedFields = fields.map { "\"\(escapeIdentifier($0))\"" }.joined(separator: ", ")
        let tagClause = buildTagFilterClause(tagFilters)
        if tagClause.isEmpty {
            return "SELECT \(escapedFields) FROM \"\(m)\" ORDER BY time DESC LIMIT 1"
        } else {
            return "SELECT \(escapedFields) FROM \"\(m)\" WHERE \(tagClause) ORDER BY time DESC LIMIT 1"
        }
    }

    public static func buildShowMeasurementsQuery() -> String {
        "SHOW MEASUREMENTS"
    }

    public static func buildShowFieldKeysQuery(measurement: String) -> String {
        "SHOW FIELD KEYS FROM \"\(escapeIdentifier(measurement))\""
    }

    public static func buildShowTagKeysQuery(measurement: String) -> String {
        "SHOW TAG KEYS FROM \"\(escapeIdentifier(measurement))\""
    }

    public static func buildShowTagValuesQuery(measurement: String, tagKey: String) -> String {
        "SHOW TAG VALUES FROM \"\(escapeIdentifier(measurement))\" WITH KEY = \"\(escapeIdentifier(tagKey))\""
    }
}
