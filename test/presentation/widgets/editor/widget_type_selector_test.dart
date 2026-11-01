import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/widgets/editor/widget_type_selector.dart';

void main() {
  Widget host(WidgetType selected, ValueChanged<WidgetType> onSelected) =>
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: WidgetTypeSelector(
              selected: selected,
              onSelected: onSelected,
            ),
          ),
        ),
      );

  testWidgets('shows a tile with name and description for all six types', (
    tester,
  ) async {
    await tester.pumpWidget(host(WidgetType.singleValue, (_) {}));

    for (final type in WidgetType.values) {
      expect(find.byKey(Key('type_tile_${type.wireName}')), findsOneWidget);
    }
    expect(WidgetType.values, hasLength(6));
    expect(find.byIcon(Icons.show_chart), findsOneWidget);
    expect(find.text(WidgetType.gaugeBar.label), findsOneWidget);
  });

  testWidgets('every type can be selected', (tester) async {
    WidgetType? picked;
    await tester.pumpWidget(host(WidgetType.singleValue, (t) => picked = t));

    for (final type in WidgetType.values) {
      await tester.ensureVisible(find.byKey(Key('type_tile_${type.wireName}')));
      await tester.tap(find.byKey(Key('type_tile_${type.wireName}')));
      await tester.pumpAndSettle();
      expect(picked, type);
    }
  });

  testWidgets('the selected tile is exposed as selected to accessibility', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(WidgetType.historyChart, (_) {}));

    expect(
      tester.getSemantics(find.byKey(const Key('type_tile_history_chart'))),
      matchesSemantics(
        label: 'History Chart. Verlauf über die Zeit',
        isSelected: true,
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('tiles keep a 48dp minimum touch target', (tester) async {
    await tester.pumpWidget(host(WidgetType.singleValue, (_) {}));
    for (final type in WidgetType.values) {
      final size = tester.getSize(
        find.byKey(Key('type_tile_${type.wireName}')),
      );
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    }
  });
}
