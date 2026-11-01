import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/presentation/widgets/editor/formula_editor_section.dart';

/// Applying a template changes formula and steps from outside while the
/// section sits inside a Form (as in the editor screen). That must not set a
/// controller during build ("setState() called during build").
void main() {
  testWidgets('external formula and step updates inside a Form do not throw', (
    tester,
  ) async {
    var formula = 'A';
    var steps = const [FormulaStep(name: 's1', expression: 'A * 2')];
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return Form(
                  child: FormulaEditorSection(
                    isEnabled: true,
                    onEnabledChanged: (_) {},
                    formula: formula,
                    onFormulaChanged: (v) => formula = v,
                    variables: const [FormulaVariable(name: 'A', field: 'f')],
                    onVariablesChanged: (_) {},
                    steps: steps,
                    onStepsChanged: (v) => steps = v,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    update(() {
      formula = 'min(s1, s2)';
      steps = const [
        FormulaStep(name: 's1', expression: 'A * 3'),
        FormulaStep(name: 's2', expression: 'A + 1'),
      ];
    });
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('formula_input_field')))
          .controller!
          .text,
      'min(s1, s2)',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('step_expression_0')))
          .controller!
          .text,
      'A * 3',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('step_name_1')))
          .controller!
          .text,
      's2',
    );
  });
}
