import Foundation
import XCTest
#if canImport(SensorWidgetsCore)
@testable import SensorWidgetsCore
#endif

/// Chart style contract and value gradient (Task_30). CI only.
final class ChartStyleTests: XCTestCase {

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

    private let stops = [
        ColorStop(value: 0, color: "#FF0000"),
        ColorStop(value: 50, color: "#FFFF00"),
        ColorStop(value: 100, color: "#00FF00")
    ]

    func testInterpolationMatchesSharedFixture() throws {
        let data = loadFixture(named: "color_interpolation_cases.json", subdirectory: "chart")
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let cases = try XCTUnwrap(root["cases"] as? [[String: Any]])
        XCTAssertFalse(cases.isEmpty)
        for testCase in cases {
            let name = try XCTUnwrap(testCase["name"] as? String)
            let rawStops = try XCTUnwrap(testCase["stops"] as? [[String: Any]])
            let caseStops = rawStops.compactMap { entry -> ColorStop? in
                guard let value = entry["value"] as? Double, let color = entry["color"] as? String else { return nil }
                return ColorStop(value: value, color: color)
            }
            let value = try XCTUnwrap(testCase["value"] as? Double)
            let expected = testCase["expected"] as? String
            let actual = ChartColor.interpolate(caseStops, value: value).map { ChartColor.formatHex($0) }
            XCTAssertEqual(actual, expected, "case \(name)")
        }
    }

    func testHexParsingAndFormatting() {
        XCTAssertEqual(ChartColor.parseHex("#FF8000"), 0xFFFF8000)
        XCTAssertEqual(ChartColor.parseHex("ff8000"), 0xFFFF8000)
        XCTAssertNil(ChartColor.parseHex("#12345"))
        XCTAssertNil(ChartColor.parseHex("red"))
        XCTAssertEqual(ChartColor.formatHex(0xFF66FF00), "#66FF00")
    }

    func testGradientPositionsFollowVisibleRange() throws {
        let full = try XCTUnwrap(ChartColor.buildGradient(stops, minValue: 0, maxValue: 100))
        XCTAssertEqual(full.positions, [0.0, 0.5, 1.0])
        XCTAssertEqual(full.colors.map { ChartColor.formatHex($0) }, ["#FF0000", "#FFFF00", "#00FF00"])

        let inner = try XCTUnwrap(ChartColor.buildGradient(stops, minValue: 25, maxValue: 75))
        XCTAssertEqual(inner.positions.first, 0.0)
        XCTAssertEqual(inner.positions.last, 1.0)
        XCTAssertTrue(inner.positions.contains(0.5))
        XCTAssertEqual(inner.colors.count, inner.positions.count)
    }

    func testGradientFallbacks() throws {
        XCTAssertNil(ChartColor.buildGradient([], minValue: 0, maxValue: 10))
        XCTAssertNil(ChartColor.buildGradient([ColorStop(value: 0, color: "nope")], minValue: 0, maxValue: 10))
        let flat = try XCTUnwrap(ChartColor.buildGradient(stops, minValue: 50, maxValue: 50))
        XCTAssertEqual(Set(flat.colors).count, 1)
        XCTAssertEqual(ChartColor.formatHex(try XCTUnwrap(flat.colors.first)), "#FFFF00")
    }

    func testDecodesChartStyleFromSharedFixture() throws {
        let data = loadFixture(named: "widget_definition_chart_style.json", subdirectory: "widget_definitions")
        let envelope = try JSONDecoder().decode(WidgetDefinitionsEnvelope.self, from: data)
        let style = try XCTUnwrap(envelope.widgets.first?.chartStyle)
        XCTAssertEqual(style.colorStops.count, 3)
        XCTAssertEqual(style.colorStops[1], ColorStop(value: 50, color: "#FFFF00"))
        XCTAssertTrue(style.fillArea && style.showGrid && style.showAxes && style.markMinMax)
        XCTAssertEqual(style.lineWidth, 3.0)
        XCTAssertNil(envelope.widgets.last?.chartStyle)
    }

    func testChartStyleDefaultsWhenFieldsAreMissing() throws {
        let json = Data("""
        {"id":"w","type":"history_chart","title":"t","connectionId":"c","measurement":"m","chartStyle":{}}
        """.utf8)
        let widget = try JSONDecoder().decode(WidgetDefinition.self, from: json)
        let style = try XCTUnwrap(widget.chartStyle)
        XCTAssertTrue(style.colorStops.isEmpty)
        XCTAssertFalse(style.fillArea)
        XCTAssertEqual(style.lineWidth, ChartStyle.defaultLineWidth)
    }
}
