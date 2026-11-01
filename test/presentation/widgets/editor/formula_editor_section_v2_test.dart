import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/presentation/widgets/editor/formula_editor_section.dart';

class _Harness extends StatefulWidget {
  final String formula;
  final List<FormulaVariable> variables;
  final List<FormulaStep> steps;
  final void Function(_HarnessState state)? onBuild;

  const _Harness({
    this.formula = '',
    this.variables = const [],
    this.steps = const [],
    this.onBuild,
  });

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late String formula = widget.formula;
  late List<FormulaVariable> variables = widget.variables;
  late List<FormulaStep> steps = widget.steps;

  @override
  Widget build(BuildContext context) {
    widget.onBuild?.call(this);
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: FormulaEditorSection(
            isEnabled: true,
            onEnabledChanged: (_) {},
            formula: formula,
            onFormulaChanged: (v) => setState(() => formula = v),
            variables: variables,
            onVariablesChanged: (v) => setState(() => variables = v),
            steps: steps,
            onStepsChanged: (v) => setState(() => steps = v),
            defaultMeasurement: 'sen66',
            availableMeasurements: const ['sen66', 'outdoor'],
            fieldLoader: (measurement) async => measurement == 'outdoor'
                ? const [InfluxFieldInfo(key: 'temp', type: 'float')]
                : const [
                    InfluxFieldInfo(key: 'voc', type: 'float'),
                    InfluxFieldInfo(key: 'co2', type: 'float'),
                  ],
            tagKeyLoader: (measurement) async => const ['room'],
            tagValueLoader: (measurement, key) async => const [
              'kitchen',
              'office',
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  late _HarnessState state;

  Future<void> pump(
    WidgetTester tester, {
    String formula = '',
    List<FormulaVariable> variables = const [],
    List<FormulaStep> steps = const [],
  }) async {
    await tester.pumpWidget(
      _Harness(
        formula: formula,
        variables: variables,
        steps: steps,
        onBuild: (s) => state = s,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('variable dialog uses schema pickers', () {
    testWidgets('IAQ variable can be assembled without typing', (tester) async {
      await pump(
        tester,
        variables: const [FormulaVariable(name: 'A', field: 'voc')],
      );

      await tester.tap(find.byKey(const Key('edit_variable_A_button')));
      await tester.pumpAndSettle();

      // Measurement from list
      await tester.tap(find.byKey(const Key('variable_measurement_input')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('outdoor').last);
      await tester.pumpAndSettle();

      // Field from the measurement's loaded fields
      await tester.tap(find.byKey(const Key('variable_field_input')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('temp').last);
      await tester.pumpAndSettle();

      // Tag filter from loaded keys and values
      await tester.tap(find.byKey(const Key('variable_tag_key_input')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('room').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('variable_tag_value_input')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('kitchen').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_variable_tag_button')));
      await tester.pumpAndSettle();
      expect(find.text('room = kitchen'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('variable_label_input')),
        'Aussen',
      );
      await tester.tap(find.byKey(const Key('apply_variable_button')));
      await tester.pumpAndSettle();

      final v = state.variables.single;
      expect(v.name, 'A');
      expect(v.measurement, 'outdoor');
      expect(v.field, 'temp');
      expect(v.tagFilters, {'room': 'kitchen'});
      expect(v.label, 'Aussen');
    });

    testWidgets('free text still works as fallback', (tester) async {
      await pump(
        tester,
        variables: const [FormulaVariable(name: 'A', field: 'voc')],
      );

      await tester.tap(find.byKey(const Key('edit_variable_A_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('variable_field_input')),
        'custom_field',
      );
      await tester.tap(find.byKey(const Key('apply_variable_button')));
      await tester.pumpAndSettle();

      expect(state.variables.single.field, 'custom_field');
    });

    testWidgets('a tag filter can be removed again', (tester) async {
      await pump(
        tester,
        variables: const [
          FormulaVariable(name: 'A', field: 'voc', tagFilters: {'room': 'x'}),
        ],
      );

      await tester.tap(find.byKey(const Key('edit_variable_A_button')));
      await tester.pumpAndSettle();
      expect(find.text('room = x'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(InputChip),
          matching: find.byIcon(Icons.cancel),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('apply_variable_button')));
      await tester.pumpAndSettle();

      expect(state.variables.single.tagFilters, isNull);
    });
  });

  group('intermediate steps', () {
    testWidgets('steps can be added, edited and removed', (tester) async {
      await pump(
        tester,
        variables: const [FormulaVariable(name: 'A', field: 'voc')],
      );

      await tester.tap(find.byKey(const Key('add_formula_step_button')));
      await tester.pumpAndSettle();
      expect(state.steps, hasLength(1));
      expect(state.steps.single.name, 'schritt1');

      await tester.enterText(
        find.byKey(const Key('step_expression_0')),
        '100 - A * 0.6',
      );
      await tester.enterText(find.byKey(const Key('step_name_0')), 'voc_idx');
      await tester.pumpAndSettle();
      expect(state.steps.single.name, 'voc_idx');
      expect(state.steps.single.expression, '100 - A * 0.6');

      await tester.tap(find.byKey(const Key('delete_step_0')));
      await tester.pumpAndSettle();
      expect(state.steps, isEmpty);
    });

    testWidgets('formula may reference steps without a warning', (
      tester,
    ) async {
      await pump(
        tester,
        formula: 'min(voc_idx, 100)',
        variables: const [FormulaVariable(name: 'A', field: 'voc')],
        steps: const [FormulaStep(name: 'voc_idx', expression: '100 - A')],
      );

      expect(find.textContaining('Nicht definierte Variable'), findsNothing);
      expect(find.textContaining('Syntaxfehler'), findsNothing);
    });

    testWidgets('forward references between steps are reported', (
      tester,
    ) async {
      await pump(
        tester,
        formula: 's1',
        variables: const [FormulaVariable(name: 'A', field: 'voc')],
        steps: const [
          FormulaStep(name: 's1', expression: 's2 + 1'),
          FormulaStep(name: 's2', expression: 'A'),
        ],
      );

      expect(find.textContaining('später definierten Schritt'), findsWidgets);
    });
  });

  group('insert chips', () {
    testWidgets('variable and function chips insert text into the formula', (
      tester,
    ) async {
      await pump(
        tester,
        variables: const [FormulaVariable(name: 'A', field: 'voc')],
        steps: const [FormulaStep(name: 'idx', expression: 'A')],
      );

      await tester.tap(find.byKey(const Key('insert_chip_min')));
      await tester.pumpAndSettle();
      expect(state.formula, 'min()');

      await tester.tap(find.byKey(const Key('insert_chip_A')));
      await tester.pumpAndSettle();
      expect(state.formula, 'min(A)');

      await tester.tap(find.byKey(const Key('insert_chip_idx')));
      await tester.pumpAndSettle();
      expect(state.formula, 'min(Aidx)');
    });
  });

  testWidgets('syntax error message contains the error position', (
    tester,
  ) async {
    await pump(
      tester,
      formula: 'A + * B',
      variables: const [FormulaVariable(name: 'A', field: 'voc')],
    );
    expect(find.textContaining('Position 5'), findsOneWidget);
  });
}
