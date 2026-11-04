import Foundation
import XCTest
#if canImport(SensorWidgetsCore)
@testable import SensorWidgetsCore
#endif

/// Threshold push notifications (`alerts`) and the network error grace period. CI only.
final class AlertTests: XCTestCase {

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

    private func rules(_ raw: Any?) -> [AlertRule] {
        let list = raw as? [[String: Any]] ?? []
        return list.map {
            AlertRule(
                target: $0["target"] as? String ?? "",
                operator: ThresholdOperator(rawValue: $0["operator"] as? String ?? "") ?? .greaterThan,
                value: ($0["value"] as? NSNumber)?.doubleValue ?? 0
            )
        }
    }

    /// Maps the Android-style cache JSON of the fixture onto the iOS cache model.
    private func cachedData(_ raw: [String: Any]) -> CachedSensorData {
        let values = (raw["values"] as? [String: [String: Any]])?.compactMapValues { ($0["value"] as? NSNumber)?.doubleValue }
        let points = (raw["points"] as? [[String: Any]])?.map {
            SensorDataPoint(
                timestamp: Date(timeIntervalSince1970: (($0["t"] as? NSNumber)?.doubleValue ?? 0) / 1000),
                value: ($0["v"] as? NSNumber)?.doubleValue ?? 0,
                field: "v"
            )
        }
        let aggregates = (raw["aggregates"] as? [String: Any])?.compactMapValues { ($0 as? NSNumber)?.doubleValue }
        return CachedSensorData(
            singleValue: (raw["value"] as? NSNumber)?.doubleValue,
            series: points,
            multiValues: values,
            aggregate: aggregates,
            lastUpdated: Date(),
            errorMessage: raw["error"] as? String
        )
    }

    func testSharedEvaluationCases() throws {
        let data = loadFixture(named: "evaluation_cases.json", subdirectory: "alerts")
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let cases = try XCTUnwrap(root["cases"] as? [[String: Any]])
        XCTAssertFalse(cases.isEmpty)
        for testCase in cases {
            let name = testCase["name"] as? String ?? "?"
            let alerts = rules(testCase["alerts"])
            let result = AlertEvaluator.evaluate(
                rules: alerts,
                data: cachedData(testCase["cache"] as? [String: Any] ?? [:]),
                previouslyActive: rules(testCase["previouslyActive"])
            )
            let triggered = (testCase["expectTriggered"] as? [Int] ?? []).map { alerts[$0] }
            let active = (testCase["expectActive"] as? [Int] ?? []).map { alerts[$0] }
            XCTAssertEqual(result.triggered.map(\.rule), triggered, name)
            XCTAssertEqual(result.active, active, name)
        }
    }

    func testDecodesAlertsFromSharedFixture() throws {
        let data = loadFixture(named: "widget_definition_alerts.json", subdirectory: "widget_definitions")
        let widgets = try JSONDecoder().decode(WidgetDefinitionsEnvelope.self, from: data).widgets
        XCTAssertEqual(widgets[0].alerts, [AlertRule(target: AlertRule.targetValue, operator: .greaterThan, value: 150)])
        XCTAssertEqual(widgets[1].alerts?.map(\.target), ["co2", "temp"])
        XCTAssertEqual(widgets[1].alerts?[1].operator, .lessThan)
        XCTAssertNil(widgets[2].alerts)
    }

    func testAlertStateRoundTripsThroughJson() throws {
        let active = [AlertRule(target: "co2", operator: .greaterThan, value: 1000)]
        let encoded = try JSONEncoder().encode(active)
        XCTAssertEqual(try JSONDecoder().decode([AlertRule].self, from: encoded), active)
    }

    func testMessageForMultiValueRow() {
        let widget = WidgetDefinition(
            id: "w", type: .multiValue, title: "sen66", connectionId: "c", measurement: "m",
            items: [SensorQueryItem(field: "temp", label: "Temperatur", unit: "°C", decimalPlaces: 1)]
        )
        let hit = AlertHit(rule: AlertRule(target: "temp", operator: .lessThan, value: 18.5), actualValue: 17.24)
        XCTAssertEqual(AlertMessage.title(widget), "sen66")
        XCTAssertEqual(AlertMessage.body(widget, hit), "Temperatur: 17.2 °C (unter 18.5 °C)")
    }

    func testMessageForPrimaryValue() {
        let widget = WidgetDefinition(id: "w", type: .singleValue, title: "IAQ Index", connectionId: "c", measurement: "m", decimalPlaces: 0)
        let hit = AlertHit(rule: AlertRule(target: "value", operator: .greaterThan, value: 150), actualValue: 163.4)
        XCTAssertEqual(AlertMessage.body(widget, hit), "IAQ Index: 163 (über 150)")
    }

    // MARK: - Network error grace

    private let good = CachedSensorData(singleValue: 22.8, lastUpdated: Date(timeIntervalSince1970: 1000))

    func testShortNetworkOutageKeepsLastValues() {
        let since = Date(timeIntervalSince1970: 10_000)
        let shown = NetworkErrorGrace.fallback(
            cached: good, errorMessage: "Network Error", isNetworkError: true,
            failureSince: since, now: since.addingTimeInterval(30 * 60)
        )
        XCTAssertEqual(shown, good)
    }

    func testLongNetworkOutageShowsError() {
        let since = Date(timeIntervalSince1970: 10_000)
        let shown = NetworkErrorGrace.fallback(
            cached: good, errorMessage: "Network Error", isNetworkError: true,
            failureSince: since, now: since.addingTimeInterval(NetworkErrorGrace.graceInterval)
        )
        XCTAssertEqual(shown.errorMessage, "Network Error")
        XCTAssertEqual(shown.singleValue, 22.8)
    }

    func testNonNetworkErrorIsShownRightAway() {
        let now = Date()
        let shown = NetworkErrorGrace.fallback(
            cached: good, errorMessage: "Authentication Error", isNetworkError: false, failureSince: now, now: now
        )
        XCTAssertEqual(shown.errorMessage, "Authentication Error")
    }

    func testNetworkErrorWithoutCachedDataIsShown() {
        let now = Date()
        let shown = NetworkErrorGrace.fallback(
            cached: nil, errorMessage: "Network Error", isNetworkError: true, failureSince: now, now: now
        )
        XCTAssertEqual(shown.errorMessage, "Network Error")
    }

    func testGraceIsOneHour() {
        XCTAssertEqual(NetworkErrorGrace.graceInterval, 3600)
    }
}
