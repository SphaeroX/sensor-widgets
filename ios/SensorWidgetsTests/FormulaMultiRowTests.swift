import Foundation
import XCTest
#if canImport(SensorWidgetsCore)
@testable import SensorWidgetsCore
#endif

/// Multi-value row formulas (Task_26). CI only.
final class FormulaMultiRowTests: XCTestCase {

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

    func testDecodesItemFormulasFromFixture() throws {
        let data = loadFixture(named: "widget_definition_multi_formula.json", subdirectory: "widget_definitions")
        let envelope = try JSONDecoder().decode(WidgetDefinitionsEnvelope.self, from: data)
        let items = try XCTUnwrap(envelope.widgets.first?.items)
        XCTAssertEqual(items.count, 2)
        XCTAssertNil(items[0].formula)
        XCTAssertEqual(items[1].formula, "min(vocIdx, 100)")
        XCTAssertEqual(items[1].formulaVariables, [FormulaVariable(name: "v", field: "voc")])
        XCTAssertEqual(items[1].formulaSteps, [FormulaStep(name: "vocIdx", expression: "100 - v * 0.6")])
    }

    func testOldItemsDecodeWithoutFormula() throws {
        let data = loadFixture(named: "widget_definitions_v1.json", subdirectory: "widget_definitions")
        let envelope = try JSONDecoder().decode(WidgetDefinitionsEnvelope.self, from: data)
        let items = envelope.widgets.compactMap { $0.items }.flatMap { $0 }
        XCTAssertFalse(items.isEmpty)
        XCTAssertTrue(items.allSatisfy { $0.formula == nil && $0.formulaVariables == nil })
    }

    func testHasFormulaFlag() {
        XCTAssertFalse(SensorQueryItem(field: "temp").hasFormula)
        XCTAssertFalse(SensorQueryItem(field: "x", formula: "  ").hasFormula)
        XCTAssertTrue(SensorQueryItem(field: "x", formula: "a").hasFormula)
    }

    func testEvaluateItemFormulaFromLatestValues() throws {
        let item = SensorQueryItem(
            field: "iaq",
            formula: "min(vocIdx, 100)",
            formulaVariables: [FormulaVariable(name: "v", field: "voc")],
            formulaSteps: [FormulaStep(name: "vocIdx", expression: "100 - v * 0.6")]
        )
        let widget = WidgetDefinition(
            id: "w", type: .multiValue, title: "Room", connectionId: "c", measurement: "room", items: [item]
        )
        let value = try FormulaSeriesCalculator.evaluateItem(widget: widget, item: item, latest: ["v": 50.0])
        XCTAssertEqual(value, 70.0, accuracy: 1e-9)
    }

    func testItemDivisionByZeroThrows() {
        let item = SensorQueryItem(
            field: "ratio",
            formula: "1 / z",
            formulaVariables: [FormulaVariable(name: "z", field: "zero")]
        )
        let widget = WidgetDefinition(
            id: "w", type: .multiValue, title: "Room", connectionId: "c", measurement: "room", items: [item]
        )
        XCTAssertThrowsError(try FormulaSeriesCalculator.evaluateItem(widget: widget, item: item, latest: ["z": 0.0])) { error in
            XCTAssertEqual(error as? FormulaError, FormulaError.divisionByZero)
        }
    }
}
