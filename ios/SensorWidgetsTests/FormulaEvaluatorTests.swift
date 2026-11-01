import Foundation
import XCTest
#if canImport(SensorWidgetsCore)
@testable import SensorWidgetsCore
#endif

final class FormulaEvaluatorTests: XCTestCase {

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

    func testValidCasesFromFixture() throws {
        let data = loadFixture(named: "evaluator_cases.json", subdirectory: "formula")
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let validCases = json["valid_cases"] as? [[String: Any]] else {
            XCTFail("Invalid fixture structure")
            return
        }

        for testCase in validCases {
            guard let name = testCase["name"] as? String,
                  let formula = testCase["formula"] as? String,
                  let varsDict = testCase["variables"] as? [String: Double],
                  let expected = testCase["expected"] as? Double else {
                XCTFail("Malformed test case in fixture")
                continue
            }

            let result = try FormulaEvaluator.evaluate(formula, variables: varsDict)
            XCTAssertEqual(result, expected, accuracy: 0.0001, "Failed on case: \(name)")
        }
    }

    func testExtractVariables() {
        let vars = FormulaEvaluator.extractVariables("(A + B * 2) / C - temp_out")
        XCTAssertEqual(vars, ["A", "B", "C", "temp_out"])
    }

    func testValidateSyntax() {
        XCTAssertNil(FormulaEvaluator.validateSyntax("A + B"))
        XCTAssertNil(FormulaEvaluator.validateSyntax("(A + B) / 3"))
        XCTAssertNotNil(FormulaEvaluator.validateSyntax("A +"))
        XCTAssertNotNil(FormulaEvaluator.validateSyntax("(A + B"))
        XCTAssertNotNil(FormulaEvaluator.validateSyntax(""))
    }

    func testDivisionByZeroThrows() {
        XCTAssertThrowsError(try FormulaEvaluator.evaluate("A / B", variables: ["A": 10.0, "B": 0.0])) { error in
            XCTAssertEqual(error as? FormulaError, FormulaError.divisionByZero)
        }
    }

    func testSyntaxErrorThrows() {
        XCTAssertThrowsError(try FormulaEvaluator.evaluate("(A + B", variables: ["A": 1.0, "B": 2.0]))
        XCTAssertThrowsError(try FormulaEvaluator.evaluate("A ++ B", variables: ["A": 1.0, "B": 2.0]))
    }

    func testMissingVariableThrows() {
        XCTAssertThrowsError(try FormulaEvaluator.evaluate("A + B", variables: ["A": 1.0])) { error in
            XCTAssertEqual(error as? FormulaError, FormulaError.missingVariable("B"))
        }
    }
}
