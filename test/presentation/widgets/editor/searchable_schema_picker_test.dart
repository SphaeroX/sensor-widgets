import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/presentation/controllers/schema_discovery_state.dart';
import 'package:sensor_widgets/presentation/widgets/editor/searchable_schema_picker.dart';

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

  group('SearchableSchemaPicker', () {
    testWidgets('renders label and current value', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          SearchableSchemaPicker(
            label: 'Measurement',
            selectedValue: 'climate',
            onSelected: (_) {},
          ),
        ),
      );

      expect(find.text('Measurement'), findsOneWidget);
      expect(find.text('climate'), findsOneWidget);
    });

    testWidgets('shows loading indicator when status is loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestable(
          SearchableSchemaPicker(
            label: 'Measurement',
            status: SchemaStatus.loading,
            onSelected: (_) {},
          ),
        ),
      );

      expect(find.text('Lade aus Datenbank...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'shows error message and calls onReload when reload button is tapped',
      (tester) async {
        var reloaded = false;
        await tester.pumpWidget(
          buildTestable(
            SearchableSchemaPicker(
              label: 'Measurement',
              status: SchemaStatus.error,
              errorMessage: 'Verbindung fehlgeschlagen',
              onSelected: (_) {},
              onReload: () => reloaded = true,
            ),
          ),
        );

        expect(
          find.textContaining('Verbindung fehlgeschlagen'),
          findsOneWidget,
        );
        final reloadBtn = find.byTooltip('Neu laden');
        expect(reloadBtn, findsOneWidget);

        await tester.tap(reloadBtn);
        await tester.pump();
        expect(reloaded, isTrue);
      },
    );

    testWidgets('opens bottom sheet on tap and selects an option', (
      tester,
    ) async {
      String? selected;
      final options = [
        const SchemaPickerOption(value: 'climate'),
        const SchemaPickerOption(value: 'power'),
        const SchemaPickerOption(value: 'water'),
      ];

      await tester.pumpWidget(
        buildTestable(
          SearchableSchemaPicker(
            label: 'Measurement',
            status: SchemaStatus.loaded,
            options: options,
            selectedValue: 'climate',
            onSelected: (val) => selected = val,
          ),
        ),
      );

      // Tap on open picker icon or field
      final openSheetBtn = find.byTooltip('Aus Liste wählen');
      if (openSheetBtn.evaluate().isNotEmpty) {
        await tester.tap(openSheetBtn);
      } else {
        await tester.tap(find.text('climate'));
      }
      await tester.pumpAndSettle();

      // Bottom sheet is open
      expect(find.text('power'), findsOneWidget);
      expect(find.text('water'), findsOneWidget);

      // Select 'power'
      await tester.tap(find.text('power'));
      await tester.pumpAndSettle();

      expect(selected, equals('power'));
      // Bottom sheet should be closed
      expect(find.text('water'), findsNothing);
    });

    testWidgets('filters options in bottom sheet via search field', (
      tester,
    ) async {
      final options = [
        const SchemaPickerOption(value: 'living_room_temp'),
        const SchemaPickerOption(value: 'bedroom_temp'),
        const SchemaPickerOption(value: 'kitchen_humidity'),
      ];

      await tester.pumpWidget(
        buildTestable(
          SearchableSchemaPicker(
            label: 'Field',
            status: SchemaStatus.loaded,
            options: options,
            onSelected: (_) {},
          ),
        ),
      );

      final openSheetBtn = find.byTooltip('Aus Liste wählen');
      if (openSheetBtn.evaluate().isNotEmpty) {
        await tester.tap(openSheetBtn);
      } else {
        await tester.tap(find.byType(TextFormField));
      }
      await tester.pumpAndSettle();

      expect(find.text('living_room_temp'), findsOneWidget);
      expect(find.text('bedroom_temp'), findsOneWidget);
      expect(find.text('kitchen_humidity'), findsOneWidget);

      // Type in search field
      final searchInput = find.byKey(const Key('schema_picker_search_input'));
      expect(searchInput, findsOneWidget);
      await tester.enterText(searchInput, 'kitchen');
      await tester.pumpAndSettle();

      expect(find.text('living_room_temp'), findsNothing);
      expect(find.text('bedroom_temp'), findsNothing);
      expect(find.text('kitchen_humidity'), findsOneWidget);
    });

    testWidgets(
      'handles numeric filter and badges when requireNumericHint is true',
      (tester) async {
        final options = [
          const SchemaPickerOption(
            value: 'temp',
            badge: 'float',
            isNumeric: true,
          ),
          const SchemaPickerOption(
            value: 'status',
            badge: 'string',
            isNumeric: false,
          ),
        ];

        await tester.pumpWidget(
          buildTestable(
            SearchableSchemaPicker(
              label: 'Field',
              status: SchemaStatus.loaded,
              options: options,
              requireNumericHint: true,
              onSelected: (_) {},
            ),
          ),
        );

        final openSheetBtn = find.byTooltip('Aus Liste wählen');
        if (openSheetBtn.evaluate().isNotEmpty) {
          await tester.tap(openSheetBtn);
        } else {
          await tester.tap(find.byType(TextFormField));
        }
        await tester.pumpAndSettle();

        expect(find.text('float'), findsOneWidget);
        expect(find.text('string'), findsOneWidget);

        // FilterChip for numeric
        final numericFilterChip = find.byKey(const Key('numeric_filter_chip'));
        expect(numericFilterChip, findsOneWidget);

        await tester.tap(numericFilterChip);
        await tester.pumpAndSettle();

        expect(find.text('temp'), findsOneWidget);
        expect(find.text('status'), findsNothing);
      },
    );

    testWidgets('allows manual free-text input via fieldKey seamlessly', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        buildTestable(
          SearchableSchemaPicker(
            fieldKey: const Key('widget_measurement_field'),
            label: 'Measurement',
            onSelected: (val) => selected = val,
          ),
        ),
      );

      final input = find.byKey(const Key('widget_measurement_field'));
      expect(input, findsOneWidget);

      await tester.enterText(input, 'my_custom_measurement');
      await tester.pump();

      expect(selected, equals('my_custom_measurement'));
    });
  });
}
