import Foundation

public enum FormulaError: LocalizedError, Equatable {
    case emptyFormula
    case syntaxError(String)
    case syntaxErrorAt(String, position: Int)
    case divisionByZero
    case missingVariable(String)
    case unknownFunction(String, position: Int?)
    case wrongArity(function: String, expected: String, actual: Int, position: Int?)
    case domainError(String)
    case stepReference(String)

    /// Stable cross-platform error code, identical to `expected_error` in
    /// `fixtures/formula/evaluator_cases.json`.
    public var code: String {
        switch self {
        case .emptyFormula, .syntaxError, .syntaxErrorAt: return "syntax_error"
        case .divisionByZero: return "division_by_zero"
        case .missingVariable: return "missing_variable"
        case .unknownFunction: return "unknown_function"
        case .wrongArity: return "wrong_arity"
        case .domainError: return "domain_error"
        case .stepReference: return "step_reference_error"
        }
    }

    /// Zero-based character offset of the error in the expression, if known.
    public var position: Int? {
        switch self {
        case .syntaxErrorAt(_, let position): return position
        case .unknownFunction(_, let position): return position
        case .wrongArity(_, _, _, let position): return position
        default: return nil
        }
    }

    public var errorDescription: String? {
        switch self {
        case .emptyFormula:
            return "Formel darf nicht leer sein"
        case .syntaxError(let detail), .syntaxErrorAt(let detail, _):
            return "Syntaxfehler: \(detail)"
        case .divisionByZero:
            return "Division durch Null"
        case .missingVariable(let name):
            return "Fehlende Variable: \(name)"
        case .unknownFunction(let name, _):
            return "Unbekannte Funktion: \(name)"
        case .wrongArity(let function, let expected, let actual, _):
            return "Funktion \(function) erwartet \(expected) Argument(e), erhalten: \(actual)"
        case .domainError(let detail):
            return detail
        case .stepReference(let detail):
            return detail
        }
    }
}

/// Formula evaluator, contract v2. Mirrors the Dart and Kotlin evaluators
/// (see docs/architecture.md) and is verified against
/// `fixtures/formula/evaluator_cases.json`.
public enum FormulaEvaluator {
    private enum TokenType {
        case number, identifier
        case plus, minus, star, slash
        case lparen, rparen, comma
        case lt, gt, le, ge, eq, ne
        case end
    }

    private struct Token {
        let type: TokenType
        let text: String
        let pos: Int
        let value: Double
    }

    private indirect enum Node {
        case num(Double)
        case ident(String)
        case neg(Node)
        case bin(TokenType, Node, Node)
        case call(String, [Node])
    }

    /// Arity as (min, max); max nil means unbounded.
    private static let functions: [String: (min: Int, max: Int?)] = [
        "min": (1, nil),
        "max": (1, nil),
        "clamp": (3, 3),
        "abs": (1, 1),
        "pow": (2, 2),
        "sqrt": (1, 1),
        "ln": (1, 1),
        "log10": (1, 1),
        "exp": (1, 1),
        "round": (1, 1),
        "floor": (1, 1),
        "ceil": (1, 1),
        "if": (3, 3)
    ]

    private static let constants: [String: Double] = ["pi": Double.pi, "e": M_E]

    // MARK: - Public API

    public static func validateSyntax(_ formula: String) -> String? {
        if formula.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Formel darf nicht leer sein"
        }
        do {
            _ = try parse(formula)
            return nil
        } catch let error as FormulaError {
            let message = error.errorDescription ?? "Ungültige Formel"
            if let position = error.position {
                return "\(message) (Position \(position + 1))"
            }
            return message
        } catch {
            return error.localizedDescription
        }
    }

    public static func validateSteps(
        _ steps: [FormulaStep],
        formula: String,
        variableNames: [String]
    ) -> String? {
        var known = Set(variableNames)
        let allSteps = Set(steps.map { $0.name })
        do {
            for step in steps {
                try checkStepName(step.name, taken: known)
                try checkReferences(try parse(step.expression), known: known, allSteps: allSteps, current: step.name)
                known.insert(step.name)
            }
            try checkReferences(try parse(formula), known: known, allSteps: [], current: nil)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    public static func extractVariables(_ formula: String) -> [String] {
        guard let ast = try? parse(formula) else { return [] }
        var out: [String] = []
        collectIdents(ast, &out)
        return out.filter { constants[$0] == nil }
    }

    public static func evaluate(
        _ formula: String,
        variables: [String: Double],
        steps: [FormulaStep] = []
    ) throws -> Double {
        let trimmed = formula.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw FormulaError.emptyFormula
        }
        var scope = variables
        let allSteps = Set(steps.map { $0.name })
        for step in steps {
            try checkStepName(step.name, taken: Set(scope.keys))
            let ast = try parse(step.expression)
            try checkForwardReferences(ast, known: Set(scope.keys), allSteps: allSteps, current: step.name)
            scope[step.name] = try eval(ast, scope)
        }
        return try eval(try parse(trimmed), scope)
    }

    // MARK: - Step validation

    private static func checkStepName(_ name: String, taken: Set<String>) throws {
        let chars = Array(name)
        let validName = !chars.isEmpty
            && isIdentStart(chars[0])
            && chars.allSatisfy { isIdentStart($0) || isDigit($0) }
        if !validName {
            throw FormulaError.stepReference("Ungültiger Schrittname: \"\(name)\"")
        }
        if functions[name] != nil {
            throw FormulaError.stepReference("Schrittname \"\(name)\" ist ein Funktionsname")
        }
        if taken.contains(name) {
            throw FormulaError.stepReference("Doppelter Name: \"\(name)\"")
        }
    }

    private static func checkForwardReferences(
        _ ast: Node,
        known: Set<String>,
        allSteps: Set<String>,
        current: String?
    ) throws {
        var idents: [String] = []
        collectIdents(ast, &idents)
        for id in idents where !known.contains(id) && allSteps.contains(id) {
            if id == current {
                throw FormulaError.stepReference("Schritt \"\(id)\" verweist auf sich selbst")
            }
            throw FormulaError.stepReference("Schritt verweist auf später definierten Schritt \"\(id)\"")
        }
    }

    private static func checkReferences(
        _ ast: Node,
        known: Set<String>,
        allSteps: Set<String>,
        current: String?
    ) throws {
        try checkForwardReferences(ast, known: known, allSteps: allSteps, current: current)
        var idents: [String] = []
        collectIdents(ast, &idents)
        for id in idents where !known.contains(id) && constants[id] == nil {
            throw FormulaError.missingVariable(id)
        }
    }

    private static func collectIdents(_ node: Node, _ out: inout [String]) {
        switch node {
        case .num:
            break
        case .ident(let name):
            if !out.contains(name) { out.append(name) }
        case .neg(let operand):
            collectIdents(operand, &out)
        case .bin(_, let left, let right):
            collectIdents(left, &out)
            collectIdents(right, &out)
        case .call(_, let args):
            for arg in args { collectIdents(arg, &out) }
        }
    }

    // MARK: - Tokenizer

    private static func isDigit(_ c: Character) -> Bool {
        return c >= "0" && c <= "9"
    }

    private static func isIdentStart(_ c: Character) -> Bool {
        return (c >= "A" && c <= "Z") || (c >= "a" && c <= "z") || c == "_"
    }

    private static func tokenize(_ expression: String) throws -> [Token] {
        var tokens: [Token] = []
        let chars = Array(expression)
        var i = 0

        func add(_ type: TokenType, _ text: String, _ pos: Int, _ value: Double = 0) {
            tokens.append(Token(type: type, text: text, pos: pos, value: value))
        }

        while i < chars.count {
            let c = chars[i]
            if c.isWhitespace {
                i += 1
                continue
            }
            let next: Character = i + 1 < chars.count ? chars[i + 1] : " "
            switch c {
            case "+": add(.plus, "+", i); i += 1
            case "-": add(.minus, "-", i); i += 1
            case "*": add(.star, "*", i); i += 1
            case "/": add(.slash, "/", i); i += 1
            case "(": add(.lparen, "(", i); i += 1
            case ")": add(.rparen, ")", i); i += 1
            case ",": add(.comma, ",", i); i += 1
            case "<":
                if next == "=" { add(.le, "<=", i); i += 2 } else { add(.lt, "<", i); i += 1 }
            case ">":
                if next == "=" { add(.ge, ">=", i); i += 2 } else { add(.gt, ">", i); i += 1 }
            case "=":
                guard next == "=" else {
                    throw FormulaError.syntaxErrorAt("Unerwartetes Zeichen: \"=\" (Vergleich: \"==\")", position: i)
                }
                add(.eq, "==", i)
                i += 2
            case "!":
                guard next == "=" else {
                    throw FormulaError.syntaxErrorAt("Unerwartetes Zeichen: \"!\"", position: i)
                }
                add(.ne, "!=", i)
                i += 2
            default:
                if isDigit(c) || c == "." {
                    let start = i
                    var hasDot = false
                    while i < chars.count && (isDigit(chars[i]) || (chars[i] == "." && !hasDot)) {
                        if chars[i] == "." { hasDot = true }
                        i += 1
                    }
                    let text = String(chars[start..<i])
                    guard let value = Double(text) else {
                        throw FormulaError.syntaxErrorAt("Ungültige Zahl: \(text)", position: start)
                    }
                    add(.number, text, start, value)
                } else if isIdentStart(c) {
                    let start = i
                    while i < chars.count && (isIdentStart(chars[i]) || isDigit(chars[i])) {
                        i += 1
                    }
                    add(.identifier, String(chars[start..<i]), start)
                } else {
                    throw FormulaError.syntaxErrorAt("Unerwartetes Zeichen: \"\(c)\"", position: i)
                }
            }
        }
        add(.end, "", chars.count)
        return tokens
    }

    private static func parse(_ formula: String) throws -> Node {
        var parser = Parser(tokens: try tokenize(formula))
        return try parser.parseAll()
    }

    // MARK: - Parser

    private struct Parser {
        let tokens: [Token]
        var index = 0

        init(tokens: [Token]) {
            self.tokens = tokens
        }

        private var cur: Token { tokens[index] }

        mutating func parseAll() throws -> Node {
            let node = try comparison()
            if cur.type != .end {
                let message: String
                switch cur.type {
                case .rparen: message = "Fehlende öffnende Klammer"
                case .number, .identifier: message = "Fehlender Operator zwischen Operanden"
                default: message = "Unerwartetes Zeichen: \"\(cur.text)\""
                }
                throw FormulaError.syntaxErrorAt(message, position: cur.pos)
            }
            return node
        }

        private static let comparisonOps: Set<TokenType> = [.lt, .gt, .le, .ge, .eq, .ne]

        private mutating func comparison() throws -> Node {
            var left = try additive()
            while Parser.comparisonOps.contains(cur.type) {
                let op = cur.type
                index += 1
                left = .bin(op, left, try additive())
            }
            return left
        }

        private mutating func additive() throws -> Node {
            var left = try term()
            while cur.type == .plus || cur.type == .minus {
                let op = cur.type
                index += 1
                left = .bin(op, left, try term())
            }
            return left
        }

        private mutating func term() throws -> Node {
            var left = try unary()
            while cur.type == .star || cur.type == .slash {
                let op = cur.type
                index += 1
                left = .bin(op, left, try unary())
            }
            return left
        }

        private mutating func unary() throws -> Node {
            if cur.type == .minus {
                index += 1
                return .neg(try unary())
            }
            return try primary()
        }

        private mutating func primary() throws -> Node {
            let t = cur
            switch t.type {
            case .number:
                index += 1
                return .num(t.value)
            case .identifier:
                index += 1
                if cur.type == .lparen { return try callNode(t) }
                return .ident(t.text)
            case .lparen:
                index += 1
                let inner = try comparison()
                try expectClose()
                return inner
            case .end:
                throw FormulaError.syntaxErrorAt("Ausdruck unvollständig", position: t.pos)
            default:
                throw FormulaError.syntaxErrorAt("Unerwartetes Zeichen: \"\(t.text)\"", position: t.pos)
            }
        }

        private mutating func expectClose() throws {
            guard cur.type == .rparen else {
                throw FormulaError.syntaxErrorAt("Nicht geschlossene Klammer", position: cur.pos)
            }
            index += 1
        }

        private mutating func callNode(_ nameToken: Token) throws -> Node {
            let name = nameToken.text
            guard let arity = FormulaEvaluator.functions[name] else {
                throw FormulaError.unknownFunction(name, position: nameToken.pos)
            }
            index += 1 // '('
            var args: [Node] = []
            if cur.type != .rparen {
                args.append(try comparison())
                while cur.type == .comma {
                    index += 1
                    args.append(try comparison())
                }
            }
            try expectClose()
            if args.count < arity.min || (arity.max != nil && args.count > arity.max!) {
                let expected: String
                if let maxArgs = arity.max {
                    expected = arity.min == maxArgs ? "\(arity.min)" : "\(arity.min) bis \(maxArgs)"
                } else {
                    expected = "mindestens \(arity.min)"
                }
                throw FormulaError.wrongArity(
                    function: name,
                    expected: expected,
                    actual: args.count,
                    position: nameToken.pos
                )
            }
            return .call(name, args)
        }
    }

    // MARK: - Evaluation

    private static func finite(_ value: Double, _ what: String = "Ergebnis") throws -> Double {
        if value.isNaN || value.isInfinite {
            throw FormulaError.domainError("\(what): Ergebnis ist nicht endlich")
        }
        return value
    }

    private static func bool(_ b: Bool) -> Double {
        return b ? 1.0 : 0.0
    }

    private static func eval(_ node: Node, _ scope: [String: Double]) throws -> Double {
        switch node {
        case .num(let value):
            return value
        case .ident(let name):
            if let v = scope[name] ?? constants[name] { return v }
            throw FormulaError.missingVariable(name)
        case .neg(let operand):
            return -(try eval(operand, scope))
        case .bin(let op, let left, let right):
            let a = try eval(left, scope)
            let b = try eval(right, scope)
            switch op {
            case .plus: return try finite(a + b)
            case .minus: return try finite(a - b)
            case .star: return try finite(a * b)
            case .slash:
                if b == 0.0 { throw FormulaError.divisionByZero }
                return try finite(a / b)
            case .lt: return bool(a < b)
            case .gt: return bool(a > b)
            case .le: return bool(a <= b)
            case .ge: return bool(a >= b)
            case .eq: return bool(a == b)
            case .ne: return bool(a != b)
            default: throw FormulaError.syntaxError("Unbekannter Operator")
            }
        case .call(let name, let args):
            return try call(name, args, scope)
        }
    }

    private static func call(_ name: String, _ args: [Node], _ scope: [String: Double]) throws -> Double {
        if name == "if" {
            let cond = try eval(args[0], scope)
            return try eval(cond != 0.0 ? args[1] : args[2], scope)
        }
        let v = try args.map { try eval($0, scope) }
        switch name {
        case "min": return v.min()!
        case "max": return v.max()!
        case "clamp":
            if v[1] > v[2] {
                throw FormulaError.domainError("clamp: untere Grenze größer als obere Grenze")
            }
            return Swift.min(Swift.max(v[0], v[1]), v[2])
        case "abs": return Swift.abs(v[0])
        case "pow": return try finite(Foundation.pow(v[0], v[1]), "pow")
        case "sqrt":
            if v[0] < 0 { throw FormulaError.domainError("sqrt: Argument darf nicht negativ sein") }
            return v[0].squareRoot()
        case "ln":
            if v[0] <= 0 { throw FormulaError.domainError("ln: Argument muss größer als 0 sein") }
            return Foundation.log(v[0])
        case "log10":
            if v[0] <= 0 { throw FormulaError.domainError("log10: Argument muss größer als 0 sein") }
            return Foundation.log(v[0]) / Foundation.log(10.0)
        case "exp": return try finite(Foundation.exp(v[0]), "exp")
        // Half away from zero, like Dart's roundToDouble().
        case "round": return v[0].rounded(.toNearestOrAwayFromZero)
        case "floor": return v[0].rounded(.down)
        case "ceil": return v[0].rounded(.up)
        default: throw FormulaError.unknownFunction(name, position: nil)
        }
    }
}
