import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/presentation/help/formula_help_content.dart';
import 'package:sensor_widgets/presentation/help/formula_help_screen.dart';
import 'package:sensor_widgets/presentation/widgets/editor/formula_editor_section.dart';

void main() {
  testWidgets('help screen lists functions, sections and templates', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FormulaHelpScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Formel-Hilfe'), findsOneWidget);
    expect(find.text('Variablen'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('clamp'), 300);
    expect(find.text('clamp'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('IAQ (Sensirion SEN66)'), 300);
    expect(find.text('IAQ (Sensirion SEN66)'), findsOneWidget);
  });

  testWidgets('apply buttons are hidden unless applying is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FormulaHelpScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('IAQ (Sensirion SEN66)'), 300);
    expect(find.byKey(const Key('apply_template_iaq_sen66')), findsNothing);
  });

  testWidgets('tapping apply returns the chosen template', (tester) async {
    FormulaTemplate? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              picked = await Navigator.of(context).push<FormulaTemplate>(
                MaterialPageRoute(
                  builder: (_) => const FormulaHelpScreen(applyEnabled: true),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('apply_template_iaq_sen66')),
      300,
    );
    await tester.ensureVisible(
      find.byKey(const Key('apply_template_iaq_sen66')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('apply_template_iaq_sen66')));
    await tester.pumpAndSettle();

    expect(picked?.id, 'iaq_sen66');
  });

  testWidgets('editor applies a template and asks to assign variables', (
    tester,
  ) async {
    var formula = '';
    var variables = <FormulaVariable>[];
    var steps = <FormulaStep>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: FormulaEditorSection(
                isEnabled: true,
                onEnabledChanged: (_) {},
                formula: formula,
                onFormulaChanged: (v) => setState(() => formula = v),
                variables: variables,
                onVariablesChanged: (v) => setState(() => variables = v),
                steps: steps,
                onStepsChanged: (v) => setState(() => steps = v),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('formula_help_button')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('apply_template_iaq_sen66')),
      300,
    );
    await tester.ensureVisible(
      find.byKey(const Key('apply_template_iaq_sen66')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('apply_template_iaq_sen66')));
    await tester.pumpAndSettle();

    expect(formula, 'min(s_co2, s_voc, s_pm25, s_rh)');
    expect(steps.map((s) => s.name), ['s_co2', 's_voc', 's_pm25', 's_rh']);
    expect(variables.map((v) => v.name), ['co2', 'voc', 'pm25', 'rh']);
    expect(variables.every((v) => v.field.isEmpty), isTrue);
    expect(find.textContaining('Variablen zuordnen'), findsOneWidget);
  });
}
