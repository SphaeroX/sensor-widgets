import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/formula/formula_evaluator.dart';
import 'package:sensor_widgets/domain/formula/formula_exception.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';

List<FormulaStep> _steps(dynamic testCase) =>
    ((testCase['steps'] as List<dynamic>?) ?? const [])
        .map((e) => FormulaStep.fromJson(e as Map<String, dynamic>))
        .toList();

Map<String, double> _vars(dynamic testCase) =>
    (testCase['variables'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );

void main() {
  group('FormulaEvaluator contract v2', () {
    late Map<String, dynamic> fixtureData;

    setUpAll(() {
      fixtureData = json.decode(
        File('fixtures/formula/evaluator_cases.json').readAsStringSync(),
      ) as Map<String, dynamic>;
    });

    test('evaluates every v2 valid fixture case', () {
      final cases = fixtureData['v2_valid_cases'] as List<dynamic>;
      expect(cases, isNotEmpty);
      for (final c in cases) {
        final result = FormulaEvaluator.evaluate(
          c['formula'] as String,
          _vars(c),
          steps: _steps(c),
        );
        expect(
          result,
          closeTo((c['expected'] as num).toDouble(), 1e-9),
          reason: 'Failed on case: ${c['name']} ("${c['formula']}")',
        );
      }
    });

    test('every v2 error fixture case throws the expected error code', () {
      final cases = fixtureData['v2_error_cases'] as List<dynamic>;
      expect(cases, isNotEmpty);
      for (final c in cases) {
        try {
          FormulaEvaluator.evaluate(
            c['formula'] as String,
            _vars(c),
            steps: _steps(c),
          );
          fail('Expected ${c['expected_error']} for case ${c['name']}');
        } on FormulaException catch (e) {
          expect(
            e.code,
            c['expected_error'],
            reason: 'Wrong error on case: ${c['name']} (${e.message})',
          );
        }
      }
    });

    test('legacy error cases expose their codes', () {
      expect(
        () => FormulaEvaluator.evaluate('A / B', {'A': 1.0, 'B': 0.0}),
        throwsA(
          isA<FormulaException>().having(
            (e) => e.code,
            'code',
            'division_by_zero',
          ),
        ),
      );
    });

    test('extractVariables ignores functions and constants', () {
      expect(
        FormulaEvaluator.extractVariables('min(a, pi * b) + e + max(a, c)'),
        ['a', 'b', 'c'],
      );
    });

    test('validateSyntax reports error position', () {
      final msg = FormulaEvaluator.validateSyntax('A + * B');
      expect(msg, isNotNull);
      expect(msg, contains('Position 5'));
    });

    test('validateSyntax accepts v2 expressions and rejects bad calls', () {
      expect(
        FormulaEvaluator.validateSyntax('if(A > 1, min(A, 2), 0)'),
        isNull,
      );
      expect(FormulaEvaluator.validateSyntax('foo(A)'), isNotNull);
      expect(FormulaEvaluator.validateSyntax('sqrt(A, B)'), isNotNull);
    });

    test('validateSteps detects forward references before evaluation', () {
      final err = FormulaEvaluator.validateSteps(
        const [
          FormulaStep(name: 's1', expression: 's2 + 1'),
          FormulaStep(name: 's2', expression: 'a'),
        ],
        'a',
        variableNames: const ['a'],
      );
      expect(err, isNotNull);
      expect(
        FormulaEvaluator.validateSteps(
          const [FormulaStep(name: 's1', expression: 'a * 2')],
          's1',
          variableNames: const ['a'],
        ),
        isNull,
      );
    });
  });
}
