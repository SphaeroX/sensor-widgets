import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';

void main() {
  group('FormulaStep', () {
    test('json roundtrip keeps optional label', () {
      const step = FormulaStep(
        name: 'voc',
        expression: '100 - a * 0.6',
        label: 'VOC-Index',
      );
      expect(FormulaStep.fromJson(step.toJson()), step);
    });

    test('toJson omits null label', () {
      const step = FormulaStep(name: 'x', expression: 'a');
      expect(step.toJson(), {'name': 'x', 'expression': 'a'});
    });
  });
}
