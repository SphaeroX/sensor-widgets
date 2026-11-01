/// Base exception for formula evaluation errors.
///
/// [code] is the stable, cross-platform error code that is also used in
/// `fixtures/formula/evaluator_cases.json` (`expected_error`).
abstract class FormulaException implements Exception {
  final String message;
  const FormulaException(this.message);

  String get code;

  @override
  String toString() => message;
}

/// Thrown when the formula contains invalid syntax (e.g. mismatched parentheses, bad operators).
class FormulaSyntaxException extends FormulaException {
  /// Zero-based character offset of the error in the expression, if known.
  final int? position;
  const FormulaSyntaxException(super.message, {this.position});

  @override
  String get code => 'syntax_error';
}

/// Thrown when an evaluation attempts to divide by zero.
class DivisionByZeroException extends FormulaException {
  const DivisionByZeroException([super.message = 'Division durch Null']);

  @override
  String get code => 'division_by_zero';
}

/// Thrown when a variable required by the formula is not provided or has null value.
class MissingVariableException extends FormulaException {
  final String variableName;
  const MissingVariableException(this.variableName)
    : super('Fehlende Variable: $variableName');

  @override
  String get code => 'missing_variable';
}

/// Thrown when a call refers to a function that does not exist.
class UnknownFunctionException extends FormulaException {
  final String functionName;
  const UnknownFunctionException(this.functionName, {this.position})
    : super('Unbekannte Funktion: $functionName');

  final int? position;

  @override
  String get code => 'unknown_function';
}

/// Thrown when a function is called with an unsupported number of arguments.
class WrongArgumentCountException extends FormulaException {
  final String functionName;
  final int? position;
  const WrongArgumentCountException(
    this.functionName,
    String expected,
    int actual, {
    this.position,
  }) : super(
         'Funktion $functionName erwartet $expected Argument(e), erhalten: $actual',
       );

  @override
  String get code => 'wrong_arity';
}

/// Thrown when an operation is outside its mathematical domain
/// (e.g. `sqrt(-1)`, `ln(0)`) or yields a non-finite result.
class FormulaDomainException extends FormulaException {
  const FormulaDomainException(super.message);

  @override
  String get code => 'domain_error';
}

/// Thrown when steps are invalid: duplicate or reserved names, forward
/// references or self references.
class StepReferenceException extends FormulaException {
  const StepReferenceException(super.message);

  @override
  String get code => 'step_reference_error';
}
