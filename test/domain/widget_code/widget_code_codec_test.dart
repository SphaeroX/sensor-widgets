import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/domain/widget_code/widget_code_codec.dart';

void main() {
  const base = WidgetDefinition(
    id: 'w1',
    type: WidgetType.singleValue,
    title: 'Alt',
    connectionId: 'c1',
    measurement: 'sen66',
  );

  const iaq = WidgetDefinition(
    id: 'w1',
    type: WidgetType.historyChart,
    title: 'IAQ',
    connectionId: 'c1',
    measurement: 'sen66',
    timeRange: '24h',
    aggregationInterval: '1h',
    formula: 'min(s_co2, s_rh)',
    formulaSteps: [
      FormulaStep(
        name: 's_co2',
        expression: 'clamp(100 * (2000 - co2) / 1400, 0, 100)',
      ),
      FormulaStep(
        name: 's_rh',
        expression: 'clamp(100 - abs(rh - 50) * 3, 0, 100)',
      ),
    ],
    formulaVariables: [
      FormulaVariable(name: 'co2', field: 'co2'),
      FormulaVariable(name: 'rh', field: 'humidity'),
    ],
  );

  group('encode', () {
    test('omits id and connectionId and is pretty printed JSON', () {
      final code = WidgetCodeCodec.encode(iaq);
      final map = jsonDecode(code) as Map<String, dynamic>;
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('connectionId'), isFalse);
      expect(map['type'], 'history_chart');
      expect(map['formula'], 'min(s_co2, s_rh)');
      expect(code, contains('\n  '));
    });
  });

  group('decode', () {
    test('round trips and keeps id and connection of the base', () {
      final result = WidgetCodeCodec.decode(
        WidgetCodeCodec.encode(iaq),
        base: base,
      );
      expect(result.errors, isEmpty);
      final def = result.definition!;
      expect(def.id, 'w1');
      expect(def.connectionId, 'c1');
      expect(def.type, WidgetType.historyChart);
      expect(def.formulaSteps, iaq.formulaSteps);
      expect(def.formulaVariables, iaq.formulaVariables);
    });

    test('ignores id and connectionId written in the code', () {
      final result = WidgetCodeCodec.decode(
        '{"id":"evil","connectionId":"other","type":"single_value",'
        '"formula":"A*2","formulaVariables":[{"name":"A","field":"x"}]}',
        base: base,
      );
      expect(result.definition!.id, 'w1');
      expect(result.definition!.connectionId, 'c1');
    });

    test('falls back to measurement and title of the base', () {
      final result = WidgetCodeCodec.decode(
        '{"type":"single_value","formula":"A","formulaVariables":'
        '[{"name":"A","field":"x"}]}',
        base: base,
      );
      expect(result.definition!.measurement, 'sen66');
      expect(result.definition!.title, 'Alt');
    });

    test('accepts a markdown code fence around the JSON', () {
      final result = WidgetCodeCodec.decode(
        '```json\n{"type":"single_value","formula":"A","formulaVariables":'
        '[{"name":"A","field":"x"}]}\n```',
        base: base,
      );
      expect(result.errors, isEmpty);
    });

    test('reports invalid JSON', () {
      final result = WidgetCodeCodec.decode('{nope', base: base);
      expect(result.definition, isNull);
      expect(result.errors.single, contains('JSON'));
    });

    test('reports unknown widget type', () {
      final result = WidgetCodeCodec.decode('{"type":"pie"}', base: base);
      expect(result.errors.single, contains('pie'));
    });

    test('reports formula syntax errors', () {
      final result = WidgetCodeCodec.decode(
        '{"type":"single_value","formula":"A +","formulaVariables":'
        '[{"name":"A","field":"x"}]}',
        base: base,
      );
      expect(result.definition, isNull);
      expect(result.errors.single, contains('Formel'));
    });

    test('reports undefined variables', () {
      final result = WidgetCodeCodec.decode(
        '{"type":"single_value","formula":"A + B","formulaVariables":'
        '[{"name":"A","field":"x"}]}',
        base: base,
      );
      expect(result.errors.join(), contains('B'));
    });

    test('reports variables without a field', () {
      final result = WidgetCodeCodec.decode(
        '{"type":"single_value","formula":"A","formulaVariables":'
        '[{"name":"A","field":""}]}',
        base: base,
      );
      expect(result.errors.join(), contains('Feld'));
    });

    test('reports wrongly typed values instead of throwing', () {
      final result = WidgetCodeCodec.decode(
        '{"type":"single_value","refreshIntervalMinutes":"viel"}',
        base: base,
      );
      expect(result.definition, isNull);
      expect(result.errors, isNotEmpty);
    });

    test('validates formulas of multi value rows', () {
      final result = WidgetCodeCodec.decode(
        '{"type":"multi_value","items":[{"field":"f1","label":"X",'
        '"formula":"A/","formulaVariables":[{"name":"A","field":"x"}]}]}',
        base: base,
      );
      expect(result.definition, isNull);
      expect(result.errors.join(), contains('X'));
    });

    test('does not require connection or title of an unsaved widget', () {
      const fresh = WidgetDefinition(
        id: 'n',
        type: WidgetType.singleValue,
        title: '',
        connectionId: '',
        measurement: 'm',
      );
      final result = WidgetCodeCodec.decode(
        '{"type":"single_value","field":"temp"}',
        base: fresh,
      );
      expect(result.errors, isEmpty);
      expect(result.definition!.title, isNotEmpty);
    });

    test('rejects a widget without formula and without field', () {
      final result = WidgetCodeCodec.decode(
        '{"type":"single_value"}',
        base: base,
      );
      expect(result.definition, isNull);
      expect(result.errors, isNotEmpty);
    });
  });
}
