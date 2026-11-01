import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/sensor_query_item.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';

void main() {
  group('SensorQueryItem formula fields', () {
    const item = SensorQueryItem(
      field: 'iaq',
      label: 'IAQ',
      formula: 'min(a, b)',
      formulaVariables: [
        FormulaVariable(name: 'a', field: 'voc'),
        FormulaVariable(name: 'b', field: 'co2', measurement: 'air'),
      ],
      formulaSteps: [FormulaStep(name: 'x', expression: 'a * 2')],
    );

    test('json roundtrip keeps formula, variables and steps', () {
      expect(SensorQueryItem.fromJson(item.toJson()), item);
    });

    test('old json without formula fields parses unchanged', () {
      final plain = SensorQueryItem.fromJson({'field': 'temp', 'label': 'T'});
      expect(plain.formula, isNull);
      expect(plain.formulaVariables, isNull);
      expect(plain.formulaSteps, isNull);
      expect(plain.toJson(), {'field': 'temp', 'label': 'T'});
    });
  });

  group('WidgetDefinition.isValid with item formulas', () {
    WidgetDefinition multi(SensorQueryItem item) => WidgetDefinition(
      id: 'w',
      type: WidgetType.multiValue,
      title: 'Room',
      connectionId: 'c',
      measurement: 'm',
      items: [
        const SensorQueryItem(field: 'temp'),
        item,
      ],
    );

    test('accepts a valid row formula', () {
      expect(
        multi(
          const SensorQueryItem(
            field: 'iaq',
            formula: 'a / 2',
            formulaVariables: [FormulaVariable(name: 'a', field: 'voc')],
          ),
        ).isValid,
        isTrue,
      );
    });

    test('rejects a row formula without variables', () {
      expect(
        multi(const SensorQueryItem(field: 'iaq', formula: 'a / 2')).isValid,
        isFalse,
      );
    });

    test('rejects a row formula with a syntax error', () {
      expect(
        multi(
          const SensorQueryItem(
            field: 'iaq',
            formula: 'a /',
            formulaVariables: [FormulaVariable(name: 'a', field: 'voc')],
          ),
        ).isValid,
        isFalse,
      );
    });
  });
}
