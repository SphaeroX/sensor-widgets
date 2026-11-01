import Foundation
import XCTest
#if canImport(SensorWidgetsCore)
@testable import SensorWidgetsCore
#endif

/// Contract v2 tests, driven by `fixtures/formula/evaluator_cases.json`
/// (sections `v2_valid_cases` and `v2_error_cases`). Runs in CI only.
final class FormulaEvaluatorV2Tests: XCTestCase {

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

    private func fixtureRoot() throws -> [String: Any] {
        let data = loadFixture(named: "evaluator_cases.json", subdirectory: "formula")
        return try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func steps(of testCase: [String: Any]) -> [FormulaStep] {
        let raw = testCase["steps"] as? [[String: Any]] ?? []
        return raw.compactMap { entry in
            guard let name = entry["name"] as? String,
                  let expression = entry["expression"] as? String else { return nil }
            return FormulaStep(name: name, expression: expression)
        }
    }

    func testV2ValidCasesFromFixture() throws {
        let cases = try XCTUnwrap(try fixtureRoot()["v2_valid_cases"] as? [[String: Any]])
        XCTAssertFalse(cases.isEmpty)
        for testCase in cases {
            let name = try XCTUnwrap(testCase["name"] as? String)
            let formula = try XCTUnwrap(testCase["formula"] as? String)
            let vars = try XCTUnwrap(testCase["variables"] as? [String: Double])
            let expected = try XCTUnwrap(testCase["expected"] as? Double)
            let result = try FormulaEvaluator.evaluate(formula, variables: vars, steps: steps(of: testCase))
            XCTAssertEqual(result, expected, accuracy: 1e-9, "Failed on case: \(name)")
        }
    }

    func testV2ErrorCasesFromFixture() throws {
        let cases = try XCTUnwrap(try fixtureRoot()["v2_error_cases"] as? [[String: Any]])
        XCTAssertFalse(cases.isEmpty)
        for testCase in cases {
            let name = try XCTUnwrap(testCase["name"] as? String)
            let formula = try XCTUnwrap(testCase["formula"] as? String)
            let vars = try XCTUnwrap(testCase["variables"] as? [String: Double])
            let expectedCode = try XCTUnwrap(testCase["expected_error"] as? String)
            do {
                _ = try FormulaEvaluator.evaluate(formula, variables: vars, steps: steps(of: testCase))
                XCTFail("Expected \(expectedCode) for case \(name)")
            } catch let error as FormulaError {
                XCTAssertEqual(error.code, expectedCode, "Wrong error on case \(name): \(error)")
            }
        }
    }

    func testExtractVariablesIgnoresFunctionsAndConstants() {
        XCTAssertEqual(
            FormulaEvaluator.extractVariables("min(a, pi * b) + e + max(a, c)"),
            ["a", "b", "c"]
        )
    }

    func testValidateSyntaxReportsPosition() {
        let message = FormulaEvaluator.validateSyntax("A + * B")
        XCTAssertNotNil(message)
        XCTAssertTrue(message?.contains("Position 5") ?? false)
        XCTAssertNil(FormulaEvaluator.validateSyntax("if(A > 1, min(A, 2), 0)"))
        XCTAssertNotNil(FormulaEvaluator.validateSyntax("foo(A)"))
        XCTAssertNotNil(FormulaEvaluator.validateSyntax("sqrt(A, B)"))
    }

    func testValidateSteps() {
        XCTAssertNotNil(FormulaEvaluator.validateSteps(
            [FormulaStep(name: "s1", expression: "s2 + 1"), FormulaStep(name: "s2", expression: "a")],
            formula: "a",
            variableNames: ["a"]
        ))
        XCTAssertNil(FormulaEvaluator.validateSteps(
            [FormulaStep(name: "s1", expression: "a * 2")],
            formula: "s1",
            variableNames: ["a"]
        ))
    }

    func testParsesFormulaStepsFromWidgetFixture() throws {
        let data = loadFixture(named: "widget_definition_formula_steps.json", subdirectory: "widget_definitions")
        let envelope = try JSONDecoder().decode(WidgetDefinitionsEnvelope.self, from: data)
        let steps = try XCTUnwrap(envelope.widgets.first?.formulaSteps)
        XCTAssertEqual(steps.count, 2)
        XCTAssertEqual(steps[0], FormulaStep(name: "voc", expression: "100 - v * 0.6", label: "VOC-Index"))
    }

    func testOldDefinitionsHaveNoSteps() throws {
        let data = loadFixture(named: "widget_definitions_v1.json", subdirectory: "widget_definitions")
        let envelope = try JSONDecoder().decode(WidgetDefinitionsEnvelope.self, from: data)
        XCTAssertTrue(envelope.widgets.allSatisfy { $0.formulaSteps == nil })
    }
}
