import 'dart:math' as math;

import 'package:sensor_widgets/domain/formula/formula_exception.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';

enum _T {
  number,
  identifier,
  plus,
  minus,
  star,
  slash,
  lparen,
  rparen,
  comma,
  lt,
  gt,
  le,
  ge,
  eq,
  ne,
  end,
}

class _Token {
  final _T type;
  final String text;
  final int pos;
  final double? value;

  const _Token(this.type, this.text, this.pos, [this.value]);
}

sealed class _Node {
  const _Node();
}

class _Num extends _Node {
  final double value;
  const _Num(this.value);
}

class _Ident extends _Node {
  final String name;
  const _Ident(this.name);
}

class _Neg extends _Node {
  final _Node operand;
  const _Neg(this.operand);
}

class _Bin extends _Node {
  final _T op;
  final _Node left;
  final _Node right;
  const _Bin(this.op, this.left, this.right);
}

class _Call extends _Node {
  final String name;
  final List<_Node> args;
  const _Call(this.name, this.args);
}

/// Arity as `(min, max)`; `max == null` means unbounded.
const Map<String, (int, int?)> _functions = {
  'min': (1, null),
  'max': (1, null),
  'clamp': (3, 3),
  'abs': (1, 1),
  'pow': (2, 2),
  'sqrt': (1, 1),
  'ln': (1, 1),
  'log10': (1, 1),
  'exp': (1, 1),
  'round': (1, 1),
  'floor': (1, 1),
  'ceil': (1, 1),
  'if': (3, 3),
};

const Map<String, double> _constants = {'pi': math.pi, 'e': math.e};

final RegExp _identPattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

/// Evaluator for formulas (contract v2).
///
/// Supports `+ - * /`, unary minus, parentheses, comparisons
/// (`< > <= >= == !=`, result `1.0` / `0.0`), the functions `min`, `max`
/// (1..n arguments), `clamp`, `abs`, `pow`, `sqrt`, `ln`, `log10`, `exp`,
/// `round` (half away from zero), `floor`, `ceil`, `if(cond, a, b)` (lazy,
/// non-zero is true), the constants `pi` and `e` (variables and steps of the
/// same name take precedence) and named intermediate [FormulaStep]s.
class FormulaEvaluator {
  FormulaEvaluator._();

  /// Names of all supported functions (used by the in-app help).
  static List<String> get functionNames => _functions.keys.toList();

  /// Validates formula syntax. Returns null if valid, or an English error
  /// description that includes the 1-based error position where known.
  /// The UI uses [syntaxError] and translates it.
  static String? validateSyntax(String formula) {
    final e = syntaxError(formula);
    if (e == null) return null;
    final position = formulaErrorPosition(e);
    return position == null
        ? e.message
        : '${e.message} (Position ${position + 1})';
  }

  /// The syntax error of [formula] (see [formulaErrorPosition]), or null.
  static FormulaException? syntaxError(String formula) {
    if (formula.trim().isEmpty) {
      return const FormulaSyntaxException(FormulaErrorKind.emptyFormula);
    }
    try {
      _parse(formula);
      return null;
    } on FormulaException catch (e) {
      return e;
    }
  }

  /// Validates [steps] and the final [formula] without evaluating them.
  /// Returns null if valid, or the first error message (English; the UI uses
  /// [stepsError] and translates it).
  static String? validateSteps(
    List<FormulaStep> steps,
    String formula, {
    required List<String> variableNames,
  }) => stepsError(steps, formula, variableNames: variableNames)?.message;

  /// The first error of [steps] and the final [formula], or null.
  static FormulaException? stepsError(
    List<FormulaStep> steps,
    String formula, {
    required List<String> variableNames,
  }) {
    final known = <String>{...variableNames};
    final allSteps = steps.map((s) => s.name).toSet();
    try {
      for (final step in steps) {
        _checkStepName(step.name, known);
        _checkReferences(_parse(step.expression), known, allSteps, step.name);
        known.add(step.name);
      }
      _checkReferences(_parse(formula), known, const {}, null);
      return null;
    } on FormulaException catch (e) {
      return e;
    }
  }

  /// Extracts all distinct variable names referenced in the formula in order
  /// of appearance. Function names and the constants `pi` and `e` are skipped.
  static List<String> extractVariables(String formula) {
    try {
      final vars = <String>[];
      _collectIdents(_parse(formula), vars);
      return vars.where((n) => !_constants.containsKey(n)).toList();
    } on FormulaException {
      return const [];
    }
  }

  /// Evaluates the formula using the provided variable values and optional
  /// intermediate [steps].
  ///
  /// Throws a [FormulaException] subclass; see `FormulaException.code`.
  static double evaluate(
    String formula,
    Map<String, double> variables, {
    List<FormulaStep> steps = const [],
  }) {
    if (formula.trim().isEmpty) {
      throw const FormulaSyntaxException(FormulaErrorKind.emptyFormula);
    }
    final scope = Map<String, double>.of(variables);
    final allSteps = steps.map((s) => s.name).toSet();
    for (final step in steps) {
      _checkStepName(step.name, scope.keys);
      final ast = _parse(step.expression);
      _checkForwardReferences(ast, scope.keys, allSteps, step.name);
      scope[step.name] = _eval(ast, scope);
    }
    return _eval(_parse(formula), scope);
  }

  static void _checkStepName(String name, Iterable<String> taken) {
    if (!_identPattern.hasMatch(name)) {
      throw StepReferenceException(FormulaErrorKind.invalidStepName, [name]);
    }
    if (_functions.containsKey(name)) {
      throw StepReferenceException(FormulaErrorKind.stepNameIsFunction, [name]);
    }
    if (taken.contains(name)) {
      throw StepReferenceException(FormulaErrorKind.duplicateName, [name]);
    }
  }

  static void _checkForwardReferences(
    _Node ast,
    Iterable<String> known,
    Set<String> allSteps,
    String? current,
  ) {
    final idents = <String>[];
    _collectIdents(ast, idents);
    for (final id in idents) {
      if (!known.contains(id) && allSteps.contains(id)) {
        throw StepReferenceException(
          id == current
              ? FormulaErrorKind.stepSelfReference
              : FormulaErrorKind.stepForwardReference,
          [id],
        );
      }
    }
  }

  static void _checkReferences(
    _Node ast,
    Set<String> known,
    Set<String> allSteps,
    String? current,
  ) {
    _checkForwardReferences(ast, known, allSteps, current);
    final idents = <String>[];
    _collectIdents(ast, idents);
    for (final id in idents) {
      if (!known.contains(id) && !_constants.containsKey(id)) {
        throw MissingVariableException(id);
      }
    }
  }

  static void _collectIdents(_Node node, List<String> out) {
    switch (node) {
      case _Num():
        break;
      case _Ident(:final name):
        if (!out.contains(name)) out.add(name);
      case _Neg(:final operand):
        _collectIdents(operand, out);
      case _Bin(:final left, :final right):
        _collectIdents(left, out);
        _collectIdents(right, out);
      case _Call(:final args):
        for (final a in args) {
          _collectIdents(a, out);
        }
    }
  }

  // ---------------------------------------------------------------- tokenizer

  static List<_Token> _tokenize(String s) {
    final tokens = <_Token>[];
    var i = 0;
    while (i < s.length) {
      final c = s[i];
      if (c.trim().isEmpty) {
        i++;
        continue;
      }
      final next = i + 1 < s.length ? s[i + 1] : '';
      switch (c) {
        case '+':
          tokens.add(_Token(_T.plus, c, i++));
        case '-':
          tokens.add(_Token(_T.minus, c, i++));
        case '*':
          tokens.add(_Token(_T.star, c, i++));
        case '/':
          tokens.add(_Token(_T.slash, c, i++));
        case '(':
          tokens.add(_Token(_T.lparen, c, i++));
        case ')':
          tokens.add(_Token(_T.rparen, c, i++));
        case ',':
          tokens.add(_Token(_T.comma, c, i++));
        case '<':
          if (next == '=') {
            tokens.add(_Token(_T.le, '<=', i));
            i += 2;
          } else {
            tokens.add(_Token(_T.lt, c, i++));
          }
        case '>':
          if (next == '=') {
            tokens.add(_Token(_T.ge, '>=', i));
            i += 2;
          } else {
            tokens.add(_Token(_T.gt, c, i++));
          }
        case '=':
          if (next != '=') {
            throw FormulaSyntaxException(
              FormulaErrorKind.unexpectedAssign,
              const [],
              i,
            );
          }
          tokens.add(_Token(_T.eq, '==', i));
          i += 2;
        case '!':
          if (next != '=') {
            throw FormulaSyntaxException(
              FormulaErrorKind.unexpectedCharacter,
              const ['!'],
              i,
            );
          }
          tokens.add(_Token(_T.ne, '!=', i));
          i += 2;
        default:
          if (_isDigit(c) || c == '.') {
            final start = i;
            var hasDot = false;
            while (i < s.length &&
                (_isDigit(s[i]) || (s[i] == '.' && !hasDot))) {
              if (s[i] == '.') hasDot = true;
              i++;
            }
            final text = s.substring(start, i);
            final value = double.tryParse(text);
            if (value == null) {
              throw FormulaSyntaxException(FormulaErrorKind.invalidNumber, [
                text,
              ], start);
            }
            tokens.add(_Token(_T.number, text, start, value));
          } else if (_isIdentStart(c)) {
            final start = i;
            while (i < s.length && (_isIdentStart(s[i]) || _isDigit(s[i]))) {
              i++;
            }
            tokens.add(_Token(_T.identifier, s.substring(start, i), start));
          } else {
            throw FormulaSyntaxException(FormulaErrorKind.unexpectedCharacter, [
              c,
            ], i);
          }
      }
    }
    tokens.add(_Token(_T.end, '', s.length));
    return tokens;
  }

  static bool _isDigit(String c) {
    final code = c.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  static bool _isIdentStart(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        code == 95;
  }

  static _Node _parse(String formula) => _Parser(_tokenize(formula)).parseAll();

  // --------------------------------------------------------------- evaluator

  static double _eval(_Node node, Map<String, double> scope) {
    switch (node) {
      case _Num(:final value):
        return value;
      case _Ident(:final name):
        final v = scope[name] ?? _constants[name];
        if (v == null) throw MissingVariableException(name);
        return v;
      case _Neg(:final operand):
        return -_eval(operand, scope);
      case _Bin(:final op, :final left, :final right):
        final a = _eval(left, scope);
        final b = _eval(right, scope);
        return _finite(switch (op) {
          _T.plus => a + b,
          _T.minus => a - b,
          _T.star => a * b,
          _T.slash => b == 0.0 ? throw const DivisionByZeroException() : a / b,
          _T.lt => a < b ? 1.0 : 0.0,
          _T.gt => a > b ? 1.0 : 0.0,
          _T.le => a <= b ? 1.0 : 0.0,
          _T.ge => a >= b ? 1.0 : 0.0,
          _T.eq => a == b ? 1.0 : 0.0,
          _T.ne => a != b ? 1.0 : 0.0,
          _ => throw FormulaSyntaxException(FormulaErrorKind.unknownOperator, [
            '$op',
          ]),
        });
      case _Call(:final name, :final args):
        return _call(name, args, scope);
    }
  }

  static double _call(
    String name,
    List<_Node> args,
    Map<String, double> scope,
  ) {
    if (name == 'if') {
      final cond = _eval(args[0], scope);
      return _eval(cond != 0.0 ? args[1] : args[2], scope);
    }
    final v = args.map((a) => _eval(a, scope)).toList();
    switch (name) {
      case 'min':
        return v.reduce(math.min);
      case 'max':
        return v.reduce(math.max);
      case 'clamp':
        if (v[1] > v[2]) {
          throw const FormulaDomainException(FormulaErrorKind.clampBounds);
        }
        return v[0].clamp(v[1], v[2]).toDouble();
      case 'abs':
        return v[0].abs();
      case 'pow':
        return _finite(math.pow(v[0], v[1]).toDouble(), 'pow');
      case 'sqrt':
        if (v[0] < 0) {
          throw const FormulaDomainException(FormulaErrorKind.sqrtNegative);
        }
        return math.sqrt(v[0]);
      case 'ln':
        if (v[0] <= 0) {
          throw const FormulaDomainException(FormulaErrorKind.lnNonPositive);
        }
        return math.log(v[0]);
      case 'log10':
        if (v[0] <= 0) {
          throw const FormulaDomainException(FormulaErrorKind.log10NonPositive);
        }
        return math.log(v[0]) / math.ln10;
      case 'exp':
        return _finite(math.exp(v[0]), 'exp');
      case 'round':
        return v[0].roundToDouble();
      case 'floor':
        return v[0].floorToDouble();
      case 'ceil':
        return v[0].ceilToDouble();
    }
    throw UnknownFunctionException(name);
  }

  static double _finite(double value, [String what = '']) {
    if (value.isNaN || value.isInfinite) {
      throw FormulaDomainException(FormulaErrorKind.notFinite, [what]);
    }
    return value;
  }
}

/// Recursive-descent parser. Grammar:
///
/// ```
/// comparison := additive (("<"|">"|"<="|">="|"=="|"!=") additive)*
/// additive   := term (("+"|"-") term)*
/// term       := unary (("*"|"/") unary)*
/// unary      := "-" unary | primary
/// primary    := number | ident "(" [comparison ("," comparison)*] ")"
///             | ident | "(" comparison ")"
/// ```
class _Parser {
  final List<_Token> _tokens;
  var _i = 0;

  _Parser(this._tokens);

  _Token get _cur => _tokens[_i];

  _Node parseAll() {
    final node = _comparison();
    if (_cur.type != _T.end) {
      throw switch (_cur.type) {
        _T.rparen => FormulaSyntaxException(
          FormulaErrorKind.missingOpeningParen,
          const [],
          _cur.pos,
        ),
        _T.number || _T.identifier => FormulaSyntaxException(
          FormulaErrorKind.missingOperator,
          const [],
          _cur.pos,
        ),
        _ => FormulaSyntaxException(FormulaErrorKind.unexpectedCharacter, [
          _cur.text,
        ], _cur.pos),
      };
    }
    return node;
  }

  static const _cmpOps = {_T.lt, _T.gt, _T.le, _T.ge, _T.eq, _T.ne};

  _Node _comparison() {
    var left = _additive();
    while (_cmpOps.contains(_cur.type)) {
      final op = _tokens[_i++].type;
      left = _Bin(op, left, _additive());
    }
    return left;
  }

  _Node _additive() {
    var left = _term();
    while (_cur.type == _T.plus || _cur.type == _T.minus) {
      final op = _tokens[_i++].type;
      left = _Bin(op, left, _term());
    }
    return left;
  }

  _Node _term() {
    var left = _unary();
    while (_cur.type == _T.star || _cur.type == _T.slash) {
      final op = _tokens[_i++].type;
      left = _Bin(op, left, _unary());
    }
    return left;
  }

  _Node _unary() {
    if (_cur.type == _T.minus) {
      _i++;
      return _Neg(_unary());
    }
    return _primary();
  }

  _Node _primary() {
    final t = _cur;
    switch (t.type) {
      case _T.number:
        _i++;
        return _Num(t.value!);
      case _T.identifier:
        _i++;
        if (_cur.type == _T.lparen) return _callNode(t);
        return _Ident(t.text);
      case _T.lparen:
        _i++;
        final inner = _comparison();
        _expectClose();
        return inner;
      case _T.end:
        throw FormulaSyntaxException(
          FormulaErrorKind.incompleteExpression,
          const [],
          t.pos,
        );
      default:
        throw FormulaSyntaxException(FormulaErrorKind.unexpectedCharacter, [
          t.text,
        ], t.pos);
    }
  }

  void _expectClose() {
    if (_cur.type != _T.rparen) {
      throw FormulaSyntaxException(
        FormulaErrorKind.unclosedParen,
        const [],
        _cur.pos,
      );
    }
    _i++;
  }

  _Node _callNode(_Token nameToken) {
    final name = nameToken.text;
    final arity = _functions[name];
    if (arity == null) {
      throw UnknownFunctionException(name, position: nameToken.pos);
    }
    _i++; // '('
    final args = <_Node>[];
    if (_cur.type != _T.rparen) {
      args.add(_comparison());
      while (_cur.type == _T.comma) {
        _i++;
        args.add(_comparison());
      }
    }
    _expectClose();
    final (minArgs, maxArgs) = arity;
    if (args.length < minArgs || (maxArgs != null && args.length > maxArgs)) {
      throw WrongArgumentCountException(
        name,
        minArgs,
        maxArgs,
        args.length,
        position: nameToken.pos,
      );
    }
    return _Call(name, args);
  }
}
