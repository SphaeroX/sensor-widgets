import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/threshold_rule.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';

void main() {
  group('WidgetDefinition & Schema v1', () {
    test('parses all 6 widget types from fixtures/widget_definitions/widget_definitions_v1.json', () {
      final file = File(
        'fixtures/widget_definitions/widget_definitions_v1.json',
      );
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> data =
          json.decode(jsonString) as Map<String, dynamic>;

      expect(data['schemaVersion'], 1);
      final rawWidgets = data['widgets'] as List<dynamic>;
      expect(rawWidgets.length, 6);

      final widgets = rawWidgets
          .map((w) => WidgetDefinition.fromJson(w as Map<String, dynamic>))
          .toList();

      // 1. single_value
      final singleVal = widgets[0];
      expect(singleVal.id, 'widget-1-single-value');
      expect(singleVal.type, WidgetType.singleValue);
      expect(singleVal.title, 'Living Room Temp');
      expect(singleVal.field, 'value');
      expect(singleVal.unit, '°C');
      expect(singleVal.decimalPlaces, 1);

      // 2. history_chart
      final history = widgets[1];
      expect(history.id, 'widget-2-history-chart');
      expect(history.type, WidgetType.historyChart);
      expect(history.timeRange, '24h');
      expect(history.aggregationInterval, '1h');

      // 3. indicator_lamp
      final lamp = widgets[2];
      expect(lamp.id, 'widget-3-indicator-lamp');
      expect(lamp.type, WidgetType.indicatorLamp);
      expect(lamp.threshold?.operator, ThresholdOperator.greaterThan);
      expect(lamp.threshold?.value, 1000.0);

      // 4. multi_value
      final multi = widgets[3];
      expect(multi.id, 'widget-4-multi-value');
      expect(multi.type, WidgetType.multiValue);
      expect(multi.items?.length, 3);
      expect(multi.items?[0].field, 'temperature');
      expect(multi.items?[1].field, 'humidity');
      expect(multi.items?[2].field, 'co2');

      // 5. aggregate
      final agg = widgets[4];
      expect(agg.id, 'widget-5-aggregate');
      expect(agg.type, WidgetType.aggregate);
      expect(agg.aggregateFunction, 'max');

      // 6. gauge_bar
      final gauge = widgets[5];
      expect(gauge.id, 'widget-6-gauge-bar');
      expect(gauge.type, WidgetType.gaugeBar);
      expect(gauge.min, 0.0);
      expect(gauge.max, 100.0);
      expect(gauge.thresholds?.length, 3);

      // Roundtrip check
      for (var i = 0; i < widgets.length; i++) {
        final serialized = widgets[i].toJson();
        final deserialized = WidgetDefinition.fromJson(serialized);
        expect(deserialized.id, widgets[i].id);
        expect(deserialized.type, widgets[i].type);
        expect(deserialized.title, widgets[i].title);
      }
    });

    test('validates required fields', () {
      const valid = WidgetDefinition(
        id: 'w-1',
        type: WidgetType.singleValue,
        title: 'Title',
        connectionId: 'c-1',
        measurement: 'temp',
        field: 'val',
      );
      expect(valid.isValid, isTrue);

      const emptyTitle = WidgetDefinition(
        id: 'w-2',
        type: WidgetType.singleValue,
        title: '',
        connectionId: 'c-1',
        measurement: 'temp',
        field: 'val',
      );
      expect(emptyTitle.isValid, isFalse);

      const missingFieldSingle = WidgetDefinition(
        id: 'w-3',
        type: WidgetType.singleValue,
        title: 'Title',
        connectionId: 'c-1',
        measurement: 'temp',
      );
      expect(missingFieldSingle.isValid, isFalse);
    });
  });
}
