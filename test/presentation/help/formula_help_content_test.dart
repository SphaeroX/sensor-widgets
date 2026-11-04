import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/formula/formula_evaluator.dart';
import 'package:sensor_widgets/presentation/help/formula_help_content.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The tests assert the German texts.
final _de = lookupAppLocalizations(const Locale('de'));

void main() {
  group('formula help content', () {
    test('every evaluator function has a help entry', () {
      final documented = formulaHelpEntries(_de).map((e) => e.name).toSet();
      for (final fn in FormulaEvaluator.functionNames) {
        expect(
          documented,
          contains(fn),
          reason: 'Function $fn is undocumented',
        );
      }
    });

    test('constants and the if() condition are documented', () {
      final documented = formulaHelpEntries(_de).map((e) => e.name).toSet();
      expect(documented, containsAll(['pi', 'e', 'if']));
    });

    test('every example is a valid formula that yields the shown result', () {
      for (final e in formulaHelpEntries(_de)) {
        expect(e.description, isNotEmpty, reason: e.name);
        expect(e.example, isNotEmpty, reason: e.name);
        expect(
          FormulaEvaluator.evaluate(e.example, const {}),
          closeTo(e.exampleResult, 1e-9),
          reason: 'Example of ${e.name}: ${e.example}',
        );
      }
    });

    test('sections explain variables, steps and error messages', () {
      final titles = formulaHelpSections(_de).map((s) => s.title).toList();
      expect(titles, containsAll(['Variablen', 'Zwischenschritte', 'Fehler']));
      for (final s in formulaHelpSections(_de)) {
        expect(s.body, isNotEmpty);
      }
    });
  });
}
