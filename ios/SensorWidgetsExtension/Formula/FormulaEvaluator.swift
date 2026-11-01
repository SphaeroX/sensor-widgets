import Foundation

public enum FormulaError: LocalizedError, Equatable {
    case emptyFormula
    case syntaxError(String)
    case divisionByZero
    case missingVariable(String)

    public var errorDescription: String? {
        switch self {
        case .emptyFormula:
            return "Formel darf nicht leer sein"
        case .syntaxError(let detail):
            return "Syntaxfehler: \(detail)"
        case .divisionByZero:
            return "Division durch Null"
        case .missingVariable(let name):
            return "Fehlende Variable: \(name)"
        }
    }
}

public enum FormulaEvaluator {
    private enum TokenType {
        case number
        case identifier
        case plus
        case minus
        case multiply
        case divide
        case openParen
        case closeParen
    }

    private struct Token {
        let type: TokenType
        let text: String
        let numberValue: Double?
    }

    public static func validateSyntax(_ formula: String) -> String? {
        if formula.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Formel darf nicht leer sein"
        }
        do {
            let tokens = try tokenize(formula)
            if tokens.isEmpty { return "Formel darf nicht leer sein" }
            let rpn = try toRpn(tokens)
            if rpn.isEmpty { return "Ungültige Formel" }
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    public static func extractVariables(_ formula: String) -> [String] {
        guard let tokens = try? tokenize(formula) else { return [] }
        var result: [String] = []
        for t in tokens where t.type == .identifier {
            if !result.contains(t.text) {
                result.append(t.text)
            }
        }
        return result
    }

    public static func evaluate(_ formula: String, variables: [String: Double]) throws -> Double {
        let trimmed = formula.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw FormulaError.emptyFormula
        }
        let tokens = try tokenize(trimmed)
        let rpn = try toRpn(tokens)
        return try evaluateRpn(rpn, variables: variables)
    }

    private static func tokenize(_ expression: String) throws -> [Token] {
        var tokens: [Token] = []
        let chars = Array(expression)
        var i = 0
        let count = chars.count

        while i < count {
            let c = chars[i]

            if c.isWhitespace {
                i += 1
                continue
            }

            switch c {
            case "+":
                tokens.append(Token(type: .plus, text: "+", numberValue: nil))
                i += 1
            case "-":
                let isUnary = tokens.isEmpty ||
                    tokens.last?.type == .plus ||
                    tokens.last?.type == .minus ||
                    tokens.last?.type == .multiply ||
                    tokens.last?.type == .divide ||
                    tokens.last?.type == .openParen

                if isUnary {
                    var nextIndex = i + 1
                    while nextIndex < count && chars[nextIndex].isWhitespace {
                        nextIndex += 1
                    }
                    if nextIndex < count && (chars[nextIndex].isNumber) {
                        var numStr = "-"
                        i = nextIndex
                        var hasDot = false
                        while i < count {
                            let curr = chars[i]
                            if curr.isNumber {
                                numStr.append(curr)
                                i += 1
                            } else if curr == "." && !hasDot {
                                hasDot = true
                                numStr.append(curr)
                                i += 1
                            } else {
                                break
                            }
                        }
                        guard let val = Double(numStr) else {
                            throw FormulaError.syntaxError("Ungültige Zahl: \(numStr)")
                        }
                        tokens.append(Token(type: .number, text: numStr, numberValue: val))
                    } else {
                        tokens.append(Token(type: .number, text: "0", numberValue: 0.0))
                        tokens.append(Token(type: .minus, text: "-", numberValue: nil))
                        i += 1
                    }
                } else {
                    tokens.append(Token(type: .minus, text: "-", numberValue: nil))
                    i += 1
                }
            case "*":
                tokens.append(Token(type: .multiply, text: "*", numberValue: nil))
                i += 1
            case "/":
                tokens.append(Token(type: .divide, text: "/", numberValue: nil))
                i += 1
            case "(":
                tokens.append(Token(type: .openParen, text: "(", numberValue: nil))
                i += 1
            case ")":
                tokens.append(Token(type: .closeParen, text: ")", numberValue: nil))
                i += 1
            default:
                if c.isNumber || c == "." {
                    var numStr = ""
                    var hasDot = false
                    while i < count {
                        let curr = chars[i]
                        if curr.isNumber {
                            numStr.append(curr)
                            i += 1
                        } else if curr == "." && !hasDot {
                            hasDot = true
                            numStr.append(curr)
                            i += 1
                        } else {
                            break
                        }
                    }
                    guard let val = Double(numStr) else {
                        throw FormulaError.syntaxError("Ungültige Zahl: \(numStr)")
                    }
                    tokens.append(Token(type: .number, text: numStr, numberValue: val))
                } else if isIdentStart(c) {
                    var ident = ""
                    while i < count && isIdentPart(chars[i]) {
                        ident.append(chars[i])
                        i += 1
                    }
                    tokens.append(Token(type: .identifier, text: ident, numberValue: nil))
                } else {
                    throw FormulaError.syntaxError("Unerwartetes Zeichen: \"\(c)\"")
                }
            }
        }
        return tokens
    }

    private static func isIdentStart(_ c: Character) -> Bool {
        return c.isLetter || c == "_"
    }

    private static func isIdentPart(_ c: Character) -> Bool {
        return isIdentStart(c) || c.isNumber
    }

    private static func precedence(_ type: TokenType) -> Int {
        switch type {
        case .plus, .minus: return 1
        case .multiply, .divide: return 2
        default: return 0
        }
    }

    private static func toRpn(_ tokens: [Token]) throws -> [Token] {
        var output: [Token] = []
        var operatorStack: [Token] = []
        var lastToken: Token? = nil

        for token in tokens {
            switch token.type {
            case .number, .identifier:
                if let last = lastToken,
                   last.type == .number || last.type == .identifier || last.type == .closeParen {
                    throw FormulaError.syntaxError("Fehlender Operator zwischen Operanden")
                }
                output.append(token)
            case .plus, .minus, .multiply, .divide:
                if lastToken == nil ||
                    lastToken?.type == .plus ||
                    lastToken?.type == .minus ||
                    lastToken?.type == .multiply ||
                    lastToken?.type == .divide ||
                    lastToken?.type == .openParen {
                    throw FormulaError.syntaxError("Unerwarteter Operator")
                }
                while let top = operatorStack.last,
                      top.type != .openParen,
                      precedence(top.type) >= precedence(token.type) {
                    output.append(operatorStack.removeLast())
                }
                operatorStack.append(token)
            case .openParen:
                operatorStack.append(token)
            case .closeParen:
                if let last = lastToken,
                   last.type == .plus || last.type == .minus || last.type == .multiply ||
                   last.type == .divide || last.type == .openParen {
                    throw FormulaError.syntaxError("Unerwartete schließende Klammer")
                }
                var foundOpen = false
                while !operatorStack.isEmpty {
                    let top = operatorStack.removeLast()
                    if top.type == .openParen {
                        foundOpen = true
                        break
                    }
                    output.append(top)
                }
                if !foundOpen {
                    throw FormulaError.syntaxError("Fehlende öffnende Klammer")
                }
            }
            lastToken = token
        }

        if let last = lastToken,
           last.type == .plus || last.type == .minus || last.type == .multiply || last.type == .divide {
            throw FormulaError.syntaxError("Ausdruck darf nicht mit Operator enden")
        }

        while !operatorStack.isEmpty {
            let top = operatorStack.removeLast()
            if top.type == .openParen {
                throw FormulaError.syntaxError("Nicht geschlossene Klammer")
            }
            output.append(top)
        }

        return output
    }

    private static func evaluateRpn(_ rpn: [Token], variables: [String: Double]) throws -> Double {
        var stack: [Double] = []

        for token in rpn {
            switch token.type {
            case .number:
                stack.append(token.numberValue ?? 0.0)
            case .identifier:
                guard let val = variables[token.text] else {
                    throw FormulaError.missingVariable(token.text)
                }
                stack.append(val)
            case .plus, .minus, .multiply, .divide:
                guard stack.count >= 2 else {
                    throw FormulaError.syntaxError("Ungenügend Operanden für Operation")
                }
                let b = stack.removeLast()
                let a = stack.removeLast()

                let res: Double
                switch token.type {
                case .plus: res = a + b
                case .minus: res = a - b
                case .multiply: res = a * b
                case .divide:
                    if abs(b) < 1e-15 || b == 0.0 {
                        throw FormulaError.divisionByZero
                    }
                    res = a / b
                default:
                    throw FormulaError.syntaxError("Unbekannter Operator")
                }
                stack.append(res)
            case .openParen, .closeParen:
                throw FormulaError.syntaxError("Unerwartete Klammer in RPN")
            }
        }

        guard stack.count == 1, let result = stack.first else {
            throw FormulaError.syntaxError("Ungültiger mathematischer Ausdruck")
        }
        return result
    }
}
