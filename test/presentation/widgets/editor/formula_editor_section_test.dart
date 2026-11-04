import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/presentation/widgets/editor/formula_editor_section.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

void main() {
  group('FormulaEditorSection', () {
    testWidgets('renders toggle switch and hides details when disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FormulaEditorSection(
              isEnabled: false,
              onEnabledChanged: (_) {},
              formula: '',
              onFormulaChanged: (_) {},
              variables: const [],
              onVariablesChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Berechnungsformel verwenden'), findsOneWidget);
      expect(find.byIcon(Icons.calculate_outlined), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.byKey(const Key('formula_input_field')), findsNothing);
    });

    testWidgets('shows formula input and variable list when enabled', (
      tester,
    ) async {
      var formula = 'A + B';
      var variables = const [
        FormulaVariable(name: 'A', field: 'temp_in'),
        FormulaVariable(name: 'B', field: 'temp_out'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FormulaEditorSection(
                  isEnabled: true,
                  onEnabledChanged: (_) {},
                  formula: formula,
                  onFormulaChanged: (val) => setState(() => formula = val),
                  variables: variables,
                  onVariablesChanged: (vars) =>
                      setState(() => variables = vars),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('formula_input_field')), findsOneWidget);
      expect(find.text('Variable A'), findsOneWidget);
      expect(find.text('Variable B'), findsOneWidget);
      expect(find.text('temp_in'), findsOneWidget);
      expect(find.text('temp_out'), findsOneWidget);
    });

    testWidgets('displays syntax error hint on invalid formula syntax', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FormulaEditorSection(
              isEnabled: true,
              onEnabledChanged: (_) {},
              formula: '(A +',
              onFormulaChanged: (_) {},
              variables: const [FormulaVariable(name: 'A', field: 'temp')],
              onVariablesChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Syntax'), findsOneWidget);
    });

    testWidgets('displays warning when variable in formula is undefined', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FormulaEditorSection(
              isEnabled: true,
              onEnabledChanged: (_) {},
              formula: 'A + C',
              onFormulaChanged: (_) {},
              variables: const [FormulaVariable(name: 'A', field: 'temp')],
              onVariablesChanged: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.textContaining('Nicht definierte Variable: C'),
        findsOneWidget,
      );
    });

    testWidgets('allows adding and removing variables', (tester) async {
      List<FormulaVariable> variables = [
        const FormulaVariable(name: 'A', field: 'temp'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FormulaEditorSection(
                  isEnabled: true,
                  onEnabledChanged: (_) {},
                  formula: 'A',
                  onFormulaChanged: (_) {},
                  variables: variables,
                  onVariablesChanged: (newVars) {
                    setState(() => variables = newVars);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Variable A'), findsOneWidget);
      expect(find.text('Variable B'), findsNothing);

      // Tap add variable
      await tester.tap(find.byKey(const Key('add_formula_variable_button')));
      await tester.pumpAndSettle();

      expect(variables.length, 2);
      expect(variables.last.name, 'B');

      // Tap delete on variable B
      await tester.tap(find.byKey(const Key('delete_variable_B_button')));
      await tester.pumpAndSettle();

      expect(variables.length, 1);
      expect(variables.first.name, 'A');
    });
  });
}
