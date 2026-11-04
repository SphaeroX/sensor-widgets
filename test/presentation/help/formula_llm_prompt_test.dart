import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/domain/widget_code/widget_code_codec.dart';
import 'package:sensor_widgets/presentation/help/formula_help_content.dart';
import 'package:sensor_widgets/presentation/help/formula_llm_prompt.dart';
import 'package:sensor_widgets/presentation/widgets/editor/formula_editor_section.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// The tests assert the German texts.
final _de = lookupAppLocalizations(const Locale('de'));

void main() {
  group('buildFormulaLlmPrompt', () {
    const fields = [
      InfluxFieldInfo(key: 'co2', type: 'float'),
      InfluxFieldInfo(key: 'temperature', type: 'integer'),
      InfluxFieldInfo(key: 'status', type: 'string'),
    ];

    test('lists every function, constant and operator of the language', () {
      final prompt = buildFormulaLlmPrompt(l10n: _de);
      for (final entry in formulaHelpEntries(_de)) {
        expect(prompt, contains(entry.signature));
      }
      expect(prompt, contains('+ - * /'));
      expect(prompt, contains('<= >= == !='));
    });

    test('lists measurement and fields with their types', () {
      final prompt = buildFormulaLlmPrompt(
        l10n: _de,
        measurement: 'sen66',
        availableMeasurements: const ['sen66', 'outdoor'],
        availableFields: fields,
      );
      expect(prompt, contains('sen66'));
      expect(prompt, contains('outdoor'));
      expect(prompt, contains('co2 (float)'));
      expect(prompt, contains('temperature (integer)'));
      expect(prompt, contains('status (string'));
    });

    test('works without schema information', () {
      final prompt = buildFormulaLlmPrompt(l10n: _de);
      expect(prompt, contains('keine Schema-Informationen'));
    });

    test('demands a plain OK first and then formula plus variable mapping', () {
      final prompt = buildFormulaLlmPrompt(l10n: _de);
      expect(prompt, contains('Antworte jetzt nur mit "OK"'));
      expect(prompt, contains('Variablen-Zuweisung'));
      expect(prompt, contains('nur die Formel'));
    });

    test('mentions intermediate steps only when they are supported', () {
      expect(
        buildFormulaLlmPrompt(l10n: _de, supportsSteps: true),
        contains('Schritt'),
      );
      expect(
        buildFormulaLlmPrompt(l10n: _de, supportsSteps: false),
        isNot(contains('Zwischenschritt')),
      );
    });
  });

  group('buildWidgetCodePrompt', () {
    const fields = [
      InfluxFieldInfo(key: 'co2', type: 'float'),
      InfluxFieldInfo(key: 'status', type: 'string'),
    ];

    test('describes language, widget types and JSON keys', () {
      final prompt = buildWidgetCodePrompt(l10n: _de);
      for (final entry in formulaHelpEntries(_de)) {
        expect(prompt, contains(entry.signature));
      }
      for (final type in WidgetType.values) {
        expect(prompt, contains(type.wireName));
      }
      for (final key in [
        'formula',
        'formulaSteps',
        'formulaVariables',
        'timeRange',
        'aggregationInterval',
        'gapPolicy',
        'chartStyle',
        'colorStops',
        'appearance',
        'items',
        'threshold',
      ]) {
        expect(prompt, contains(key));
      }
    });

    test('lists measurement and fields of the environment', () {
      final prompt = buildWidgetCodePrompt(
        l10n: _de,
        measurement: 'sen66',
        availableMeasurements: const ['sen66'],
        availableFields: fields,
      );
      expect(prompt, contains('sen66'));
      expect(prompt, contains('co2 (float)'));
      expect(prompt, contains('status (string'));
    });

    test('includes the current widget code when given', () {
      final prompt = buildWidgetCodePrompt(
        l10n: _de,
        currentCode: '{"type":"gauge_bar"}',
      );
      expect(prompt, contains('{"type":"gauge_bar"}'));
    });

    test('demands OK first and then only one JSON code block', () {
      final prompt = buildWidgetCodePrompt(l10n: _de);
      expect(prompt, contains('Antworte jetzt nur mit "OK"'));
      expect(prompt, contains('genau einem JSON-Codeblock'));
      expect(prompt, isNot(contains('Variablen-Zuweisung:')));
    });

    test('contains an example that the app itself accepts', () {
      final prompt = buildWidgetCodePrompt(l10n: _de);
      final match = RegExp(r'```json\n([\s\S]*?)\n```').firstMatch(prompt);
      expect(match, isNotNull);
      final result = WidgetCodeCodec.decode(
        l10n: _de,
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
  });

  group('FormulaEditorSection copy prompt button', () {
    testWidgets('copies the prompt to the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: FormulaEditorSection(
                isEnabled: true,
                onEnabledChanged: (_) {},
                formula: '',
                onFormulaChanged: (_) {},
                variables: const [],
                onVariablesChanged: (_) {},
                defaultMeasurement: 'sen66',
                availableFields: const [
                  InfluxFieldInfo(key: 'co2', type: 'float'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('copy_llm_prompt_button')));
      await tester.pump();

      expect(copied, isNotNull);
      expect(copied, contains('co2 (float)'));
      expect(copied, contains('sen66'));
      expect(find.textContaining('Prompt kopiert'), findsOneWidget);
    });

    testWidgets('share button hands the prompt to the share callback', (
      tester,
    ) async {
      String? shared;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: FormulaEditorSection(
                isEnabled: true,
                onEnabledChanged: (_) {},
                formula: '',
                onFormulaChanged: (_) {},
                variables: const [],
                onVariablesChanged: (_) {},
                defaultMeasurement: 'sen66',
                availableFields: const [
                  InfluxFieldInfo(key: 'co2', type: 'float'),
                ],
                onSharePrompt: (text) async => shared = text,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('share_llm_prompt_button')));
      await tester.pump();

      expect(shared, contains('co2 (float)'));
      expect(shared, contains('Antworte jetzt nur mit "OK"'));
    });
  });
}
