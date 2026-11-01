import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';

void main() {
  group('FormulaVariable', () {
    test('creates with required name and field', () {
      const variable = FormulaVariable(name: 'A', field: 'temperature');
      expect(variable.name, 'A');
      expect(variable.field, 'temperature');
      expect(variable.measurement, isNull);
      expect(variable.tagFilters, isNull);
      expect(variable.label, isNull);
    });

    test('serializes and deserializes from/to JSON', () {
      const variable = FormulaVariable(
        name: 'B',
        field: 'humidity',
        measurement: 'weather',
        tagFilters: {'room': 'living'},
        label: 'Living Humidity',
      );

      final json = variable.toJson();
      expect(json, {
        'name': 'B',
        'field': 'humidity',
        'measurement': 'weather',
        'tagFilters': {'room': 'living'},
        'label': 'Living Humidity',
      });

      final fromJson = FormulaVariable.fromJson(json);
      expect(fromJson, variable);
    });

    test('equality and hashCode', () {
      const v1 = FormulaVariable(
        name: 'A',
        field: 'temp',
        tagFilters: {'sensor': '1'},
      );
      const v2 = FormulaVariable(
        name: 'A',
        field: 'temp',
        tagFilters: {'sensor': '1'},
      );
      const v3 = FormulaVariable(
        name: 'A',
        field: 'temp',
        tagFilters: {'sensor': '2'},
      );

      expect(v1, equals(v2));
      expect(v1.hashCode, equals(v2.hashCode));
      expect(v1, isNot(equals(v3)));
    });
  });
}
