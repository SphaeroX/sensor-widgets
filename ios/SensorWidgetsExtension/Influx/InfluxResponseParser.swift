import Foundation

public enum InfluxResponseParser {
    private static func toDouble(_ value: Any?) -> Double? {
        if let num = value as? NSNumber {
            return num.doubleValue
        } else if let str = value as? String, let d = Double(str) {
            return d
        }
        return nil
    }

    private static func toDate(_ value: Any?) -> Date {
        if let num = value as? NSNumber {
            return Date(timeIntervalSince1970: num.doubleValue / 1000.0)
        }
        return Date()
    }

    private static func checkErrors(_ dict: [String: Any]) throws {
        if let error = dict["error"] as? String {
            throw InfluxError.queryError(error)
        }
        if let results = dict["results"] as? [[String: Any]], let first = results.first {
            if let error = first["error"] as? String {
                throw InfluxError.queryError(error)
            }
        }
    }

    private static func extractSeries(_ dict: [String: Any]) throws -> [[String: Any]]? {
        try checkErrors(dict)
        guard let results = dict["results"] as? [[String: Any]], !results.isEmpty else {
            return nil
        }
        return results[0]["series"] as? [[String: Any]]
    }

    private static func deserializeJson(_ data: Data) throws -> [String: Any] {
        guard let obj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw InfluxError.queryError("Failed to parse JSON dictionary")
        }
        return obj
    }

    // MARK: - Single Value

    public static func parseSingleValue(data: Data, fieldName: String) throws -> SensorDataPoint? {
        let dict = try deserializeJson(data)
        return try parseSingleValue(dict: dict, fieldName: fieldName)
    }

    public static func parseSingleValue(dict: [String: Any], fieldName: String) throws -> SensorDataPoint? {
        guard let seriesArr = try extractSeries(dict), !seriesArr.isEmpty else { return nil }
        let series = seriesArr[0]
        guard let columns = series["columns"] as? [String],
              let values = series["values"] as? [[Any]],
              !values.isEmpty else { return nil }

        let firstRow = values[0]
        var timeIdx = -1
        var fieldIdx = -1

        for (i, col) in columns.enumerated() {
            if col == "time" { timeIdx = i }
            if col == fieldName { fieldIdx = i }
        }

        if fieldIdx == -1 {
            if columns.count == 2 && timeIdx != -1 {
                fieldIdx = (timeIdx == 0) ? 1 : 0
            } else {
                return nil
            }
        }

        guard fieldIdx < firstRow.count, let val = toDouble(firstRow[fieldIdx]) else {
            return nil
        }

        let timestamp: Date
        if timeIdx != -1 && timeIdx < firstRow.count {
            timestamp = toDate(firstRow[timeIdx])
        } else {
            timestamp = Date()
        }

        return SensorDataPoint(timestamp: timestamp, value: val, field: fieldName)
    }

    // MARK: - Time Series

    public static func parseTimeSeries(data: Data, fieldName: String) throws -> [SensorDataPoint] {
        let dict = try deserializeJson(data)
        return try parseTimeSeries(dict: dict, fieldName: fieldName)
    }

    public static func parseTimeSeries(dict: [String: Any], fieldName: String) throws -> [SensorDataPoint] {
        guard let seriesArr = try extractSeries(dict), !seriesArr.isEmpty else { return [] }
        let series = seriesArr[0]
        guard let columns = series["columns"] as? [String],
              let values = series["values"] as? [[Any]] else { return [] }

        var timeIdx = -1
        var fieldIdx = -1

        for (i, col) in columns.enumerated() {
            if col == "time" { timeIdx = i }
            if col == fieldName { fieldIdx = i }
        }

        if fieldIdx == -1 {
            if columns.count == 2 && timeIdx != -1 {
                fieldIdx = (timeIdx == 0) ? 1 : 0
            } else {
                return []
            }
        }

        var points: [SensorDataPoint] = []
        for row in values {
            guard fieldIdx < row.count, let val = toDouble(row[fieldIdx]) else { continue }
            let timestamp = (timeIdx != -1 && timeIdx < row.count) ? toDate(row[timeIdx]) : Date(timeIntervalSince1970: 0)
            points.append(SensorDataPoint(timestamp: timestamp, value: val, field: fieldName))
        }
        return points
    }

    // MARK: - Bucketed fields

    public static func parseBucketedFields(data: Data, fields: [String]) throws -> [String: [Int64: Double]] {
        let dict = try deserializeJson(data)
        return try parseBucketedFields(dict: dict, fields: fields)
    }

    /// Parses a bucketed multi-field response into `field -> [epochMs: value]`; null buckets are omitted.
    public static func parseBucketedFields(dict: [String: Any], fields: [String]) throws -> [String: [Int64: Double]] {
        var result: [String: [Int64: Double]] = [:]
        for field in fields { result[field] = [:] }
        guard let seriesArr = try extractSeries(dict), let series = seriesArr.first,
              let columns = series["columns"] as? [String],
              let values = series["values"] as? [[Any]],
              let timeIdx = columns.firstIndex(of: "time") else { return result }

        for field in fields {
            guard let idx = columns.firstIndex(of: field) else { continue }
            for row in values {
                guard idx < row.count, timeIdx < row.count,
                      let value = toDouble(row[idx]),
                      let time = row[timeIdx] as? NSNumber else { continue }
                result[field]?[time.int64Value] = value
            }
        }
        return result
    }

    // MARK: - Multi Values

    public static func parseMultiValues(data: Data, fields: [String]) throws -> [String: SensorDataPoint] {
        let dict = try deserializeJson(data)
        return try parseMultiValues(dict: dict, fields: fields)
    }

    public static func parseMultiValues(dict: [String: Any], fields: [String]) throws -> [String: SensorDataPoint] {
        guard let seriesArr = try extractSeries(dict), !seriesArr.isEmpty else { return [:] }
        let series = seriesArr[0]
        guard let columns = series["columns"] as? [String],
              let values = series["values"] as? [[Any]],
              !values.isEmpty else { return [:] }

        let firstRow = values[0]
        var timeIdx = -1
        var colMap: [String: Int] = [:]

        for (i, col) in columns.enumerated() {
            if col == "time" { timeIdx = i }
            colMap[col] = i
        }

        let timestamp: Date = (timeIdx != -1 && timeIdx < firstRow.count) ? toDate(firstRow[timeIdx]) : Date()
        var result: [String: SensorDataPoint] = [:]

        for field in fields {
            if let idx = colMap[field], idx < firstRow.count, let val = toDouble(firstRow[idx]) {
                result[field] = SensorDataPoint(timestamp: timestamp, value: val, field: field)
            }
        }
        return result
    }

    // MARK: - Aggregate

    public static func parseAggregate(data: Data) throws -> [String: Double] {
        let dict = try deserializeJson(data)
        return try parseAggregate(dict: dict)
    }

    public static func parseAggregate(dict: [String: Any]) throws -> [String: Double] {
        guard let seriesArr = try extractSeries(dict), !seriesArr.isEmpty else { return [:] }
        let series = seriesArr[0]
        guard let columns = series["columns"] as? [String],
              let values = series["values"] as? [[Any]],
              !values.isEmpty else { return [:] }

        let firstRow = values[0]
        var map: [String: Double] = [:]

        for (i, col) in columns.enumerated() {
            let lower = col.lowercased()
            if lower == "time" { continue }
            if i < firstRow.count, let val = toDouble(firstRow[i]) {
                map[lower] = val
            }
        }
        return map
    }

    // MARK: - Metadata / Discovery

    public static func parseMeasurements(data: Data) throws -> [String] {
        let dict = try deserializeJson(data)
        return try parseMeasurements(dict: dict)
    }

    public static func parseMeasurements(dict: [String: Any]) throws -> [String] {
        guard let seriesArr = try extractSeries(dict), !seriesArr.isEmpty else { return [] }
        guard let values = seriesArr[0]["values"] as? [[Any]] else { return [] }
        return values.compactMap { row in
            guard !row.isEmpty else { return nil }
            return row[0] as? String
        }
    }

    public static func parseFieldKeys(data: Data) throws -> [String] {
        let dict = try deserializeJson(data)
        return try parseFieldKeys(dict: dict)
    }

    public static func parseFieldKeys(dict: [String: Any]) throws -> [String] {
        guard let seriesArr = try extractSeries(dict), !seriesArr.isEmpty else { return [] }
        guard let values = seriesArr[0]["values"] as? [[Any]] else { return [] }
        return values.compactMap { row in
            guard !row.isEmpty else { return nil }
            return row[0] as? String
        }
    }

    public static func parseTagKeys(data: Data) throws -> [String] {
        let dict = try deserializeJson(data)
        return try parseTagKeys(dict: dict)
    }

    public static func parseTagKeys(dict: [String: Any]) throws -> [String] {
        guard let seriesArr = try extractSeries(dict), !seriesArr.isEmpty else { return [] }
        guard let values = seriesArr[0]["values"] as? [[Any]] else { return [] }
        return values.compactMap { row in
            guard !row.isEmpty else { return nil }
            return row[0] as? String
        }
    }

    public static func parseTagValues(data: Data) throws -> [String] {
        let dict = try deserializeJson(data)
        return try parseTagValues(dict: dict)
    }

    public static func parseTagValues(dict: [String: Any]) throws -> [String] {
        guard let seriesArr = try extractSeries(dict), !seriesArr.isEmpty else { return [] }
        let series = seriesArr[0]
        guard let columns = series["columns"] as? [String],
              let values = series["values"] as? [[Any]] else { return [] }

        var valIdx = 1
        for (i, col) in columns.enumerated() where col == "value" {
            valIdx = i
            break
        }

        return values.compactMap { row in
            guard valIdx < row.count else { return nil }
            return row[valIdx] as? String
        }
    }
}
