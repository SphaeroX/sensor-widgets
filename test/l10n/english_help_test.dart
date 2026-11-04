import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/domain/widget_code/widget_code_codec.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';
import 'package:sensor_widgets/presentation/help/formula_help_content.dart';
import 'package:sensor_widgets/presentation/help/formula_help_screen.dart';
import 'package:sensor_widgets/presentation/help/formula_llm_prompt.dart';

import 'english_locale.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _de = lookupAppLocalizations(const Locale('de'));

void main() {
  useEnglishDeviceLocale();

  testWidgets('help screen is English', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FormulaHelpScreen(applyEnabled: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Formula help'), findsOneWidget);
    expect(find.text('Variables'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('clamp(x, low, high)'), 300);
    expect(find.text('Limits x to the range low to high.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Celsius to Fahrenheit'), 300);
    expect(find.text('Apply template'), findsWidgets);
  });

  test('every help entry and template is translated in both languages', () {
    final en = formulaHelpEntries(_en);
    final de = formulaHelpEntries(_de);
    expect(en.map((e) => e.name), de.map((e) => e.name));
    for (var i = 0; i < en.length; i++) {
      expect(en[i].example, de[i].example);
      expect(en[i].exampleResult, de[i].exampleResult);
    }
    expect(
      formulaTemplates(_en).map((t) => t.formula),
      formulaTemplates(_de).map((t) => t.formula),
    );
    expect(formulaHelpSections(_en).first.title, 'Variables');
  });

  test('formula prompt is English', () {
    final prompt = buildFormulaLlmPrompt(l10n: _en);
    expect(prompt, contains('## Formula language'));
    expect(prompt, contains('Reply only with "OK"'));
    expect(prompt, contains('clamp(x, low, high)'));
    expect(prompt, isNot(contains('Formelsprache')));
  });

  test('English widget code prompt contains an example the app accepts', () {
    final prompt = buildWidgetCodePrompt(l10n: _en);
    expect(prompt, contains('## Widget code (JSON)'));
    final match = RegExp(r'```json\n([\s\S]*?)\n```').firstMatch(prompt);
    expect(match, isNotNull);
    final result = WidgetCodeCodec.decode(
      l10n: _en,
      match!.group(1)!,
      base: const WidgetDefinition(
        id: 'x',
        type: WidgetType.singleValue,
        title: 't',
        connectionId: 'c',
        measurement: 'm',
      ),
    );
    expect(result.errors, isEmpty);
  });
}
