package io.github.sphaerox.influx_sensor_widgets.formula

import io.github.sphaerox.influx_sensor_widgets.model.FormulaStep
import kotlin.math.E
import kotlin.math.PI
import kotlin.math.ceil
import kotlin.math.exp
import kotlin.math.floor
import kotlin.math.ln
import kotlin.math.pow
import kotlin.math.sqrt

/**
 * Formula evaluator, contract v2. Mirrors the Dart `FormulaEvaluator`
 * (see docs/architecture.md) and is verified against
 * `fixtures/formula/evaluator_cases.json`.
 */
object FormulaEvaluator {
    private enum class T {
        NUMBER,
        IDENT,
        PLUS,
        MINUS,
        STAR,
        SLASH,
        LPAREN,
        RPAREN,
        COMMA,
        LT,
        GT,
        LE,
        GE,
        EQ,
        NE,
        END,
    }

    private data class Token(
        val type: T,
        val text: String,
        val pos: Int,
        val value: Double = 0.0,
    )

    private sealed class Node {
        class Num(
            val value: Double,
        ) : Node()

        class Ident(
            val name: String,
        ) : Node()

        class Neg(
            val operand: Node,
        ) : Node()

        class Bin(
            val op: T,
            val left: Node,
            val right: Node,
        ) : Node()

        class Call(
            val name: String,
            val args: List<Node>,
        ) : Node()
    }

    /** Arity as (min, max); max null means unbounded. */
    private val functions: Map<String, Pair<Int, Int?>> =
        mapOf(
            "min" to (1 to null),
            "max" to (1 to null),
            "clamp" to (3 to 3),
            "abs" to (1 to 1),
            "pow" to (2 to 2),
            "sqrt" to (1 to 1),
            "ln" to (1 to 1),
            "log10" to (1 to 1),
            "exp" to (1 to 1),
            "round" to (1 to 1),
            "floor" to (1 to 1),
            "ceil" to (1 to 1),
            "if" to (3 to 3),
        )

    private val constants: Map<String, Double> = mapOf("pi" to PI, "e" to E)

    private val identPattern = Regex("^[A-Za-z_][A-Za-z0-9_]*$")

    fun validateSyntax(formula: String): String? {
        if (formula.trim().isEmpty()) return "Formel darf nicht leer sein"
        return try {
            parse(formula)
            null
        } catch (e: FormulaException) {
            val position =
                when (e) {
                    is FormulaSyntaxException -> e.position
                    is UnknownFunctionException -> e.position
                    is WrongArgumentCountException -> e.position
                    else -> null
                }
            if (position == null) e.message else "${e.message} (Position ${position + 1})"
        }
    }

    fun validateSteps(
        steps: List<FormulaStep>,
        formula: String,
        variableNames: List<String>,
    ): String? {
        val known = variableNames.toMutableSet()
        val allSteps = steps.map { it.name }.toSet()
        return try {
            for (step in steps) {
                checkStepName(step.name, known)
                checkReferences(parse(step.expression), known, allSteps, step.name)
                known.add(step.name)
            }
            checkReferences(parse(formula), known, emptySet(), null)
            null
        } catch (e: FormulaException) {
            e.message
        }
    }

    fun extractVariables(formula: String): List<String> =
        try {
            val out = mutableListOf<String>()
            collectIdents(parse(formula), out)
            out.filter { !constants.containsKey(it) }
        } catch (e: FormulaException) {
            emptyList()
        }

    fun evaluate(
        formula: String,
        variables: Map<String, Double>,
        steps: List<FormulaStep> = emptyList(),
    ): Double {
        if (formula.trim().isEmpty()) {
            throw FormulaSyntaxException("Formel darf nicht leer sein")
        }
        val scope = variables.toMutableMap()
        val allSteps = steps.map { it.name }.toSet()
        for (step in steps) {
            checkStepName(step.name, scope.keys)
            val ast = parse(step.expression)
            checkForwardReferences(ast, scope.keys, allSteps, step.name)
            scope[step.name] = eval(ast, scope)
        }
        return eval(parse(formula), scope)
    }

    private fun checkStepName(
        name: String,
        taken: Collection<String>,
    ) {
        if (!identPattern.matches(name)) {
            throw StepReferenceException("Ungültiger Schrittname: \"$name\"")
        }
        if (functions.containsKey(name)) {
            throw StepReferenceException("Schrittname \"$name\" ist ein Funktionsname")
        }
        if (taken.contains(name)) {
            throw StepReferenceException("Doppelter Name: \"$name\"")
        }
    }

    private fun checkForwardReferences(
        ast: Node,
        known: Collection<String>,
        allSteps: Set<String>,
        current: String?,
    ) {
        val idents = mutableListOf<String>()
        collectIdents(ast, idents)
        for (id in idents) {
            if (!known.contains(id) && allSteps.contains(id)) {
                throw StepReferenceException(
                    if (id == current) {
                        "Schritt \"$id\" verweist auf sich selbst"
                    } else {
                        "Schritt verweist auf später definierten Schritt \"$id\""
                    },
                )
            }
        }
    }

    private fun checkReferences(
        ast: Node,
        known: Set<String>,
        allSteps: Set<String>,
        current: String?,
    ) {
        checkForwardReferences(ast, known, allSteps, current)
        val idents = mutableListOf<String>()
        collectIdents(ast, idents)
        for (id in idents) {
            if (!known.contains(id) && !constants.containsKey(id)) {
                throw MissingVariableException(id)
            }
        }
    }

    private fun collectIdents(
        node: Node,
        out: MutableList<String>,
    ) {
        when (node) {
            is Node.Num -> Unit
            is Node.Ident -> if (!out.contains(node.name)) out.add(node.name)
            is Node.Neg -> collectIdents(node.operand, out)
            is Node.Bin -> {
                collectIdents(node.left, out)
                collectIdents(node.right, out)
            }
            is Node.Call -> node.args.forEach { collectIdents(it, out) }
        }
    }

    // ---------------------------------------------------------------- tokenizer

    private fun isDigit(c: Char) = c in '0'..'9'

    private fun isIdentStart(c: Char) = (c in 'A'..'Z') || (c in 'a'..'z') || c == '_'

    private fun tokenize(s: String): List<Token> {
        val tokens = mutableListOf<Token>()
        var i = 0
        while (i < s.length) {
            val c = s[i]
            if (c.isWhitespace()) {
                i++
                continue
            }
            val next = if (i + 1 < s.length) s[i + 1] else ' '
            val single =
                when (c) {
                    '+' -> T.PLUS
                    '-' -> T.MINUS
                    '*' -> T.STAR
                    '/' -> T.SLASH
                    '(' -> T.LPAREN
                    ')' -> T.RPAREN
                    ',' -> T.COMMA
                    else -> null
                }
            if (single != null) {
                tokens.add(Token(single, c.toString(), i))
                i++
                continue
            }
            when {
                c == '<' || c == '>' -> {
                    if (next == '=') {
                        tokens.add(Token(if (c == '<') T.LE else T.GE, "$c=", i))
                        i += 2
                    } else {
                        tokens.add(Token(if (c == '<') T.LT else T.GT, c.toString(), i))
                        i++
                    }
                }
                c == '=' -> {
                    if (next != '=') {
                        throw FormulaSyntaxException("Unerwartetes Zeichen: \"=\" (Vergleich: \"==\")", i)
                    }
                    tokens.add(Token(T.EQ, "==", i))
                    i += 2
                }
                c == '!' -> {
                    if (next != '=') throw FormulaSyntaxException("Unerwartetes Zeichen: \"!\"", i)
                    tokens.add(Token(T.NE, "!=", i))
                    i += 2
                }
                isDigit(c) || c == '.' -> {
                    val start = i
                    var hasDot = false
                    while (i < s.length && (isDigit(s[i]) || (s[i] == '.' && !hasDot))) {
                        if (s[i] == '.') hasDot = true
                        i++
                    }
                    val text = s.substring(start, i)
                    val value =
                        text.toDoubleOrNull()
                            ?: throw FormulaSyntaxException("Ungültige Zahl: $text", start)
                    tokens.add(Token(T.NUMBER, text, start, value))
                }
                isIdentStart(c) -> {
                    val start = i
                    while (i < s.length && (isIdentStart(s[i]) || isDigit(s[i]))) i++
                    tokens.add(Token(T.IDENT, s.substring(start, i), start))
                }
                else -> throw FormulaSyntaxException("Unerwartetes Zeichen: \"$c\"", i)
            }
        }
        tokens.add(Token(T.END, "", s.length))
        return tokens
    }

    private fun parse(formula: String): Node = Parser(tokenize(formula)).parseAll()

    private class Parser(
        private val tokens: List<Token>,
    ) {
        private var i = 0
        private val cur get() = tokens[i]

        fun parseAll(): Node {
            val node = comparison()
            if (cur.type != T.END) {
                val msg =
                    when (cur.type) {
                        T.RPAREN -> "Fehlende öffnende Klammer"
                        T.NUMBER, T.IDENT -> "Fehlender Operator zwischen Operanden"
                        else -> "Unerwartetes Zeichen: \"${cur.text}\""
                    }
                throw FormulaSyntaxException(msg, cur.pos)
            }
            return node
        }

        private val cmpOps = setOf(T.LT, T.GT, T.LE, T.GE, T.EQ, T.NE)

        private fun comparison(): Node {
            var left = additive()
            while (cur.type in cmpOps) {
                val op = tokens[i++].type
                left = Node.Bin(op, left, additive())
            }
            return left
        }

        private fun additive(): Node {
            var left = term()
            while (cur.type == T.PLUS || cur.type == T.MINUS) {
                val op = tokens[i++].type
                left = Node.Bin(op, left, term())
            }
            return left
        }

        private fun term(): Node {
            var left = unary()
            while (cur.type == T.STAR || cur.type == T.SLASH) {
                val op = tokens[i++].type
                left = Node.Bin(op, left, unary())
            }
            return left
        }

        private fun unary(): Node {
            if (cur.type == T.MINUS) {
                i++
                return Node.Neg(unary())
            }
            return primary()
        }

        private fun primary(): Node {
            val t = cur
            return when (t.type) {
                T.NUMBER -> {
                    i++
                    Node.Num(t.value)
                }
                T.IDENT -> {
                    i++
                    if (cur.type == T.LPAREN) callNode(t) else Node.Ident(t.text)
                }
                T.LPAREN -> {
                    i++
                    val inner = comparison()
                    expectClose()
                    inner
                }
                T.END -> throw FormulaSyntaxException("Ausdruck unvollständig", t.pos)
                else -> throw FormulaSyntaxException("Unerwartetes Zeichen: \"${t.text}\"", t.pos)
            }
        }

        private fun expectClose() {
            if (cur.type != T.RPAREN) {
                throw FormulaSyntaxException("Nicht geschlossene Klammer", cur.pos)
            }
            i++
        }

        private fun callNode(nameToken: Token): Node {
            val name = nameToken.text
            val (minArgs, maxArgs) =
                functions[name] ?: throw UnknownFunctionException(name, nameToken.pos)
            i++ // '('
            val args = mutableListOf<Node>()
            if (cur.type != T.RPAREN) {
                args.add(comparison())
                while (cur.type == T.COMMA) {
                    i++
                    args.add(comparison())
                }
            }
            expectClose()
            if (args.size < minArgs || (maxArgs != null && args.size > maxArgs)) {
                val expected =
                    when {
                        maxArgs == null -> "mindestens $minArgs"
                        minArgs == maxArgs -> "$minArgs"
                        else -> "$minArgs bis $maxArgs"
                    }
                throw WrongArgumentCountException(name, expected, args.size, nameToken.pos)
            }
            return Node.Call(name, args)
        }
    }

    // --------------------------------------------------------------- evaluator

    private fun finite(
        value: Double,
        what: String = "Ergebnis",
    ): Double {
        if (value.isNaN() || value.isInfinite()) {
            throw FormulaDomainException("$what: Ergebnis ist nicht endlich")
        }
        return value
    }

    private fun bool(b: Boolean) = if (b) 1.0 else 0.0

    private fun eval(
        node: Node,
        scope: Map<String, Double>,
    ): Double =
        when (node) {
            is Node.Num -> node.value
            is Node.Ident -> scope[node.name] ?: constants[node.name] ?: throw MissingVariableException(node.name)
            is Node.Neg -> -eval(node.operand, scope)
            is Node.Bin -> {
                val a = eval(node.left, scope)
                val b = eval(node.right, scope)
                when (node.op) {
                    T.PLUS -> finite(a + b)
                    T.MINUS -> finite(a - b)
                    T.STAR -> finite(a * b)
                    T.SLASH -> if (b == 0.0) throw DivisionByZeroException() else finite(a / b)
                    T.LT -> bool(a < b)
                    T.GT -> bool(a > b)
                    T.LE -> bool(a <= b)
                    T.GE -> bool(a >= b)
                    T.EQ -> bool(a == b)
                    T.NE -> bool(a != b)
                    else -> throw FormulaSyntaxException("Unbekannter Operator: ${node.op}")
                }
            }
            is Node.Call -> call(node.name, node.args, scope)
        }

    private fun call(
        name: String,
        args: List<Node>,
        scope: Map<String, Double>,
    ): Double {
        if (name == "if") {
            val cond = eval(args[0], scope)
            return eval(if (cond != 0.0) args[1] else args[2], scope)
        }
        val v = args.map { eval(it, scope) }
        return when (name) {
            "min" -> v.min()
            "max" -> v.max()
            "clamp" -> {
                if (v[1] > v[2]) {
                    throw FormulaDomainException("clamp: untere Grenze größer als obere Grenze")
                }
                v[0].coerceIn(v[1], v[2])
            }
            "abs" -> kotlin.math.abs(v[0])
            "pow" -> finite(v[0].pow(v[1]), "pow")
            "sqrt" -> {
                if (v[0] < 0) throw FormulaDomainException("sqrt: Argument darf nicht negativ sein")
                sqrt(v[0])
            }
            "ln" -> {
                if (v[0] <= 0) throw FormulaDomainException("ln: Argument muss größer als 0 sein")
                ln(v[0])
            }
            "log10" -> {
                if (v[0] <= 0) throw FormulaDomainException("log10: Argument muss größer als 0 sein")
                ln(v[0]) / ln(10.0)
            }
            "exp" -> finite(exp(v[0]), "exp")
            // Half away from zero, like Dart's roundToDouble().
            "round" -> if (v[0] < 0) -floor(-v[0] + 0.5) else floor(v[0] + 0.5)
            "floor" -> floor(v[0])
            "ceil" -> ceil(v[0])
            else -> throw UnknownFunctionException(name)
        }
    }
}
