import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/alert_rule.dart';
import 'package:sensor_widgets/domain/models/threshold_rule.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';

void main() {
  group('AlertRule', () {
    test('round-trips through json', () {
      const rule = AlertRule(
        target: 'co2',
        operator: ThresholdOperator.greaterThan,
        value: 1000,
      );

      final json = rule.toJson();

      expect(json, {'target': 'co2', 'operator': 'greaterThan', 'value': 1000});
      expect(AlertRule.fromJson(json), rule);
    });

    test('isValid needs a target and a finite value', () {
      expect(
        const AlertRule(
          target: 'value',
          operator: ThresholdOperator.lessThan,
          value: 3,
        ).isValid,
        isTrue,
      );
      expect(
        const AlertRule(
          target: ' ',
          operator: ThresholdOperator.lessThan,
          value: 3,
        ).isValid,
        isFalse,
      );
      expect(
        const AlertRule(
          target: 'value',
          operator: ThresholdOperator.lessThan,
          value: double.nan,
        ).isValid,
        isFalse,
      );
    });
  });

  group('WidgetDefinition.alerts (shared fixture)', () {
    late List<WidgetDefinition> widgets;

    setUpAll(() {
      final raw = jsonDecode(
        File('fixtures/widget_definitions/widget_definition_alerts.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      widgets = (raw['widgets'] as List<dynamic>)
          .map((e) => WidgetDefinition.fromJson(e as Map<String, dynamic>))
          .toList();
    });

    test('formula widget alerts on the calculated value', () {
      expect(widgets[0].alerts, const [
        AlertRule(
          target: AlertRule.targetValue,
          operator: ThresholdOperator.greaterThan,
          value: 150,
        ),
      ]);
    });

    test('multi value widget has one rule per row', () {
      expect(widgets[1].alerts!.map((a) => a.target), ['co2', 'temp']);
      expect(widgets[1].alerts![1].operator, ThresholdOperator.lessThan);
      expect(widgets[1].alerts![1].value, 18.5);
    });

    test('old definitions have no alerts and do not serialize them', () {
      expect(widgets[2].alerts, isNull);
      expect(widgets[2].toJson().containsKey('alerts'), isFalse);
    });

    test('alerts survive toJson, fromJson and copyWith', () {
      final w = widgets[1];
      expect(WidgetDefinition.fromJson(w.toJson()).alerts, w.alerts);
      expect(w.copyWith(title: 'x').alerts, w.alerts);
    });

    test('an invalid rule makes the definition invalid', () {
      final w = widgets[0].copyWith(
        alerts: const [
          AlertRule(
            target: '',
            operator: ThresholdOperator.greaterThan,
            value: 1,
          ),
        ],
      );
      expect(w.isValid, isFalse);
    });
  });
}
