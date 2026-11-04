package io.github.sphaerox.influx_sensor_widgets.formula

/**
 * Base of all formula errors. [code] is the stable cross-platform error code
 * used as `expected_error` in `fixtures/formula/evaluator_cases.json`.
 */
sealed class FormulaException(
    message: String,
    val code: String,
) : Exception(message)

class FormulaSyntaxException(
    message: String,
    val position: Int? = null,
) : FormulaException(message, "syntax_error")

class DivisionByZeroException(
    message: String = "Division durch Null",
) : FormulaException(message, "division_by_zero")

class MissingVariableException(
    val variableName: String,
) : FormulaException("Fehlende Variable: $variableName", "missing_variable")

class UnknownFunctionException(
    val functionName: String,
    val position: Int? = null,
) : FormulaException("Unbekannte Funktion: $functionName", "unknown_function")

class WrongArgumentCountException(
    val functionName: String,
    expected: String,
    actual: Int,
    val position: Int? = null,
) : FormulaException(
        "Funktion $functionName erwartet $expected Argument(e), erhalten: $actual",
        "wrong_arity",
    )

class FormulaDomainException(
    message: String,
) : FormulaException(message, "domain_error")

class StepReferenceException(
    message: String,
) : FormulaException(message, "step_reference_error")
