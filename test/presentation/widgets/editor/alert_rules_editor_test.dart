import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/alert_rule.dart';
import 'package:sensor_widgets/domain/models/threshold_rule.dart';
import 'package:sensor_widgets/presentation/widgets/editor/alert_rules_editor.dart';

void main() {
  const singleTarget = [AlertTarget(id: 'value', label: 'Berechneter Wert')];
  const rowTargets = [
    AlertTarget(id: 'co2', label: 'CO2'),
    AlertTarget(id: 'temp', label: 'Temperatur'),
  ];

  Future<void> pump(
    WidgetTester tester, {
    required List<AlertRule> rules,
    required List<AlertTarget> targets,
    required ValueChanged<List<AlertRule>> onChanged,
    VoidCallback? onRuleAdded,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AlertRulesEditor(
              rules: rules,
              targets: targets,
              onChanged: onChanged,
              onRuleAdded: onRuleAdded ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('adding a rule uses the first target and asks for permission', (
    tester,
  ) async {
    List<AlertRule>? changed;
    var added = 0;
    await pump(
      tester,
      rules: const [],
      targets: rowTargets,
      onChanged: (r) => changed = r,
      onRuleAdded: () => added++,
    );

    await tester.tap(find.byKey(const Key('alert_add_button')));
    await tester.pump();

    expect(changed, hasLength(1));
    expect(changed!.single.target, 'co2');
    expect(changed!.single.operator, ThresholdOperator.greaterThan);
    expect(added, 1);
  });

  testWidgets('threshold, operator and target can be changed', (tester) async {
    var rules = const [
      AlertRule(
        target: 'co2',
        operator: ThresholdOperator.greaterThan,
        value: 0,
      ),
    ];
    await pump(
      tester,
      rules: rules,
      targets: rowTargets,
      onChanged: (r) => rules = r,
    );

    await tester.enterText(find.byKey(const Key('alert_value_0')), '18,5');
    await tester.pump();
    expect(rules.single.value, 18.5);

    await tester.tap(find.byKey(const Key('alert_operator_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('unter').last);
    await tester.pumpAndSettle();
    expect(rules.single.operator, ThresholdOperator.lessThan);

    await tester.tap(find.byKey(const Key('alert_target_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Temperatur').last);
    await tester.pumpAndSettle();
    expect(rules.single.target, 'temp');
  });

  testWidgets('a single target needs no target dropdown', (tester) async {
    await pump(
      tester,
      rules: const [
        AlertRule(
          target: 'value',
          operator: ThresholdOperator.greaterThan,
          value: 150,
        ),
      ],
      targets: singleTarget,
      onChanged: (_) {},
    );

    expect(find.byKey(const Key('alert_target_0')), findsNothing);
    expect(find.text('Berechneter Wert'), findsOneWidget);
  });

  testWidgets('a rule can be removed', (tester) async {
    List<AlertRule>? changed;
    await pump(
      tester,
      rules: const [
        AlertRule(
          target: 'value',
          operator: ThresholdOperator.greaterThan,
          value: 150,
        ),
      ],
      targets: singleTarget,
      onChanged: (r) => changed = r,
    );

    await tester.tap(find.byKey(const Key('alert_remove_0')));
    await tester.pump();

    expect(changed, isEmpty);
  });
}
