import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';
import 'package:sensor_widgets/presentation/widgets/editor/alert_rules_editor.dart';
import 'package:sensor_widgets/presentation/widgets/editor/appearance_editor.dart';
import 'package:sensor_widgets/presentation/widgets/editor/chart_style_editor.dart';
import 'package:sensor_widgets/presentation/widgets/editor/widget_code_section.dart';

/// Inside the editor accordion the section header already carries the title
/// and the card, so embedded editors render neither.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('de'),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('embedded appearance editor has no card and no title', (
    tester,
  ) async {
    await pump(
      tester,
      AppearanceEditor(appearance: null, onChanged: (_) {}, embedded: true),
    );
    expect(find.byKey(const Key('appearance_editor')), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(find.text('Aussehen'), findsNothing);
  });

  testWidgets('embedded alert editor has no card and no title', (tester) async {
    await pump(
      tester,
      AlertRulesEditor(
        rules: const [],
        targets: const [],
        onChanged: (_) {},
        onRuleAdded: () {},
        embedded: true,
      ),
    );
    expect(find.byKey(const Key('alert_add_button')), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(find.text('Benachrichtigungen'), findsNothing);
  });

  testWidgets('embedded chart style editor has no card but keeps its title', (
    tester,
  ) async {
    await pump(
      tester,
      ChartStyleEditor(style: null, onChanged: (_) {}, embedded: true),
    );
    expect(find.byKey(const Key('chart_style_editor')), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('embedded code section has no card and no title', (tester) async {
    await pump(
      tester,
      WidgetCodeSection(
        generatedCode: '{}',
        onApply: (_) => const [],
        embedded: true,
      ),
    );
    expect(find.byKey(const Key('widget_code_field')), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(find.text('Widget als Code'), findsNothing);
  });
}
