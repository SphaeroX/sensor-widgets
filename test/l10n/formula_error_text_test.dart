import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/formula/formula_evaluator.dart';
import 'package:sensor_widgets/domain/formula/formula_exception.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/l10n/formula_error_text.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _de = lookupAppLocalizations(const Locale('de'));

FormulaException _caught(void Function() run) {
  try {
    run();
  } on FormulaException catch (e) {
    return e;
  }
  fail('no FormulaException thrown');
}

void main() {
  test('division by zero in both languages', () {
    final e = _caught(() => FormulaEvaluator.evaluate('1 / 0', const {}));
    expect(formulaErrorText(_en, e), 'Division by zero');
    expect(formulaErrorText(_de, e), 'Division durch Null');
  });

  test('syntax errors carry the 1-based position when asked', () {
    final e = FormulaEvaluator.syntaxError('A + * B')!;
    expect(
      formulaErrorText(_de, e, withPosition: true),
      contains('Position 5'),
    );
    expect(
      formulaErrorText(_en, e, withPosition: true),
      contains('position 5'),
    );
    expect(formulaErrorText(_de, e), isNot(contains('Position')));
  });

  test('wrong argument count spells the arity per language', () {
    final atLeast = FormulaEvaluator.syntaxError('min()')!;
    expect(formulaErrorText(_en, atLeast), contains('at least 1'));
    expect(formulaErrorText(_de, atLeast), contains('mindestens 1'));
    final exact = FormulaEvaluator.syntaxError('sqrt(1, 2)')!;
    expect(formulaErrorText(_de, exact), contains('erwartet 1 Argument(e)'));
  });

  test('step errors are translated with the step name', () {
    final e = FormulaEvaluator.stepsError(
      const [
        FormulaStep(name: 's1', expression: 's2 + 1'),
        FormulaStep(name: 's2', expression: 'a'),
      ],
      'a',
      variableNames: const ['a'],
    )!;
    expect(
      formulaErrorText(_de, e),
      'Schritt verweist auf später definierten Schritt "s2"',
    );
    expect(formulaErrorText(_en, e), 'Step refers to a later step "s2"');
  });

  test('every error kind has a non-empty text in every language', () {
    for (final l10n in [_en, _de]) {
      for (final kind in FormulaErrorKind.values) {
        final text = formulaErrorText(
          l10n,
          FormulaSyntaxException(kind, const ['x', '1', '2', '3']),
        );
        expect(text.trim(), isNotEmpty, reason: '$kind');
      }
    }
  });

  test('domain message stays English for logs', () {
    final e = _caught(() => FormulaEvaluator.evaluate('sqrt(0 - 1)', const {}));
    expect(e.message, 'sqrt: argument must not be negative');
    expect(e.code, 'domain_error');
  });
}
