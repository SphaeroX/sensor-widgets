/// Base exception for formula evaluation errors.
abstract class FormulaException implements Exception {
  final String message;
  const FormulaException(this.message);

  @override
  String toString() => message;
}

/// Thrown when the formula contains invalid syntax (e.g. mismatched parentheses, bad operators).
class FormulaSyntaxException extends FormulaException {
  const FormulaSyntaxException(super.message);
}

/// Thrown when an evaluation attempts to divide by zero.
class DivisionByZeroException extends FormulaException {
  const DivisionByZeroException([super.message = 'Division durch Null']);
}

/// Thrown when a variable required by the formula is not provided or has null value.
class MissingVariableException extends FormulaException {
  final String variableName;
  const MissingVariableException(this.variableName)
    : super('Fehlende Variable: $variableName');
}
