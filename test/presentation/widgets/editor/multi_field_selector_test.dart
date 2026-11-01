import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/domain/models/sensor_query_item.dart';
import 'package:sensor_widgets/presentation/controllers/schema_discovery_state.dart';
import 'package:sensor_widgets/presentation/widgets/editor/multi_field_selector.dart';

void main() {
  Widget buildTestable(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  group('MultiFieldSelector', () {
    testWidgets('renders existing selected items and removes item on delete', (
      tester,
    ) async {
      List<SensorQueryItem>? updated;
      final initialItems = [
        const SensorQueryItem(field: 'temperature', label: 'Temp', unit: '°C'),
        const SensorQueryItem(field: 'humidity', label: 'Hum', unit: '%'),
      ];

      await tester.pumpWidget(
        buildTestable(
          MultiFieldSelector(
            items: initialItems,
            fieldsState: const SchemaListState.loaded([
              InfluxFieldInfo(key: 'temperature', type: 'float'),
              InfluxFieldInfo(key: 'humidity', type: 'float'),
            ]),
            onItemsChanged: (items) => updated = items,
          ),
        ),
      );

      expect(find.text('temperature'), findsOneWidget);
      expect(find.text('Temp'), findsOneWidget);
      expect(find.text('°C'), findsOneWidget);
      expect(find.text('humidity'), findsOneWidget);

      final deleteBtns = find.byTooltip('Feld entfernen');
      expect(deleteBtns, findsNWidgets(2));

      await tester.tap(deleteBtns.first);
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.length, equals(1));
      expect(updated!.first.field, equals('humidity'));
    });

    testWidgets(
      'opens multi select sheet, checks fields while preserving existing label, and confirms',
      (tester) async {
        List<SensorQueryItem>? updated;
        final initialItems = [
          const SensorQueryItem(
            field: 'temperature',
            label: 'Raumtemp',
            unit: '°C',
          ),
        ];
        final availableFields = [
          const InfluxFieldInfo(key: 'temperature', type: 'float'),
          const InfluxFieldInfo(key: 'humidity', type: 'float'),
          const InfluxFieldInfo(key: 'co2', type: 'integer'),
        ];

        await tester.pumpWidget(
          buildTestable(
            MultiFieldSelector(
              items: initialItems,
              fieldsState: SchemaListState.loaded(availableFields),
              onItemsChanged: (items) => updated = items,
            ),
          ),
        );

        // Open multi select sheet
        await tester.tap(find.byKey(const Key('select_multi_fields_button')));
        await tester.pumpAndSettle();

        expect(find.text('Felder auswählen'), findsOneWidget);
        expect(find.text('co2'), findsOneWidget);
        expect(find.text('integer'), findsOneWidget);

        // Select 'co2'
        await tester.tap(find.text('co2'));
        await tester.pumpAndSettle();

        // Confirm
        await tester.tap(find.byKey(const Key('confirm_multi_fields_button')));
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        expect(updated!.length, equals(2));
        // Preserved custom label
        expect(updated![0].field, equals('temperature'));
        expect(updated![0].label, equals('Raumtemp'));
        // Added co2
        expect(updated![1].field, equals('co2'));
      },
    );

    testWidgets('allows adding a manual field when offline', (tester) async {
      List<SensorQueryItem>? updated;

      await tester.pumpWidget(
        buildTestable(
          MultiFieldSelector(
            items: const [],
            fieldsState: const SchemaListState.loaded([]),
            onItemsChanged: (items) => updated = items,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('add_manual_multi_field_button')));
      await tester.pumpAndSettle();

      final input = find.byKey(const Key('manual_field_name_input'));
      expect(input, findsOneWidget);

      await tester.enterText(input, 'pressure_raw');
      await tester.tap(find.byKey(const Key('confirm_manual_field_button')));
      await tester.pumpAndSettle();

      expect(updated, isNotNull);
      expect(updated!.length, equals(1));
      expect(updated!.first.field, equals('pressure_raw'));
    });

    testWidgets('shows loading and error states with reload button', (
      tester,
    ) async {
      var reloaded = false;
      await tester.pumpWidget(
        buildTestable(
          MultiFieldSelector(
            items: const [],
            fieldsState: const SchemaListState.error(
              'Fehler beim Laden der Felder',
            ),
            onItemsChanged: (_) {},
            onReload: () => reloaded = true,
          ),
        ),
      );

      expect(
        find.textContaining('Fehler beim Laden der Felder'),
        findsOneWidget,
      );
      final reloadBtn = find.byTooltip('Felder neu laden');
      expect(reloadBtn, findsOneWidget);

      await tester.tap(reloadBtn);
      await tester.pump();
      expect(reloaded, isTrue);
    });
  });
}
