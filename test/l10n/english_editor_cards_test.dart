import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/alert_rule.dart';
import 'package:sensor_widgets/domain/models/chart_style.dart';
import 'package:sensor_widgets/domain/models/threshold_rule.dart';
import 'package:sensor_widgets/domain/models/widget_appearance.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';
import 'package:sensor_widgets/presentation/widgets/editor/alert_rules_editor.dart';
import 'package:sensor_widgets/presentation/widgets/editor/appearance_editor.dart';
import 'package:sensor_widgets/presentation/widgets/editor/chart_style_editor.dart';
import 'package:sensor_widgets/presentation/widgets/editor/widget_code_section.dart';
import 'package:sensor_widgets/presentation/widgets/editor/widget_type_selector.dart';

import 'english_locale.dart';

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  useEnglishDeviceLocale();

  testWidgets('appearance editor is English', (tester) async {
    await tester.pumpWidget(
      _host(
        AppearanceEditor(
          appearance: const WidgetAppearance(backgroundColor: '#FFFFFF'),
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Background color'), findsOneWidget);
    expect(find.text('Corner radius: 16 dp'), findsOneWidget);
  });

  testWidgets('chart style editor is English', (tester) async {
    await tester.pumpWidget(
      _host(
        ChartStyleEditor(
          style: ChartStyle(colorStops: List.of(ChartStyle.greenToRedStops)),
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Color gradient & chart style'), findsOneWidget);
    expect(find.text('Green → Red'), findsOneWidget);
    expect(find.text('Fill area'), findsOneWidget);
    expect(find.text('Line width'), findsOneWidget);
    expect(find.byTooltip('Delete color stop'), findsWidgets);
  });

  testWidgets('alert rules editor is English', (tester) async {
    await tester.pumpWidget(
      _host(
        AlertRulesEditor(
          rules: const [
            AlertRule(
              target: 'value',
              operator: ThresholdOperator.greaterThan,
              value: 30,
            ),
          ],
          targets: const [AlertTarget(id: 'value', label: 'Value')],
          onChanged: (_) {},
          onRuleAdded: () {},
        ),
      ),
    );
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Add notification'), findsOneWidget);
    expect(find.text('above'), findsOneWidget);
    expect(find.text('Threshold'), findsOneWidget);
  });

  testWidgets('widget code section is English', (tester) async {
    await tester.pumpWidget(
      _host(WidgetCodeSection(generatedCode: '{}', onApply: (_) => const [])),
    );
    expect(find.text('Widget as code'), findsOneWidget);
    expect(find.text('Copy prompt for AI'), findsOneWidget);
    expect(find.text('Apply code'), findsOneWidget);
    await tester.tap(find.byKey(const Key('widget_code_apply_button')));
    await tester.pump();
    expect(find.text('Code applied.'), findsOneWidget);
  });

  testWidgets('widget type tiles are English', (tester) async {
    await tester.pumpWidget(
      _host(
        WidgetTypeSelector(
          selected: WidgetType.singleValue,
          onSelected: (_) {},
        ),
      ),
    );
    expect(find.text('A current reading'), findsOneWidget);
    expect(find.text('History over time'), findsOneWidget);
  });
}
