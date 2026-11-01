import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';

/// Widget JSONs written by milestones 1 to 3 must keep parsing and must not
/// gain any milestone 4 field when written back.
void main() {
  const milestone4Keys = [
    'formulaSteps',
    'gapPolicy',
    'chartStyle',
    'appearance',
  ];

  List<Map<String, dynamic>> load(String path) {
    final decoded = json.decode(File(path).readAsStringSync());
    final list = decoded is List
        ? decoded
        : (decoded as Map<String, dynamic>)['widgets'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  group('legacy widget definition fixtures', () {
    final legacy = load(
      'fixtures/widget_definitions/widget_definitions_v1.json',
    );

    test('are still valid and cover all six types', () {
      expect(legacy, hasLength(6));
      for (final raw in legacy) {
        final widget = WidgetDefinition.fromJson(raw);
        expect(widget.isValid, isTrue, reason: raw['id'] as String);
      }
      expect(legacy.map((w) => w['type']).toSet(), hasLength(6));
    });

    test('are written back without milestone 4 fields', () {
      for (final raw in legacy) {
        final out = WidgetDefinition.fromJson(raw).toJson();
        for (final key in milestone4Keys) {
          expect(out.containsKey(key), isFalse, reason: '${raw['id']} $key');
        }
        // Every original value survives unchanged.
        for (final entry in raw.entries) {
          expect(
            out[entry.key],
            entry.value,
            reason: '${raw['id']} ${entry.key}',
          );
        }
      }
    });
  });

  group('milestone 3 formula widget (v1 formula contract)', () {
    const legacyFormula = {
      'id': 'w-formula',
      'type': 'single_value',
      'title': 'Differenz',
      'connectionId': 'c1',
      'measurement': 'climate',
      'formula': 'A - B',
      'formulaVariables': [
        {'name': 'A', 'field': 'temp_in'},
        {
          'name': 'B',
          'field': 'temp_out',
          'measurement': 'outside',
          'tagFilters': {'loc': 'garden'},
        },
      ],
    };

    test('keeps parsing and gains no new fields', () {
      final widget = WidgetDefinition.fromJson(legacyFormula);
      expect(widget.isValid, isTrue);
      expect(widget.formulaSteps, isNull);
      expect(widget.gapPolicy, isNull);
      final out = widget.toJson();
      for (final key in milestone4Keys) {
        expect(out.containsKey(key), isFalse);
      }
      expect(out['formula'], 'A - B');
    });
  });

  group('milestone 2 multi-value widget', () {
    test('rows without formula keep their json', () {
      const raw = {
        'id': 'w-multi',
        'type': 'multi_value',
        'title': 'Raum',
        'connectionId': 'c1',
        'measurement': 'room',
        'items': [
          {'field': 'temp', 'label': 'Temperatur', 'unit': '°C'},
          {'field': 'hum', 'decimalPlaces': 0},
        ],
      };
      final widget = WidgetDefinition.fromJson(raw);
      expect(widget.isValid, isTrue);
      expect((widget.toJson()['items'] as List<dynamic>), raw['items']);
    });
  });
}
