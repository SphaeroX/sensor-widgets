import Foundation
import XCTest
#if canImport(SensorWidgetsCore)
@testable import SensorWidgetsCore
#endif

/// Time-bucket formula pipeline (Task_25), mirrors the Dart and Kotlin tests. CI only.
final class FormulaSeriesTests: XCTestCase {

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
        XCTFail("Could not locate fixture \(name) in \(subdirectory)")
        return Data()
    }

    private func iaq(gapPolicy: String? = nil) -> WidgetDefinition {
        WidgetDefinition(
            id: "w",
            type: .historyChart,
            title: "IAQ",
            connectionId: "c",
            measurement: "sen66",
            formula: "min(vocIdx, co2Idx)",
            formulaVariables: [
                FormulaVariable(name: "v", field: "voc"),
                FormulaVariable(name: "c", field: "co2")
            ],
            formulaSteps: [
                FormulaStep(name: "vocIdx", expression: "100 - v * 0.6"),
                FormulaStep(name: "co2Idx", expression: "clamp(100 - (c - 400) / 10, 0, 100)")
            ],
            gapPolicy: gapPolicy
        )
    }

    private func ratio() -> WidgetDefinition {
        WidgetDefinition(
            id: "w",
            type: .historyChart,
            title: "ratio",
            connectionId: "c",
            measurement: "m",
            formula: "a / b",
            formulaVariables: [
                FormulaVariable(name: "a", field: "a"),
                FormulaVariable(name: "b", field: "b")
            ]
        )
    }

    private let byVariable: [String: [Int64: Double]] = [
        "v": [2000: 100.0, 3000: 50.0, 4000: 0.0],
        "c": [1000: 800.0, 2000: 900.0, 4000: 400.0]
    ]

    func testBuilderCreatesBucketedMultiFieldQuery() {
        let query = InfluxQlBuilder.buildBucketedMultiFieldQuery(
            measurement: "sen66",
            fields: ["voc", "co2"],
            timeRange: "24h",
            bucketInterval: "1h"
        )
        XCTAssertEqual(
            query,
            "SELECT MEAN(\"voc\") AS \"voc\", MEAN(\"co2\") AS \"co2\" FROM \"sen66\" "
                + "WHERE time > now() - 24h GROUP BY time(1h) fill(null)"
        )
    }

    func testBuilderAddsSortedTagFilters() {
        let query = InfluxQlBuilder.buildBucketedMultiFieldQuery(
            measurement: "m",
            fields: ["a"],
            timeRange: "6h",
            bucketInterval: "10m",
            tagFilters: ["room": "kitchen", "floor": "1"]
        )
        XCTAssertEqual(
            query,
            "SELECT MEAN(\"a\") AS \"a\" FROM \"m\" WHERE time > now() - 6h AND "
                + "\"floor\" = '1' AND \"room\" = 'kitchen' GROUP BY time(10m) fill(null)"
        )
    }

    func testParserMapsFieldsToNonNullBuckets() throws {
        let data = loadFixture(named: "bucketed_multi_field_response.json", subdirectory: "influx")
        let result = try InfluxResponseParser.parseBucketedFields(data: data, fields: ["voc", "co2"])
        XCTAssertEqual(result["voc"], [2000: 100.0, 3000: 50.0, 4000: 0.0])
        XCTAssertEqual(result["co2"], [1000: 800.0, 2000: 900.0, 4000: 400.0])
    }

    func testDurationUtils() {
        XCTAssertEqual(DurationUtils.parseSeconds("30m"), 1800)
        XCTAssertEqual(DurationUtils.parseSeconds("1w"), 604800)
        XCTAssertNil(DurationUtils.parseSeconds("abc"))
        XCTAssertEqual(DurationUtils.effectiveBucketInterval(timeRange: "24h", requested: "1h"), "1h")
        XCTAssertEqual(DurationUtils.effectiveBucketInterval(timeRange: "garbage", requested: nil), "1h")
        let coarse = DurationUtils.effectiveBucketInterval(timeRange: "7d", requested: "1m")
        XCTAssertLessThanOrEqual(604800.0 / Double(DurationUtils.parseSeconds(coarse) ?? 1), 300)
        let derived = DurationUtils.effectiveBucketInterval(timeRange: "24h", requested: nil)
        let buckets = 86400.0 / Double(DurationUtils.parseSeconds(derived) ?? 1)
        XCTAssertLessThanOrEqual(buckets, 60)
        XCTAssertGreaterThan(buckets, 5)
    }

    func testSkipPolicyDropsIncompleteBuckets() throws {
        let result = try FormulaSeriesCalculator.combine(widget: iaq(), byVariable: byVariable)
        XCTAssertEqual(result.points.map { $0.value }, [40.0, 100.0])
        XCTAssertTrue(result.errors.isEmpty)
    }

    func testPreviousPolicyCarriesLastValueForward() throws {
        let result = try FormulaSeriesCalculator.combine(widget: iaq(gapPolicy: "previous"), byVariable: byVariable)
        XCTAssertEqual(result.points.map { $0.value }, [40.0, 50.0, 100.0])
    }

    func testRecordsPerBucketErrorsAndKeepsGoodBuckets() throws {
        let result = try FormulaSeriesCalculator.combine(
            widget: ratio(),
            byVariable: [
                "a": [1000: 10.0, 2000: 10.0, 3000: 9.0],
                "b": [1000: 2.0, 2000: 0.0, 3000: 3.0]
            ]
        )
        XCTAssertEqual(result.points.map { $0.value }, [5.0, 3.0])
        XCTAssertEqual(result.errors.count, 1)
        XCTAssertEqual(result.errors.first?.error, FormulaError.divisionByZero)
    }

    func testThrowsWhenEveryBucketFails() {
        XCTAssertThrowsError(
            try FormulaSeriesCalculator.combine(
                widget: ratio(),
                byVariable: ["a": [1000: 10.0], "b": [1000: 0.0]]
            )
        ) { error in
            XCTAssertEqual(error as? FormulaError, FormulaError.divisionByZero)
        }
    }

    func testThrowsMissingVariableWhenVariableHasNoData() {
        XCTAssertThrowsError(
            try FormulaSeriesCalculator.combine(
                widget: ratio(),
                byVariable: ["a": [1000: 10.0], "b": [:]]
            )
        ) { error in
            XCTAssertEqual(error as? FormulaError, FormulaError.missingVariable("b"))
        }
    }

    func testAggregateAppliesFormulaBeforeMinMaxMean() throws {
        let series = try FormulaSeriesCalculator.combine(widget: iaq(), byVariable: byVariable)
        let agg = FormulaSeriesCalculator.aggregate(series, widget: iaq())
        XCTAssertEqual(agg["min"] ?? -1, 40.0, accuracy: 1e-9)
        XCTAssertEqual(agg["max"] ?? -1, 100.0, accuracy: 1e-9)
        XCTAssertEqual(agg["mean"] ?? -1, 70.0, accuracy: 1e-9)
    }

    func testSummarizeErrors() {
        XCTAssertNil(FormulaSeriesCalculator.summarizeErrors([]))
        let one = FormulaSeriesCalculator.BucketError(timestamp: 1, error: .divisionByZero)
        XCTAssertEqual(
            FormulaSeriesCalculator.summarizeErrors([one]),
            "1 Zeit-Bucket nicht berechenbar: Division durch Null"
        )
    }

    func testGapPolicyDecoding() throws {
        let json = """
        {"id":"w","type":"history_chart","title":"t","connectionId":"c","measurement":"m","gapPolicy":"previous"}
        """.data(using: .utf8)!
        let widget = try JSONDecoder().decode(WidgetDefinition.self, from: json)
        XCTAssertEqual(widget.gapPolicy, "previous")
    }
}
