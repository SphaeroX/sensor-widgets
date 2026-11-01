import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/formula/formula_evaluator.dart';
import 'package:sensor_widgets/domain/formula/formula_exception.dart';

void main() {
  group('FormulaEvaluator', () {
    late Map<String, dynamic> fixtureData;

    setUpAll(() {
      final file = File('fixtures/formula/evaluator_cases.json');
      fixtureData =
          json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('evaluates all valid cases from fixtures correctly', () {
      final validCases = fixtureData['valid_cases'] as List<dynamic>;
      for (final testCase in validCases) {
        final name = testCase['name'] as String;
        final formula = testCase['formula'] as String;
        final rawVars = testCase['variables'] as Map<String, dynamic>;
        final variables = rawVars.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );
        final expected = (testCase['expected'] as num).toDouble();

        final result = FormulaEvaluator.evaluate(formula, variables);
        expect(
          result,
          closeTo(expected, 0.0001),
          reason: 'Failed on case: $name ("$formula")',
        );
      }
    });

    test('extracts variable names from formula', () {
      final vars = FormulaEvaluator.extractVariables(
        '(A + B * 2) / C - temp_out',
      );
      expect(vars, ['A', 'B', 'C', 'temp_out']);
    });

    test('validates formula syntax correctly', () {
      expect(FormulaEvaluator.validateSyntax('A + B'), isNull);
      expect(FormulaEvaluator.validateSyntax('(A + B) / 3'), isNull);
      expect(FormulaEvaluator.validateSyntax('A +'), isNotNull);
      expect(FormulaEvaluator.validateSyntax('(A + B'), isNotNull);
      expect(FormulaEvaluator.validateSyntax(''), isNotNull);
    });

    test('throws DivisionByZeroException on division by zero', () {
      expect(
        () => FormulaEvaluator.evaluate('A / B', {'A': 10.0, 'B': 0.0}),
        throwsA(isA<DivisionByZeroException>()),
      );
    });

    test('throws FormulaSyntaxException on invalid syntax', () {
      expect(
        () => FormulaEvaluator.evaluate('(A + B', {'A': 1.0, 'B': 2.0}),
        throwsA(isA<FormulaSyntaxException>()),
      );
      expect(
        () => FormulaEvaluator.evaluate('A ++ B', {'A': 1.0, 'B': 2.0}),
        throwsA(isA<FormulaSyntaxException>()),
      );
    });

    test('throws MissingVariableException when variable is missing', () {
      expect(
        () => FormulaEvaluator.evaluate('A + B', {'A': 1.0}),
        throwsA(isA<MissingVariableException>()),
      );
    });

    test('handles edge-cases: negative numbers, unary minus, large floats', () {
      // Unary minus with variable
      expect(
        FormulaEvaluator.evaluate('-A', {'A': 5.0}),
        closeTo(-5.0, 0.0001),
      );
      // Multiplication by negative constant
      expect(
        FormulaEvaluator.evaluate('A * -1', {'A': 12.5}),
        closeTo(-12.5, 0.0001),
      );
      // Double unary minus with parentheses
      expect(
        FormulaEvaluator.evaluate('-(-A)', {'A': 7.2}),
        closeTo(7.2, 0.0001),
      );
      // Negative combined with addition
      expect(
        FormulaEvaluator.evaluate('-A + B', {'A': 3.0, 'B': 10.0}),
        closeTo(7.0, 0.0001),
      );
      // Large floating point calculations
      expect(
        FormulaEvaluator.evaluate('A * 1000000', {'A': 1.5}),
        closeTo(1500000.0, 0.0001),
      );
    });
  });
}
