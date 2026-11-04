import 'package:sensor_widgets/domain/formula/formula_exception.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// Translates a formula error into the language of [l10n].
///
/// With [withPosition] the 1-based error position is appended where the
/// parser knows it (syntax errors in the editor).
String formulaErrorText(
  AppLocalizations l10n,
  FormulaException e, {
  bool withPosition = false,
}) {
  final text = _text(l10n, e.kind, e.args);
  final position = withPosition ? formulaErrorPosition(e) : null;
  return position == null
      ? text
      : l10n.formulaErrorAtPosition(text, position + 1);
}

/// Like [formulaErrorText] for any error: formula errors are translated,
/// everything else is shown as is.
String errorText(AppLocalizations l10n, Object error) =>
    error is FormulaException ? formulaErrorText(l10n, error) : '$error';

String _text(AppLocalizations l10n, FormulaErrorKind kind, List<String> args) {
  String a(int i) => i < args.length ? args[i] : '';
  return switch (kind) {
    FormulaErrorKind.emptyFormula => l10n.formulaErrorEmpty,
    FormulaErrorKind.unexpectedCharacter =>
      l10n.formulaErrorUnexpectedCharacter(a(0)),
    FormulaErrorKind.unexpectedAssign => l10n.formulaErrorUnexpectedAssign,
    FormulaErrorKind.invalidNumber => l10n.formulaErrorInvalidNumber(a(0)),
    FormulaErrorKind.unknownOperator => l10n.formulaErrorUnknownOperator(a(0)),
    FormulaErrorKind.missingOpeningParen =>
      l10n.formulaErrorMissingOpeningParen,
    FormulaErrorKind.missingOperator => l10n.formulaErrorMissingOperator,
    FormulaErrorKind.incompleteExpression => l10n.formulaErrorIncomplete,
    FormulaErrorKind.unclosedParen => l10n.formulaErrorUnclosedParen,
    FormulaErrorKind.invalidStepName => l10n.formulaErrorInvalidStepName(a(0)),
    FormulaErrorKind.stepNameIsFunction => l10n.formulaErrorStepNameIsFunction(
      a(0),
    ),
    FormulaErrorKind.duplicateName => l10n.formulaErrorDuplicateName(a(0)),
    FormulaErrorKind.stepSelfReference => l10n.formulaErrorStepSelfReference(
      a(0),
    ),
    FormulaErrorKind.stepForwardReference =>
      l10n.formulaErrorStepForwardReference(a(0)),
    FormulaErrorKind.divisionByZero => l10n.formulaErrorDivisionByZero,
    FormulaErrorKind.missingVariable => l10n.formulaErrorMissingVariable(a(0)),
    FormulaErrorKind.unknownFunction => l10n.formulaErrorUnknownFunction(a(0)),
    FormulaErrorKind.wrongArgumentCount => l10n.formulaErrorWrongArgumentCount(
      a(0),
      a(2).isEmpty
          ? l10n.formulaArityAtLeast(a(1))
          : a(1) == a(2)
          ? a(1)
          : l10n.formulaArityRange(a(1), a(2)),
      a(3),
    ),
    FormulaErrorKind.clampBounds => l10n.formulaErrorClampBounds,
    FormulaErrorKind.sqrtNegative => l10n.formulaErrorSqrtNegative,
    FormulaErrorKind.lnNonPositive => l10n.formulaErrorLnNonPositive,
    FormulaErrorKind.log10NonPositive => l10n.formulaErrorLog10NonPositive,
    FormulaErrorKind.notFinite =>
      a(0).isEmpty
          ? l10n.formulaErrorResultNotFinite
          : l10n.formulaErrorNotFinite(a(0)),
    FormulaErrorKind.noFormula => l10n.formulaErrorNoFormula,
    FormulaErrorKind.noVariables => l10n.formulaErrorNoVariables,
  };
}
