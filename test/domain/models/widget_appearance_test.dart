import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/widget_appearance.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';

void main() {
  group('WidgetAppearance', () {
    const full = WidgetAppearance(
      backgroundColor: '#102030',
      backgroundOpacity: 0.5,
      textColor: '#FFEEAA',
      accentColor: '#33CC99',
      fontScale: 1.2,
      cornerRadius: 24,
    );

    test('json roundtrip', () {
      expect(WidgetAppearance.fromJson(full.toJson()), full);
    });

    test('empty json gives an empty appearance and omits nulls', () {
      final a = WidgetAppearance.fromJson({});
      expect(a.isEmpty, isTrue);
      expect(a.toJson(), isEmpty);
      expect(const WidgetAppearance(accentColor: '#FF5722').toJson(), {
        'accentColor': '#FF5722',
      });
    });

    test('exposes documented defaults', () {
      expect(WidgetAppearance.defaultBackgroundOpacity, 1.0);
      expect(WidgetAppearance.defaultFontScale, 1.0);
      expect(WidgetAppearance.defaultCornerRadius, 16.0);
    });

    test('isValid checks colors and ranges', () {
      expect(full.isValid, isTrue);
      expect(const WidgetAppearance().isValid, isTrue);
      expect(const WidgetAppearance(textColor: 'nope').isValid, isFalse);
      expect(const WidgetAppearance(backgroundOpacity: 1.5).isValid, isFalse);
      expect(const WidgetAppearance(fontScale: 0.1).isValid, isFalse);
      expect(const WidgetAppearance(fontScale: 3).isValid, isFalse);
      expect(const WidgetAppearance(cornerRadius: -1).isValid, isFalse);
      expect(const WidgetAppearance(cornerRadius: 100).isValid, isFalse);
    });

    test('copyWith can set and clear single values', () {
      expect(full.copyWith(fontScale: 1.4).fontScale, 1.4);
      expect(full.copyWith(clearTextColor: true).textColor, isNull);
      expect(full.copyWith(clearTextColor: true).accentColor, '#33CC99');
    });
  });

  group('WidgetDefinition.appearance (shared fixture)', () {
    final widgets =
        ((json.decode(
                  File(
                    'fixtures/widget_definitions/widget_definition_appearance.json',
                  ).readAsStringSync(),
                ) as Map<String, dynamic>)['widgets']
                as List<dynamic>)
            .map((e) => WidgetDefinition.fromJson(e as Map<String, dynamic>))
            .toList();

    test('parses every value', () {
      final a = widgets[0].appearance!;
      expect(a.backgroundColor, '#102030');
      expect(a.backgroundOpacity, 0.5);
      expect(a.textColor, '#FFEEAA');
      expect(a.accentColor, '#33CC99');
      expect(a.fontScale, 1.2);
      expect(a.cornerRadius, 24.0);
    });

    test('old definitions have no appearance and do not serialize it', () {
      expect(widgets[1].appearance, isNull);
      expect(widgets[1].toJson().containsKey('appearance'), isFalse);
    });

    test('partial appearance keeps other values unset', () {
      expect(widgets[2].appearance!.accentColor, '#FF5722');
      expect(widgets[2].appearance!.backgroundColor, isNull);
    });

    test('roundtrip, copyWith and validation', () {
      final w = widgets[0];
      expect(WidgetDefinition.fromJson(w.toJson()).appearance, w.appearance);
      expect(w.copyWith(title: 'x').appearance, w.appearance);
      const bad = WidgetDefinition(
        id: 'b',
        type: WidgetType.singleValue,
        title: 't',
        connectionId: 'c',
        measurement: 'm',
        field: 'f',
        appearance: WidgetAppearance(backgroundColor: 'zzz'),
      );
      expect(bad.isValid, isFalse);
    });
  });
}
