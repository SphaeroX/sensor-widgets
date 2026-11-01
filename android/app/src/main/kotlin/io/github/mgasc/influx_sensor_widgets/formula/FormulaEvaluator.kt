package io.github.mgasc.influx_sensor_widgets.formula

import kotlin.math.abs

object FormulaEvaluator {
    private enum class TokenType {
        NUMBER,
        IDENTIFIER,
        PLUS,
        MINUS,
        MULTIPLY,
        DIVIDE,
        OPEN_PAREN,
        CLOSE_PAREN,
    }

    private data class Token(
        val type: TokenType,
        val text: String,
        val numberValue: Double? = null,
    )

    fun validateSyntax(formula: String): String? {
        if (formula.trim().isEmpty()) {
            return "Formel darf nicht leer sein"
        }
        return try {
            val tokens = tokenize(formula)
            if (tokens.isEmpty()) return "Formel darf nicht leer sein"
            val rpn = toRpn(tokens)
            if (rpn.isEmpty()) "Ungültige Formel" else null
        } catch (e: Exception) {
            e.message ?: "Ungültige Formel"
        }
    }

    fun extractVariables(formula: String): List<String> =
        try {
            val tokens = tokenize(formula)
            val list = mutableListOf<String>()
            for (t in tokens) {
                if (t.type == TokenType.IDENTIFIER && !list.contains(t.text)) {
                    list.add(t.text)
                }
            }
            list
        } catch (e: Exception) {
            emptyList()
        }

    fun evaluate(
        formula: String,
        variables: Map<String, Double>,
    ): Double {
        if (formula.trim().isEmpty()) {
            throw FormulaSyntaxException("Formel darf nicht leer sein")
        }
        val tokens = tokenize(formula)
        val rpn = toRpn(tokens)
        return evaluateRpn(rpn, variables)
    }

    private fun tokenize(expression: String): List<Token> {
        val tokens = mutableListOf<Token>()
        var i = 0
        val length = expression.length

        while (i < length) {
            val char = expression[i]

            if (char.isWhitespace()) {
                i++
                continue
            }

            when (char) {
                '+' -> {
                    tokens.add(Token(TokenType.PLUS, "+"))
                    i++
                }
                '-' -> {
                    val isUnary =
                        tokens.isEmpty() ||
                            tokens.last().type == TokenType.PLUS ||
                            tokens.last().type == TokenType.MINUS ||
                            tokens.last().type == TokenType.MULTIPLY ||
                            tokens.last().type == TokenType.DIVIDE ||
                            tokens.last().type == TokenType.OPEN_PAREN

                    if (isUnary) {
                        var nextIndex = i + 1
                        while (nextIndex < length && expression[nextIndex].isWhitespace()) {
                            nextIndex++
                        }
                        if (nextIndex < length && expression[nextIndex].isDigit()) {
                            var numStr = "-"
                            i = nextIndex
                            var hasDot = false
                            while (i < length) {
                                val c = expression[i]
                                if (c.isDigit()) {
                                    numStr += c
                                    i++
                                } else if (c == '.' && !hasDot) {
                                    hasDot = true
                                    numStr += c
                                    i++
                                } else {
                                    break
                                }
                            }
                            val num =
                                numStr.toDoubleOrNull()
                                    ?: throw FormulaSyntaxException("Ungültige Zahl: $numStr")
                            tokens.add(Token(TokenType.NUMBER, numStr, num))
                        } else {
                            tokens.add(Token(TokenType.NUMBER, "0", 0.0))
                            tokens.add(Token(TokenType.MINUS, "-"))
                            i++
                        }
                    } else {
                        tokens.add(Token(TokenType.MINUS, "-"))
                        i++
                    }
                }
                '*' -> {
                    tokens.add(Token(TokenType.MULTIPLY, "*"))
                    i++
                }
                '/' -> {
                    tokens.add(Token(TokenType.DIVIDE, "/"))
                    i++
                }
                '(' -> {
                    tokens.add(Token(TokenType.OPEN_PAREN, "("))
                    i++
                }
                ')' -> {
                    tokens.add(Token(TokenType.CLOSE_PAREN, ")"))
                    i++
                }
                else -> {
                    if (char.isDigit() || char == '.') {
                        var numStr = ""
                        var hasDot = false
                        while (i < length) {
                            val c = expression[i]
                            if (c.isDigit()) {
                                numStr += c
                                i++
                            } else if (c == '.' && !hasDot) {
                                hasDot = true
                                numStr += c
                                i++
                            } else {
                                break
                            }
                        }
                        val num =
                            numStr.toDoubleOrNull()
                                ?: throw FormulaSyntaxException("Ungültige Zahl: $numStr")
                        tokens.add(Token(TokenType.NUMBER, numStr, num))
                    } else if (isIdentStart(char)) {
                        var ident = ""
                        while (i < length && isIdentPart(expression[i])) {
                            ident += expression[i]
                            i++
                        }
                        tokens.add(Token(TokenType.IDENTIFIER, ident))
                    } else {
                        throw FormulaSyntaxException("Unerwartetes Zeichen: \"$char\"")
                    }
                }
            }
        }
        return tokens
    }

    private fun isIdentStart(c: Char): Boolean = (c in 'A'..'Z') || (c in 'a'..'z') || c == '_'

    private fun isIdentPart(c: Char): Boolean = isIdentStart(c) || c.isDigit()

    private fun precedence(type: TokenType): Int =
        when (type) {
            TokenType.PLUS, TokenType.MINUS -> 1
            TokenType.MULTIPLY, TokenType.DIVIDE -> 2
            else -> 0
        }

    private fun toRpn(tokens: List<Token>): List<Token> {
        val output = mutableListOf<Token>()
        val operatorStack = mutableListOf<Token>()
        var lastToken: Token? = null

        for (token in tokens) {
            when (token.type) {
                TokenType.NUMBER, TokenType.IDENTIFIER -> {
                    if (lastToken != null &&
                        (
                            lastToken.type == TokenType.NUMBER ||
                                lastToken.type == TokenType.IDENTIFIER ||
                                lastToken.type == TokenType.CLOSE_PAREN
                        )
                    ) {
                        throw FormulaSyntaxException("Fehlender Operator zwischen Operanden")
                    }
                    output.add(token)
                }
                TokenType.PLUS, TokenType.MINUS, TokenType.MULTIPLY, TokenType.DIVIDE -> {
                    if (lastToken == null ||
                        lastToken.type == TokenType.PLUS ||
                        lastToken.type == TokenType.MINUS ||
                        lastToken.type == TokenType.MULTIPLY ||
                        lastToken.type == TokenType.DIVIDE ||
                        lastToken.type == TokenType.OPEN_PAREN
                    ) {
                        throw FormulaSyntaxException("Unerwarteter Operator")
                    }
                    while (operatorStack.isNotEmpty() &&
                        operatorStack.last().type != TokenType.OPEN_PAREN &&
                        precedence(operatorStack.last().type) >= precedence(token.type)
                    ) {
                        output.add(operatorStack.removeAt(operatorStack.size - 1))
                    }
                    operatorStack.add(token)
                }
                TokenType.OPEN_PAREN -> {
                    operatorStack.add(token)
                }
                TokenType.CLOSE_PAREN -> {
                    if (lastToken != null &&
                        (
                            lastToken.type == TokenType.PLUS ||
                                lastToken.type == TokenType.MINUS ||
                                lastToken.type == TokenType.MULTIPLY ||
                                lastToken.type == TokenType.DIVIDE ||
                                lastToken.type == TokenType.OPEN_PAREN
                        )
                    ) {
                        throw FormulaSyntaxException("Unerwartete schließende Klammer")
                    }
                    var foundOpen = false
                    while (operatorStack.isNotEmpty()) {
                        val top = operatorStack.removeAt(operatorStack.size - 1)
                        if (top.type == TokenType.OPEN_PAREN) {
                            foundOpen = true
                            break
                        }
                        output.add(top)
                    }
                    if (!foundOpen) {
                        throw FormulaSyntaxException("Fehlende öffnende Klammer")
                    }
                }
            }
            lastToken = token
        }

        if (lastToken != null &&
            (
                lastToken.type == TokenType.PLUS ||
                    lastToken.type == TokenType.MINUS ||
                    lastToken.type == TokenType.MULTIPLY ||
                    lastToken.type == TokenType.DIVIDE
            )
        ) {
            throw FormulaSyntaxException("Ausdruck darf nicht mit Operator enden")
        }

        while (operatorStack.isNotEmpty()) {
            val top = operatorStack.removeAt(operatorStack.size - 1)
            if (top.type == TokenType.OPEN_PAREN) {
                throw FormulaSyntaxException("Nicht geschlossene Klammer")
            }
            output.add(top)
        }

        return output
    }

    private fun evaluateRpn(
        rpn: List<Token>,
        variables: Map<String, Double>,
    ): Double {
        val stack = mutableListOf<Double>()

        for (token in rpn) {
            when (token.type) {
                TokenType.NUMBER -> {
                    stack.add(token.numberValue ?: 0.0)
                }
                TokenType.IDENTIFIER -> {
                    val value =
                        variables[token.text]
                            ?: throw MissingVariableException(token.text)
                    stack.add(value)
                }
                TokenType.PLUS, TokenType.MINUS, TokenType.MULTIPLY, TokenType.DIVIDE -> {
                    if (stack.size < 2) {
                        throw FormulaSyntaxException("Ungenügend Operanden für Operation")
                    }
                    val b = stack.removeAt(stack.size - 1)
                    val a = stack.removeAt(stack.size - 1)

                    val res =
                        when (token.type) {
                            TokenType.PLUS -> a + b
                            TokenType.MINUS -> a - b
                            TokenType.MULTIPLY -> a * b
                            TokenType.DIVIDE -> {
                                if (abs(b) < 1e-15 || b == 0.0) {
                                    throw DivisionByZeroException()
                                }
                                a / b
                            }
                            TokenType.NUMBER, TokenType.IDENTIFIER,
                            TokenType.OPEN_PAREN, TokenType.CLOSE_PAREN,
                            ->
                                throw FormulaSyntaxException("Unbekannter Operator: ${token.text}")
                        }
                    stack.add(res)
                }
                else -> throw FormulaSyntaxException("Unerwarteter RPN-Token: ${token.text}")
            }
        }

        if (stack.size != 1) {
            throw FormulaSyntaxException("Ungültiger mathematischer Ausdruck")
        }
        return stack.first()
    }
}
