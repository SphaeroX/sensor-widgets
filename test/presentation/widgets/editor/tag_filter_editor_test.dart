import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/presentation/controllers/schema_discovery_state.dart';
import 'package:sensor_widgets/presentation/widgets/editor/tag_filter_editor.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

void main() {
  Widget buildTestable(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  group('TagFilterEditor', () {
    testWidgets('renders existing tag filters as chips and removes on delete', (
      tester,
    ) async {
      Map<String, String>? updated;
      await tester.pumpWidget(
        buildTestable(
          TagFilterEditor(
            tagFilters: const {'room': 'living_room', 'device': 'sensor_a'},
            tagKeysState: const SchemaListState.loaded(['room', 'device']),
            onTagFiltersChanged: (map) => updated = map,
          ),
        ),
      );

      expect(find.text('room = living_room'), findsOneWidget);
      expect(find.text('device = sensor_a'), findsOneWidget);

      // Delete the 'room' chip
      final deleteButtons = find.byIcon(Icons.close);
      expect(deleteButtons, findsNWidgets(2));

      await tester.tap(deleteButtons.first);
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.containsKey('room'), isFalse);
      expect(updated!['device'], equals('sensor_a'));
    });

    testWidgets('shows loading and error states for tag keys', (tester) async {
      var reloaded = false;
      await tester.pumpWidget(
        buildTestable(
          TagFilterEditor(
            tagFilters: const {},
            tagKeysState: const SchemaListState.error(
              'Konnte Tags nicht laden',
            ),
            onTagFiltersChanged: (_) {},
            onReloadTagKeys: () => reloaded = true,
          ),
        ),
      );

      expect(find.textContaining('Konnte Tags nicht laden'), findsOneWidget);
      final reloadBtn = find.byTooltip('Tags neu laden');
      expect(reloadBtn, findsOneWidget);

      await tester.tap(reloadBtn);
      await tester.pump();
      expect(reloaded, isTrue);
    });

    testWidgets(
      'opens add filter sheet, selects tag key, loads tag values and adds filter',
      (tester) async {
        Map<String, String>? updated;
        String? requestedTagKey;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return buildTestable(
                TagFilterEditor(
                  tagFilters: const {},
                  tagKeysState: const SchemaListState.loaded([
                    'room',
                    'device',
                  ]),
                  tagValuesByKey: const {
                    'room': SchemaListState.loaded(['living_room', 'kitchen']),
                  },
                  onLoadTagValues: (k) => requestedTagKey = k,
                  onTagFiltersChanged: (map) => updated = map,
                ),
              );
            },
          ),
        );

        // Tap on "+ Filter hinzufügen"
        final addBtn = find.byKey(const Key('add_tag_filter_button'));
        expect(addBtn, findsOneWidget);
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        // Step 1: select tag key 'room'
        expect(find.text('Tag-Key auswählen'), findsOneWidget);
        expect(find.text('room'), findsOneWidget);
        await tester.tap(find.text('room'));
        await tester.pumpAndSettle();

        expect(requestedTagKey, equals('room'));

        // Step 2: select tag value 'living_room'
        expect(find.text('living_room'), findsOneWidget);
        await tester.tap(find.text('living_room'));
        await tester.pumpAndSettle();

        expect(updated, equals({'room': 'living_room'}));
      },
    );

    testWidgets('allows manual entry of tag key and tag value', (tester) async {
      Map<String, String>? updated;

      await tester.pumpWidget(
        buildTestable(
          TagFilterEditor(
            tagFilters: const {},
            tagKeysState: const SchemaListState.loaded([]),
            onTagFiltersChanged: (map) => updated = map,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('add_tag_filter_button')));
      await tester.pumpAndSettle();

      // Enter custom tag key
      final keyInput = find.byKey(const Key('manual_tag_key_input'));
      expect(keyInput, findsOneWidget);
      await tester.enterText(keyInput, 'custom_key');
      await tester.tap(find.byKey(const Key('confirm_tag_key_button')));
      await tester.pumpAndSettle();

      // Enter custom tag value
      final valInput = find.byKey(const Key('manual_tag_value_input'));
      expect(valInput, findsOneWidget);
      await tester.enterText(valInput, 'custom_value');
      await tester.tap(find.byKey(const Key('confirm_tag_value_button')));
      await tester.pumpAndSettle();

      expect(updated, equals({'custom_key': 'custom_value'}));
    });
  });
}
