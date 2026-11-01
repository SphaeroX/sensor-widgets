package io.github.mgasc.influx_sensor_widgets.formula

sealed class FormulaException(
    message: String,
) : Exception(message)

class FormulaSyntaxException(
    message: String,
) : FormulaException(message)

class DivisionByZeroException(
    message: String = "Division durch Null",
) : FormulaException(message)

class MissingVariableException(
    val variableName: String,
) : FormulaException("Fehlende Variable: $variableName")
