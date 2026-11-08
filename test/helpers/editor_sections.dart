import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens an accordion section of the widget editor (ids: `basics`,
/// `data_source`, `code`, `type_settings`, `appearance`, `alerts`).
///
/// Only one section is open at a time, so this closes the one that was open.
Future<void> openEditorSection(WidgetTester tester, String id) async {
  final header = find.byKey(Key('editor_section_$id'));
  await tester.ensureVisible(header);
  await tester.pumpAndSettle();
  final expanded = tester
      .widget<Semantics>(find.byKey(Key('editor_section_${id}_semantics')))
      .properties
      .expanded;
  if (expanded != true) {
    await tester.tap(header);
    await tester.pumpAndSettle();
  }
}
