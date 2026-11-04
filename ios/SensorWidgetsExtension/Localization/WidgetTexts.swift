import Foundation

/// Texts of the native widgets in the device language; English is the fallback.
///
/// Each language is one table in this file (`english`, `german`). The widget
/// extension is built as a Swift package without resources, so the tables live
/// in code instead of `Localizable.strings`. A new language adds a table and an
/// entry in `byLanguage`; missing keys fall back to English.
public struct WidgetTexts {
    public enum Key: String, CaseIterable {
        case noData
        case selectWidget
        case longPressToConfigure
        case rowError
        case alertAbove
        case alertBelow
        case alertTargetMin
        case alertTargetMax
        case alertTargetMean
        case alertBody
        case bucketErrorOne
        case bucketErrors
        case genericError
        case formulaError
        case invalidFormula
        case formulaEmpty
        case syntaxError
        case divisionByZero
        case missingVariable
        case unknownFunction
        case wrongArity
        case arityAtLeast
        case arityRange
        case invalidStepName
        case stepNameIsFunction
        case duplicateName
        case stepSelfReference
        case stepForwardReference
        case unexpectedAssign
        case unexpectedCharacter
        case invalidNumber
        case missingOpeningParen
        case missingOperator
        case incompleteExpression
        case unclosedParen
        case unknownOperator
        case notFinite
        case resultNotFinite
        case clampBounds
        case sqrtNegative
        case lnNonPositive
        case log10NonPositive
        case noFormula
    }

    /// Language code of the table, e.g. "en".
    public let language: String
    let table: [Key: String]

    /// Texts for the device language. Tests may replace it.
    public static var current = WidgetTexts.forLanguages(Locale.preferredLanguages)

    /// The first of [languages] (BCP 47, e.g. "de-AT") that has a table, else English.
    public static func forLanguages(_ languages: [String]) -> WidgetTexts {
        for identifier in languages {
            let code = String(identifier.prefix { $0 != "-" && $0 != "_" }).lowercased()
            if let texts = byLanguage[code] { return texts }
        }
        return english
    }

    /// The text for [key] with `String(format:)` arguments (`%@` for strings).
    public func text(_ key: Key, _ args: CVarArg...) -> String {
        let pattern = table[key] ?? WidgetTexts.english.table[key] ?? key.rawValue
        return args.isEmpty ? pattern : String(format: pattern, locale: Locale(identifier: "en_US_POSIX"), arguments: args)
    }

    static let byLanguage: [String: WidgetTexts] = ["en": english, "de": german]

    public static let english = WidgetTexts(language: "en", table: [
        .noData: "No data available",
        .selectWidget: "Select Widget",
        .longPressToConfigure: "Long press to configure",
        .rowError: "Error: %@",
        .alertAbove: "above",
        .alertBelow: "below",
        .alertTargetMin: "Minimum",
        .alertTargetMax: "Maximum",
        .alertTargetMean: "Average",
        .alertBody: "%@: %@%@ (%@ %@%@)",
        .bucketErrorOne: "1 time bucket could not be calculated: %@",
        .bucketErrors: "%ld time buckets could not be calculated: %@",
        .genericError: "Error",
        .formulaError: "Formula error",
        .invalidFormula: "Invalid formula",
        .formulaEmpty: "Formula must not be empty",
        .syntaxError: "Syntax error: %@",
        .divisionByZero: "Division by zero",
        .missingVariable: "Missing variable: %@",
        .unknownFunction: "Unknown function: %@",
        .wrongArity: "Function %@ expects %@ argument(s), got: %ld",
        .arityAtLeast: "at least %ld",
        .arityRange: "%ld to %ld",
        .invalidStepName: "Invalid step name: \"%@\"",
        .stepNameIsFunction: "Step name \"%@\" is a function name",
        .duplicateName: "Duplicate name: \"%@\"",
        .stepSelfReference: "Step \"%@\" refers to itself",
        .stepForwardReference: "Step refers to a later step \"%@\"",
        .unexpectedAssign: "Unexpected character: \"=\" (comparison: \"==\")",
        .unexpectedCharacter: "Unexpected character: \"%@\"",
        .invalidNumber: "Invalid number: %@",
        .missingOpeningParen: "Missing opening parenthesis",
        .missingOperator: "Missing operator between operands",
        .incompleteExpression: "Incomplete expression",
        .unclosedParen: "Unclosed parenthesis",
        .unknownOperator: "Unknown operator",
        .notFinite: "%@: result is not finite",
        .resultNotFinite: "Result is not finite",
        .clampBounds: "clamp: lower bound greater than upper bound",
        .sqrtNegative: "sqrt: argument must not be negative",
        .lnNonPositive: "ln: argument must be greater than 0",
        .log10NonPositive: "log10: argument must be greater than 0",
        .noFormula: "Widget has no formula"
    ])

    public static let german = WidgetTexts(language: "de", table: [
        .noData: "Keine Daten verfügbar",
        .selectWidget: "Widget auswählen",
        .longPressToConfigure: "Lange drücken zum Einrichten",
        .rowError: "Fehler: %@",
        .alertAbove: "über",
        .alertBelow: "unter",
        .alertTargetMin: "Minimum",
        .alertTargetMax: "Maximum",
        .alertTargetMean: "Mittelwert",
        .alertBody: "%@: %@%@ (%@ %@%@)",
        .bucketErrorOne: "1 Zeit-Bucket nicht berechenbar: %@",
        .bucketErrors: "%ld Zeit-Buckets nicht berechenbar: %@",
        .genericError: "Fehler",
        .formulaError: "Formelfehler",
        .invalidFormula: "Ungültige Formel",
        .formulaEmpty: "Formel darf nicht leer sein",
        .syntaxError: "Syntaxfehler: %@",
        .divisionByZero: "Division durch Null",
        .missingVariable: "Fehlende Variable: %@",
        .unknownFunction: "Unbekannte Funktion: %@",
        .wrongArity: "Funktion %@ erwartet %@ Argument(e), erhalten: %ld",
        .arityAtLeast: "mindestens %ld",
        .arityRange: "%ld bis %ld",
        .invalidStepName: "Ungültiger Schrittname: \"%@\"",
        .stepNameIsFunction: "Schrittname \"%@\" ist ein Funktionsname",
        .duplicateName: "Doppelter Name: \"%@\"",
        .stepSelfReference: "Schritt \"%@\" verweist auf sich selbst",
        .stepForwardReference: "Schritt verweist auf später definierten Schritt \"%@\"",
        .unexpectedAssign: "Unerwartetes Zeichen: \"=\" (Vergleich: \"==\")",
        .unexpectedCharacter: "Unerwartetes Zeichen: \"%@\"",
        .invalidNumber: "Ungültige Zahl: %@",
        .missingOpeningParen: "Fehlende öffnende Klammer",
        .missingOperator: "Fehlender Operator zwischen Operanden",
        .incompleteExpression: "Ausdruck unvollständig",
        .unclosedParen: "Nicht geschlossene Klammer",
        .unknownOperator: "Unbekannter Operator",
        .notFinite: "%@: Ergebnis ist nicht endlich",
        .resultNotFinite: "Ergebnis ist nicht endlich",
        .clampBounds: "clamp: untere Grenze größer als obere Grenze",
        .sqrtNegative: "sqrt: Argument darf nicht negativ sein",
        .lnNonPositive: "ln: Argument muss größer als 0 sein",
        .log10NonPositive: "log10: Argument muss größer als 0 sein",
        .noFormula: "Widget besitzt keine Formel"
    ])
}
