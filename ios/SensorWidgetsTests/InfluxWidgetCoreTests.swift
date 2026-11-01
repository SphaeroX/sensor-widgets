import Foundation
import XCTest
#if canImport(SensorWidgetsCore)
@testable import SensorWidgetsCore
#endif

final class InfluxWidgetCoreTests: XCTestCase {

    private func loadFixture(named name: String, subdirectory: String) -> Data {
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath

        let candidatePaths = [
            "fixtures/\(subdirectory)/\(name)",
            "../fixtures/\(subdirectory)/\(name)",
            "../../fixtures/\(subdirectory)/\(name)",
            "\(currentDir)/fixtures/\(subdirectory)/\(name)",
            "\(currentDir)/../fixtures/\(subdirectory)/\(name)"
        ]

        for path in candidatePaths {
            if fileManager.fileExists(atPath: path),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                return data
            }
        }

        #if SWIFT_PACKAGE
        // Check bundle module if resources are bundled
        #endif

        XCTFail("Could not locate fixture \(name) in \(subdirectory)")
        return Data()
    }

    // MARK: - 1. Widget Definitions Decoding

    func testWidgetDefinitionsDecoding() throws {
        let data = loadFixture(named: "widget_definitions_v1.json", subdirectory: "widget_definitions")
        let envelope = try JSONDecoder().decode(WidgetDefinitionsEnvelope.self, from: data)

        XCTAssertEqual(envelope.schemaVersion, 1)
        XCTAssertEqual(envelope.widgets.count, 6)

        let types = Set(envelope.widgets.map { $0.type })
        XCTAssertTrue(types.contains(.singleValue))
        XCTAssertTrue(types.contains(.historyChart))
        XCTAssertTrue(types.contains(.indicatorLamp))
        XCTAssertTrue(types.contains(.gaugeBar))
        XCTAssertTrue(types.contains(.aggregate))
        XCTAssertTrue(types.contains(.multiValue))

        let single = envelope.widgets.first { $0.type == .singleValue }
        XCTAssertNotNil(single)
        XCTAssertEqual(single?.id, "widget-1-single-value")
        XCTAssertEqual(single?.measurement, "temperature")
        XCTAssertEqual(single?.field, "value")
        XCTAssertEqual(single?.unit, "°C")
        XCTAssertEqual(single?.decimalPlaces, 1)
    }

    // MARK: - 2. InfluxQL Query Builder

    func testInfluxQlBuilderQueries() {
        let singleQ = InfluxQlBuilder.buildSingleValueQuery(
            measurement: "temperature",
            field: "temp",
            tagFilters: ["room": "living_room"]
        )
        XCTAssertEqual(singleQ, "SELECT \"temp\" FROM \"temperature\" WHERE \"room\" = 'living_room' ORDER BY time DESC LIMIT 1")

        let singleQNoTags = InfluxQlBuilder.buildSingleValueQuery(
            measurement: "temperature",
            field: "temp"
        )
        XCTAssertEqual(singleQNoTags, "SELECT \"temp\" FROM \"temperature\" ORDER BY time DESC LIMIT 1")

        let historyQ = InfluxQlBuilder.buildHistoryQuery(
            measurement: "temperature",
            field: "temp",
            timeRange: "24h",
            bucketInterval: "15m",
            tagFilters: ["room": "kitchen"]
        )
        XCTAssertEqual(
            historyQ,
            "SELECT MEAN(\"temp\") AS \"mean\" FROM \"temperature\" WHERE time > now() - 24h AND \"room\" = 'kitchen' GROUP BY time(15m) fill(none)"
        )

        let aggregateQ = InfluxQlBuilder.buildAggregateQuery(
            measurement: "temperature",
            field: "temp",
            timeRange: "24h",
            tagFilters: ["sensor": "esp32"]
        )
        XCTAssertEqual(
            aggregateQ,
            "SELECT MIN(\"temp\") AS \"min\", MAX(\"temp\") AS \"max\", MEAN(\"temp\") AS \"mean\" FROM \"temperature\" WHERE time > now() - 24h AND \"sensor\" = 'esp32'"
        )

        let multiQ = InfluxQlBuilder.buildMultiValueQuery(
            measurement: "climate",
            fields: ["temp", "humidity"],
            tagFilters: ["room": "office"]
        )
        XCTAssertEqual(
            multiQ,
            "SELECT \"temp\", \"humidity\" FROM \"climate\" WHERE \"room\" = 'office' ORDER BY time DESC LIMIT 1"
        )

        XCTAssertEqual(InfluxQlBuilder.buildShowMeasurementsQuery(), "SHOW MEASUREMENTS")
        XCTAssertEqual(InfluxQlBuilder.buildShowFieldKeysQuery(measurement: "weather"), "SHOW FIELD KEYS FROM \"weather\"")
        XCTAssertEqual(InfluxQlBuilder.buildShowTagKeysQuery(measurement: "weather"), "SHOW TAG KEYS FROM \"weather\"")
        XCTAssertEqual(
            InfluxQlBuilder.buildShowTagValuesQuery(measurement: "weather", tagKey: "city"),
            "SHOW TAG VALUES FROM \"weather\" WITH KEY = \"city\""
        )
    }

    // MARK: - 3. InfluxResponseParser Fixtures

    func testParseSingleValue() throws {
        let data = loadFixture(named: "single_value_response.json", subdirectory: "influx")
        let point = try InfluxResponseParser.parseSingleValue(data: data, fieldName: "temp")
        XCTAssertNotNil(point)
        XCTAssertEqual(point?.value, 21.5)
        XCTAssertEqual(point?.field, "temp")
    }

    func testParseTimeSeries() throws {
        let data = loadFixture(named: "history_series_response.json", subdirectory: "influx")
        let points = try InfluxResponseParser.parseTimeSeries(data: data, fieldName: "mean")
        XCTAssertEqual(points.count, 6)
        XCTAssertEqual(points.first?.value, 19.8)
        XCTAssertEqual(points.last?.value, 21.5)
    }

    func testParseAggregate() throws {
        let data = loadFixture(named: "aggregate_min_max_mean_response.json", subdirectory: "influx")
        let agg = try InfluxResponseParser.parseAggregate(data: data)
        XCTAssertEqual(agg["min"], 18.2)
        XCTAssertEqual(agg["max"], 23.9)
        XCTAssertEqual(agg["mean"], 21.1)
    }

    func testParseMultiValues() throws {
        let data = loadFixture(named: "multi_series_room_response.json", subdirectory: "influx")
        let multi = try InfluxResponseParser.parseMultiValues(data: data, fields: ["temperature", "humidity", "co2"])
        XCTAssertEqual(multi["temperature"]?.value, 22.3)
        XCTAssertEqual(multi["humidity"]?.value, 48.5)
        XCTAssertEqual(multi["co2"]?.value, 620.0)
    }

    func testParseDiscoveryMetadata() throws {
        let measurementsData = loadFixture(named: "show_measurements_response.json", subdirectory: "influx")
        let measurements = try InfluxResponseParser.parseMeasurements(data: measurementsData)
        XCTAssertTrue(measurements.contains("temperature"))

        let fieldKeysData = loadFixture(named: "show_field_keys_response.json", subdirectory: "influx")
        let fields = try InfluxResponseParser.parseFieldKeys(data: fieldKeysData)
        XCTAssertTrue(fields.contains("temperature"))

        let tagKeysData = loadFixture(named: "show_tag_keys_response.json", subdirectory: "influx")
        let tagKeys = try InfluxResponseParser.parseTagKeys(data: tagKeysData)
        XCTAssertTrue(tagKeys.contains("room"))

        let tagValuesData = loadFixture(named: "show_tag_values_response.json", subdirectory: "influx")
        let tagVals = try InfluxResponseParser.parseTagValues(data: tagValuesData)
        XCTAssertTrue(tagVals.contains("living_room"))
    }

    func testEmptyResponseHandling() throws {
        let data = loadFixture(named: "empty_result_response.json", subdirectory: "influx")
        let point = try InfluxResponseParser.parseSingleValue(data: data, fieldName: "temp")
        XCTAssertNil(point)

        let points = try InfluxResponseParser.parseTimeSeries(data: data, fieldName: "temp")
        XCTAssertTrue(points.isEmpty)

        let agg = try InfluxResponseParser.parseAggregate(data: data)
        XCTAssertTrue(agg.isEmpty)
    }

    func testErrorResponseHandling() throws {
        let data = loadFixture(named: "error_query_response.json", subdirectory: "influx")
        XCTAssertThrowsError(try InfluxResponseParser.parseSingleValue(data: data, fieldName: "temp")) { error in
            guard case InfluxError.queryError(let msg) = error else {
                XCTFail("Expected InfluxError.queryError, got \(error)")
                return
            }
            XCTAssertTrue(msg.contains("syntax error") || msg.contains("parsing error") || !msg.isEmpty)
        }
    }

    // MARK: - 4. Threshold Evaluation

    func testThresholdEvaluation() {
        let greater = ThresholdRule(operator: .greaterThan, value: 25.0)
        XCTAssertTrue(greater.matches(25.1))
        XCTAssertFalse(greater.matches(25.0))
        XCTAssertFalse(greater.matches(24.9))

        let lesser = ThresholdRule(operator: .lessThan, value: 10.0)
        XCTAssertTrue(lesser.matches(9.9))
        XCTAssertFalse(lesser.matches(10.0))
        XCTAssertFalse(lesser.matches(10.1))
    }

    // MARK: - 5. Token Masking

    func testTokenMasking() {
        let secret = "super-secret-influx-token-abc"
        let msg = "Failed authorization for Token \(secret) at http://localhost:8086"
        let sanitized = InfluxHttpClient.maskToken(msg, token: secret)
        XCTAssertFalse(sanitized.contains(secret))
        XCTAssertTrue(sanitized.contains("***"))
    }
}
