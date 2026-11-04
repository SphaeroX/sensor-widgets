import Foundation
import XCTest

@testable import SensorWidgetsCore

final class WidgetTextsTests: XCTestCase {
    override func tearDown() {
        WidgetTexts.current = WidgetTexts.forLanguages(Locale.preferredLanguages)
        super.tearDown()
    }

    func testDeviceLanguagePicksTable() {
        XCTAssertEqual(WidgetTexts.forLanguages(["de-DE"]).language, "de")
        XCTAssertEqual(WidgetTexts.forLanguages(["de-AT"]).language, "de")
        XCTAssertEqual(WidgetTexts.forLanguages(["en-GB"]).language, "en")
    }

    func testUnsupportedLanguageFallsBackToEnglish() {
        XCTAssertEqual(WidgetTexts.forLanguages(["hi-IN"]).language, "en")
        XCTAssertEqual(WidgetTexts.forLanguages([]).language, "en")
    }

    func testLaterSupportedLanguageWins() {
        XCTAssertEqual(WidgetTexts.forLanguages(["hi-IN", "de-DE"]).language, "de")
    }

    func testEveryKeyHasEnglishAndGermanText() {
        for key in WidgetTexts.Key.allCases {
            XCTAssertNotNil(WidgetTexts.english.table[key], "english \(key)")
            XCTAssertNotNil(WidgetTexts.german.table[key], "german \(key)")
        }
    }

    func testFormulaErrorsFollowCurrentLanguage() {
        WidgetTexts.current = .english
        XCTAssertEqual(FormulaError.divisionByZero.errorDescription, "Division by zero")
        XCTAssertTrue(FormulaEvaluator.validateSyntax("min()")?.contains("at least 1") ?? false)
        WidgetTexts.current = .german
        XCTAssertEqual(FormulaError.divisionByZero.errorDescription, "Division durch Null")
        XCTAssertTrue(FormulaEvaluator.validateSyntax("min()")?.contains("mindestens 1") ?? false)
    }

    func testAlertBodyIsEnglish() {
        WidgetTexts.current = .english
        let widget = WidgetDefinition(
            id: "w", type: .multiValue, title: "sen66", connectionId: "c", measurement: "m",
            items: [SensorQueryItem(field: "temp", label: "Temperature", unit: "°C", decimalPlaces: 1)]
        )
        let hit = AlertHit(rule: AlertRule(target: "temp", operator: .lessThan, value: 18.5), actualValue: 17.24)
        XCTAssertEqual(AlertMessage.body(widget, hit), "Temperature: 17.2 °C (below 18.5 °C)")
    }

    func testBucketSummaryCountsInEnglish() {
        WidgetTexts.current = .english
        XCTAssertEqual(
            WidgetTexts.current.text(.bucketErrors, 3, "x"),
            "3 time buckets could not be calculated: x"
        )
    }
}
