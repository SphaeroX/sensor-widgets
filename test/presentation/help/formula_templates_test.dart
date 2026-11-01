import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/formula/formula_evaluator.dart';
import 'package:sensor_widgets/presentation/help/formula_help_content.dart';

FormulaTemplate _template(String id) =>
    formulaTemplates.firstWhere((t) => t.id == id);

double _eval(FormulaTemplate t, Map<String, double> values) =>
    FormulaEvaluator.evaluate(t.formula, values, steps: t.steps);

void main() {
  group('formula templates', () {
    test('every template is syntactically valid and self-consistent', () {
      expect(formulaTemplates, isNotEmpty);
      for (final t in formulaTemplates) {
        final names = t.variables.map((v) => v.name).toList();
        expect(t.title, isNotEmpty);
        expect(t.description, isNotEmpty);
        expect(
          FormulaEvaluator.validateSteps(
            t.steps,
            t.formula,
            variableNames: names,
          ),
          isNull,
          reason: 'Template ${t.id} is invalid',
        );
      }
    });

    test('template ids are unique', () {
      final ids = formulaTemplates.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    group('IAQ (Sensirion SEN66)', () {
      final iaq = _template('iaq_sen66');

      test('uses the four documented variables and steps', () {
        expect(iaq.variables.map((v) => v.name), ['co2', 'voc', 'pm25', 'rh']);
        expect(iaq.steps.map((s) => s.name), [
          's_co2',
          's_voc',
          's_pm25',
          's_rh',
        ]);
        expect(iaq.formula, 'min(s_co2, s_voc, s_pm25, s_rh)');
      });

      test('perfect air gives 100', () {
        expect(_eval(iaq, {'co2': 600, 'voc': 100, 'pm25': 5, 'rh': 50}), 100);
      });

      test('all sub scores at 50 give 50', () {
        expect(
          _eval(iaq, {'co2': 1300, 'voc': 175, 'pm25': 20, 'rh': 35}),
          closeTo(50, 1e-9),
        );
      });

      test('the worst sub score decides the result', () {
        // Only PM2.5 is bad (35 ug/m3 -> score 0), everything else is perfect.
        expect(_eval(iaq, {'co2': 600, 'voc': 100, 'pm25': 35, 'rh': 50}), 0);
        // Only humidity is mediocre (65 % -> 50).
        expect(
          _eval(iaq, {'co2': 600, 'voc': 100, 'pm25': 5, 'rh': 65}),
          closeTo(50, 1e-9),
        );
      });

      test('scores are clamped to 0..100', () {
        expect(_eval(iaq, {'co2': 5000, 'voc': 100, 'pm25': 5, 'rh': 50}), 0);
        expect(_eval(iaq, {'co2': 400, 'voc': 1, 'pm25': 0, 'rh': 50}), 100);
      });
    });

    test('celsius to fahrenheit template converts correctly', () {
      expect(_eval(_template('celsius_to_fahrenheit'), {'temp': 25}), 77);
    });

    test('average template averages two sensors', () {
      expect(_eval(_template('average_two'), {'a': 20, 'b': 24}), 22);
    });
  });
}
