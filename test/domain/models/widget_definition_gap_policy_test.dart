import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';

WidgetDefinition _widget({String? gapPolicy}) => WidgetDefinition(
  id: 'w',
  type: WidgetType.historyChart,
  title: 'IAQ',
  connectionId: 'c',
  measurement: 'm',
  formula: 'a',
  formulaVariables: const [FormulaVariable(name: 'a', field: 'f')],
  gapPolicy: gapPolicy,
);

void main() {
  group('WidgetDefinition.gapPolicy', () {
    test('json roundtrip and omitted when null', () {
      expect(
        WidgetDefinition.fromJson(_widget(gapPolicy: 'previous').toJson())
            .gapPolicy,
        'previous',
      );
      expect(_widget().toJson().containsKey('gapPolicy'), isFalse);
    });

    test('copyWith keeps value', () {
      expect(_widget(gapPolicy: 'skip').copyWith(title: 'x').gapPolicy, 'skip');
    });

    test('isValid accepts skip, previous and null only', () {
      expect(_widget().isValid, isTrue);
      expect(_widget(gapPolicy: 'skip').isValid, isTrue);
      expect(_widget(gapPolicy: 'previous').isValid, isTrue);
      expect(_widget(gapPolicy: 'zero').isValid, isFalse);
    });
  });
}
