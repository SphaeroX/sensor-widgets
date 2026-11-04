package io.github.sphaerox.influx_sensor_widgets.formula

/**
 * What exactly went wrong in a formula, independent of the UI language.
 * `l10n/FormulaErrorText` translates a kind with its [FormulaException.args];
 * [FormulaException.message] is the English text for logs.
 */
enum class FormulaErrorKind {
    EMPTY_FORMULA,
    UNEXPECTED_CHARACTER,
    UNEXPECTED_ASSIGN,
    INVALID_NUMBER,
    UNKNOWN_OPERATOR,
    MISSING_OPENING_PAREN,
    MISSING_OPERATOR,
    INCOMPLETE_EXPRESSION,
    UNCLOSED_PAREN,
    INVALID_STEP_NAME,
    STEP_NAME_IS_FUNCTION,
    DUPLICATE_NAME,
    STEP_SELF_REFERENCE,
    STEP_FORWARD_REFERENCE,
    DIVISION_BY_ZERO,
    MISSING_VARIABLE,
    UNKNOWN_FUNCTION,
    WRONG_ARGUMENT_COUNT,
    CLAMP_BOUNDS,
    SQRT_NEGATIVE,
    LN_NON_POSITIVE,
    LOG10_NON_POSITIVE,
    NOT_FINITE,
    NO_FORMULA,
}

/**
 * Base of all formula errors. [code] is the stable cross-platform error code
 * used as `expected_error` in `fixtures/formula/evaluator_cases.json`.
 */
sealed class FormulaException(
    val kind: FormulaErrorKind,
    val args: List<String>,
    val code: String,
) : Exception(englishFormulaMessage(kind, args))

class FormulaSyntaxException(
    kind: FormulaErrorKind,
    args: List<String> = emptyList(),
    val position: Int? = null,
) : FormulaException(kind, args, "syntax_error")

class DivisionByZeroException : FormulaException(FormulaErrorKind.DIVISION_BY_ZERO, emptyList(), "division_by_zero")

class MissingVariableException(
    val variableName: String,
) : FormulaException(FormulaErrorKind.MISSING_VARIABLE, listOf(variableName), "missing_variable")

class UnknownFunctionException(
    val functionName: String,
    val position: Int? = null,
) : FormulaException(FormulaErrorKind.UNKNOWN_FUNCTION, listOf(functionName), "unknown_function")

/** [args]: function name, minimum, maximum ("" = unbounded), actual count. */
class WrongArgumentCountException(
    val functionName: String,
    minArgs: Int,
    maxArgs: Int?,
    actual: Int,
    val position: Int? = null,
) : FormulaException(
        FormulaErrorKind.WRONG_ARGUMENT_COUNT,
        listOf(functionName, "$minArgs", maxArgs?.toString() ?: "", "$actual"),
        "wrong_arity",
    )

class FormulaDomainException(
    kind: FormulaErrorKind,
    args: List<String> = emptyList(),
) : FormulaException(kind, args, "domain_error")

class StepReferenceException(
    kind: FormulaErrorKind,
    args: List<String> = emptyList(),
) : FormulaException(kind, args, "step_reference_error")

/** Zero-based error position, if the parser knows it. */
val FormulaException.errorPosition: Int?
    get() =
        when (this) {
            is FormulaSyntaxException -> position
            is UnknownFunctionException -> position
            is WrongArgumentCountException -> position
            else -> null
        }

/** English text of [kind] with [args] (logs and `Exception.message`). */
fun englishFormulaMessage(
    kind: FormulaErrorKind,
    args: List<String>,
): String {
    fun a(i: Int) = args.getOrElse(i) { "" }
    return when (kind) {
        FormulaErrorKind.EMPTY_FORMULA -> "Formula must not be empty"
        FormulaErrorKind.UNEXPECTED_CHARACTER -> "Unexpected character: \"${a(0)}\""
        FormulaErrorKind.UNEXPECTED_ASSIGN -> "Unexpected character: \"=\" (comparison: \"==\")"
        FormulaErrorKind.INVALID_NUMBER -> "Invalid number: ${a(0)}"
        FormulaErrorKind.UNKNOWN_OPERATOR -> "Unknown operator: ${a(0)}"
        FormulaErrorKind.MISSING_OPENING_PAREN -> "Missing opening parenthesis"
        FormulaErrorKind.MISSING_OPERATOR -> "Missing operator between operands"
        FormulaErrorKind.INCOMPLETE_EXPRESSION -> "Incomplete expression"
        FormulaErrorKind.UNCLOSED_PAREN -> "Unclosed parenthesis"
        FormulaErrorKind.INVALID_STEP_NAME -> "Invalid step name: \"${a(0)}\""
        FormulaErrorKind.STEP_NAME_IS_FUNCTION -> "Step name \"${a(0)}\" is a function name"
        FormulaErrorKind.DUPLICATE_NAME -> "Duplicate name: \"${a(0)}\""
        FormulaErrorKind.STEP_SELF_REFERENCE -> "Step \"${a(0)}\" refers to itself"
        FormulaErrorKind.STEP_FORWARD_REFERENCE -> "Step refers to a later step \"${a(0)}\""
        FormulaErrorKind.DIVISION_BY_ZERO -> "Division by zero"
        FormulaErrorKind.MISSING_VARIABLE -> "Missing variable: ${a(0)}"
        FormulaErrorKind.UNKNOWN_FUNCTION -> "Unknown function: ${a(0)}"
        FormulaErrorKind.WRONG_ARGUMENT_COUNT -> {
            val expected =
                when {
                    a(2).isEmpty() -> "at least ${a(1)}"
                    a(1) == a(2) -> a(1)
                    else -> "${a(1)} to ${a(2)}"
                }
            "Function ${a(0)} expects $expected argument(s), got: ${a(3)}"
        }
        FormulaErrorKind.CLAMP_BOUNDS -> "clamp: lower bound greater than upper bound"
        FormulaErrorKind.SQRT_NEGATIVE -> "sqrt: argument must not be negative"
        FormulaErrorKind.LN_NON_POSITIVE -> "ln: argument must be greater than 0"
        FormulaErrorKind.LOG10_NON_POSITIVE -> "log10: argument must be greater than 0"
        FormulaErrorKind.NOT_FINITE -> if (a(0).isEmpty()) "Result is not finite" else "${a(0)}: result is not finite"
        FormulaErrorKind.NO_FORMULA -> "Widget has no formula"
    }
}
