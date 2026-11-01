import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';

WidgetDefinition _widget({
  String? formula,
  List<FormulaStep>? steps,
  List<FormulaVariable>? variables,
}) => WidgetDefinition(
  id: 'w-1',
  type: WidgetType.singleValue,
  title: 'IAQ',
  connectionId: 'c-1',
  measurement: 'sen66',
  formula: formula,
  formulaVariables: variables,
  formulaSteps: steps,
);

void main() {
  group('WidgetDefinition.formulaSteps', () {
    const vars = [FormulaVariable(name: 'a', field: 'voc')];

    test('json roundtrip', () {
      final w = _widget(
        formula: 'idx',
        variables: vars,
        steps: const [FormulaStep(name: 'idx', expression: '100 - a')],
      );
      final json = w.toJson();
      expect((json['formulaSteps'] as List).length, 1);
      expect(WidgetDefinition.fromJson(json).formulaSteps, w.formulaSteps);
    });

    test('old json without formulaSteps parses to null', () {
      final w = WidgetDefinition.fromJson(
        _widget(formula: 'a', variables: vars).toJson(),
      );
      expect(w.formulaSteps, isNull);
      expect(w.toJson().containsKey('formulaSteps'), isFalse);
    });

    test('copyWith keeps and replaces steps', () {
      final w = _widget(
        formula: 'idx',
        variables: vars,
        steps: const [FormulaStep(name: 'idx', expression: 'a')],
      );
      expect(w.copyWith(title: 'x').formulaSteps, w.formulaSteps);
      expect(w.copyWith(formulaSteps: const []).formulaSteps, isEmpty);
    });

    test('isValid rejects invalid formula and invalid steps', () {
      expect(_widget(formula: 'a + ', variables: vars).isValid, isFalse);
      expect(
        _widget(
          formula: 's1',
          variables: vars,
          steps: const [FormulaStep(name: 's1', expression: 's2')],
        ).isValid,
        isFalse,
      );
      expect(
        _widget(
          formula: 's1',
          variables: vars,
          steps: const [FormulaStep(name: 's1', expression: 'a * 2')],
        ).isValid,
        isTrue,
      );
    });
  });
}
