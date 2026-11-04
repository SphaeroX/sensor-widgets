/// What exactly went wrong in a formula, independent of the UI language.
///
/// The app translates a kind with its [FormulaException.args] into the user's
/// language (`lib/l10n/formula_error_text.dart`); [FormulaException.message]
/// is the English text for logs and `toString`.
enum FormulaErrorKind {
  emptyFormula,
  unexpectedCharacter,
  unexpectedAssign,
  invalidNumber,
  unknownOperator,
  missingOpeningParen,
  missingOperator,
  incompleteExpression,
  unclosedParen,
  invalidStepName,
  stepNameIsFunction,
  duplicateName,
  stepSelfReference,
  stepForwardReference,
  divisionByZero,
  missingVariable,
  unknownFunction,
  wrongArgumentCount,
  clampBounds,
  sqrtNegative,
  lnNonPositive,
  log10NonPositive,
  notFinite,
  noFormula,
  noVariables,
}

/// Base exception for formula evaluation errors.
///
/// [code] is the stable, cross-platform error code that is also used in
/// `fixtures/formula/evaluator_cases.json` (`expected_error`).
abstract class FormulaException implements Exception {
  final FormulaErrorKind kind;

  /// Values inserted into the message, in the order of [kind]'s text.
  final List<String> args;

  const FormulaException(this.kind, [this.args = const []]);

  String get code;

  /// English description (logs, `toString`); the UI shows a translated text.
  String get message => englishFormulaMessage(kind, args);

  @override
  String toString() => message;
}

/// Thrown when the formula contains invalid syntax (e.g. mismatched parentheses, bad operators).
class FormulaSyntaxException extends FormulaException {
  /// Zero-based character offset of the error in the expression, if known.
  final int? position;
  const FormulaSyntaxException(super.kind, [super.args, this.position]);

  @override
  String get code => 'syntax_error';
}

/// Thrown when an evaluation attempts to divide by zero.
class DivisionByZeroException extends FormulaException {
  const DivisionByZeroException() : super(FormulaErrorKind.divisionByZero);

  @override
  String get code => 'division_by_zero';
}

/// Thrown when a variable required by the formula is not provided or has null value.
class MissingVariableException extends FormulaException {
  final String variableName;
  MissingVariableException(this.variableName)
    : super(FormulaErrorKind.missingVariable, [variableName]);

  @override
  String get code => 'missing_variable';
}

/// Thrown when a call refers to a function that does not exist.
class UnknownFunctionException extends FormulaException {
  final String functionName;
  UnknownFunctionException(this.functionName, {this.position})
    : super(FormulaErrorKind.unknownFunction, [functionName]);

  final int? position;

  @override
  String get code => 'unknown_function';
}

/// Thrown when a function is called with an unsupported number of arguments.
class WrongArgumentCountException extends FormulaException {
  final String functionName;
  final int? position;

  /// [args]: function name, minimum, maximum ('' = unbounded), actual count.
  WrongArgumentCountException(
    this.functionName,
    int minArgs,
    int? maxArgs,
    int actual, {
    this.position,
  }) : super(FormulaErrorKind.wrongArgumentCount, [
         functionName,
         '$minArgs',
         maxArgs == null ? '' : '$maxArgs',
         '$actual',
       ]);

  @override
  String get code => 'wrong_arity';
}

/// Thrown when an operation is outside its mathematical domain
/// (e.g. `sqrt(-1)`, `ln(0)`) or yields a non-finite result.
class FormulaDomainException extends FormulaException {
  const FormulaDomainException(super.kind, [super.args]);

  @override
  String get code => 'domain_error';
}

/// Thrown when steps are invalid: duplicate or reserved names, forward
/// references or self references.
class StepReferenceException extends FormulaException {
  const StepReferenceException(super.kind, [super.args]);

  @override
  String get code => 'step_reference_error';
}

/// Zero-based error position of [e], if the parser knows it.
int? formulaErrorPosition(FormulaException e) => switch (e) {
  FormulaSyntaxException(:final position) => position,
  UnknownFunctionException(:final position) => position,
  WrongArgumentCountException(:final position) => position,
  _ => null,
};

/// English text of [kind] with [args] (see [FormulaErrorKind]).
String englishFormulaMessage(FormulaErrorKind kind, List<String> args) {
  String a(int i) => i < args.length ? args[i] : '';
  return switch (kind) {
    FormulaErrorKind.emptyFormula => 'Formula must not be empty',
    FormulaErrorKind.unexpectedCharacter => 'Unexpected character: "${a(0)}"',
    FormulaErrorKind.unexpectedAssign =>
      'Unexpected character: "=" (comparison: "==")',
    FormulaErrorKind.invalidNumber => 'Invalid number: ${a(0)}',
    FormulaErrorKind.unknownOperator => 'Unknown operator: ${a(0)}',
    FormulaErrorKind.missingOpeningParen => 'Missing opening parenthesis',
    FormulaErrorKind.missingOperator => 'Missing operator between operands',
    FormulaErrorKind.incompleteExpression => 'Incomplete expression',
    FormulaErrorKind.unclosedParen => 'Unclosed parenthesis',
    FormulaErrorKind.invalidStepName => 'Invalid step name: "${a(0)}"',
    FormulaErrorKind.stepNameIsFunction =>
      'Step name "${a(0)}" is a function name',
    FormulaErrorKind.duplicateName => 'Duplicate name: "${a(0)}"',
    FormulaErrorKind.stepSelfReference => 'Step "${a(0)}" refers to itself',
    FormulaErrorKind.stepForwardReference =>
      'Step refers to a later step "${a(0)}"',
    FormulaErrorKind.divisionByZero => 'Division by zero',
    FormulaErrorKind.missingVariable => 'Missing variable: ${a(0)}',
    FormulaErrorKind.unknownFunction => 'Unknown function: ${a(0)}',
    FormulaErrorKind.wrongArgumentCount =>
      'Function ${a(0)} expects ${_englishArity(a(1), a(2))} argument(s), '
          'got: ${a(3)}',
    FormulaErrorKind.clampBounds =>
      'clamp: lower bound greater than upper bound',
    FormulaErrorKind.sqrtNegative => 'sqrt: argument must not be negative',
    FormulaErrorKind.lnNonPositive => 'ln: argument must be greater than 0',
    FormulaErrorKind.log10NonPositive =>
      'log10: argument must be greater than 0',
    FormulaErrorKind.notFinite =>
      a(0).isEmpty ? 'Result is not finite' : '${a(0)}: result is not finite',
    FormulaErrorKind.noFormula => 'Widget has no formula',
    FormulaErrorKind.noVariables => 'No variables defined for the formula',
  };
}

String _englishArity(String min, String max) => max.isEmpty
    ? 'at least $min'
    : min == max
    ? min
    : '$min to $max';
