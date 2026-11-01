import 'package:sensor_widgets/domain/formula/formula_exception.dart';

enum _TokenType {
  number,
  identifier,
  plus,
  minus,
  multiply,
  divide,
  openParen,
  closeParen,
}

class _Token {
  final _TokenType type;
  final String text;
  final double? numberValue;

  _Token(this.type, this.text, [this.numberValue]);

  @override
  String toString() => '_Token($type, $text)';
}

/// Evaluator for custom arithmetic formulas with variables.
/// Supports +, -, *, /, unary minus, parentheses, and floating-point constants.
class FormulaEvaluator {
  FormulaEvaluator._();

  /// Validates formula syntax. Returns null if valid, or an error description string.
  static String? validateSyntax(String formula) {
    if (formula.trim().isEmpty) {
      return 'Formel darf nicht leer sein';
    }
    try {
      final tokens = _tokenize(formula);
      if (tokens.isEmpty) return 'Formel darf nicht leer sein';
      final rpn = _toRpn(tokens);
      if (rpn.isEmpty) return 'Ungültige Formel';
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Extracts all distinct variable names referenced in the formula in order of appearance.
  static List<String> extractVariables(String formula) {
    try {
      final tokens = _tokenize(formula);
      final vars = <String>[];
      for (final t in tokens) {
        if (t.type == _TokenType.identifier && !vars.contains(t.text)) {
          vars.add(t.text);
        }
      }
      return vars;
    } catch (_) {
      return const [];
    }
  }

  /// Evaluates the formula using the provided variable values.
  /// Throws [FormulaSyntaxException], [MissingVariableException], or [DivisionByZeroException].
  static double evaluate(String formula, Map<String, double> variables) {
    if (formula.trim().isEmpty) {
      throw const FormulaSyntaxException('Formel darf nicht leer sein');
    }
    final tokens = _tokenize(formula);
    final rpn = _toRpn(tokens);
    return _evaluateRpn(rpn, variables);
  }

  static List<_Token> _tokenize(String expression) {
    final tokens = <_Token>[];
    var i = 0;
    final length = expression.length;

    while (i < length) {
      final char = expression[i];

      if (char.trim().isEmpty) {
        i++;
        continue;
      }

      if (char == '+') {
        tokens.add(_Token(_TokenType.plus, '+'));
        i++;
      } else if (char == '-') {
        // Unary minus detection: if it's at start or after an operator or '('
        final isUnary =
            tokens.isEmpty ||
            tokens.last.type == _TokenType.plus ||
            tokens.last.type == _TokenType.minus ||
            tokens.last.type == _TokenType.multiply ||
            tokens.last.type == _TokenType.divide ||
            tokens.last.type == _TokenType.openParen;

        if (isUnary) {
          // Check if followed immediately by a number
          var nextIndex = i + 1;
          while (nextIndex < length && expression[nextIndex].trim().isEmpty) {
            nextIndex++;
          }
          if (nextIndex < length && _isDigit(expression[nextIndex])) {
            var numStr = '-';
            i = nextIndex;
            var hasDot = false;
            while (i < length) {
              final c = expression[i];
              if (_isDigit(c)) {
                numStr += c;
                i++;
              } else if (c == '.' && !hasDot) {
                hasDot = true;
                numStr += c;
                i++;
              } else {
                break;
              }
            }
            final val = double.tryParse(numStr);
            if (val == null) {
              throw FormulaSyntaxException('Ungültige Zahl: $numStr');
            }
            tokens.add(_Token(_TokenType.number, numStr, val));
            continue;
          } else {
            // Unary minus as (0 - x)
            tokens.add(_Token(_TokenType.number, '0', 0.0));
            tokens.add(_Token(_TokenType.minus, '-'));
            i++;
            continue;
          }
        } else {
          tokens.add(_Token(_TokenType.minus, '-'));
          i++;
        }
      } else if (char == '*') {
        tokens.add(_Token(_TokenType.multiply, '*'));
        i++;
      } else if (char == '/') {
        tokens.add(_Token(_TokenType.divide, '/'));
        i++;
      } else if (char == '(') {
        tokens.add(_Token(_TokenType.openParen, '('));
        i++;
      } else if (char == ')') {
        tokens.add(_Token(_TokenType.closeParen, ')'));
        i++;
      } else if (_isDigit(char) || char == '.') {
        var numStr = '';
        var hasDot = false;
        while (i < length) {
          final c = expression[i];
          if (_isDigit(c)) {
            numStr += c;
            i++;
          } else if (c == '.' && !hasDot) {
            hasDot = true;
            numStr += c;
            i++;
          } else {
            break;
          }
        }
        final val = double.tryParse(numStr);
        if (val == null) {
          throw FormulaSyntaxException('Ungültige Zahl: $numStr');
        }
        tokens.add(_Token(_TokenType.number, numStr, val));
      } else if (_isIdentStart(char)) {
        var ident = '';
        while (i < length && _isIdentPart(expression[i])) {
          ident += expression[i];
          i++;
        }
        tokens.add(_Token(_TokenType.identifier, ident));
      } else {
        throw FormulaSyntaxException('Unerwartetes Zeichen: "$char"');
      }
    }

    return tokens;
  }

  static bool _isDigit(String s) {
    if (s.isEmpty) return false;
    final code = s.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  static bool _isIdentStart(String s) {
    if (s.isEmpty) return false;
    final code = s.codeUnitAt(0);
    return (code >= 65 && code <= 90) || // A-Z
        (code >= 97 && code <= 122) || // a-z
        code == 95; // _
  }

  static bool _isIdentPart(String s) {
    return _isIdentStart(s) || _isDigit(s);
  }

  static int _precedence(_TokenType type) {
    switch (type) {
      case _TokenType.plus:
      case _TokenType.minus:
        return 1;
      case _TokenType.multiply:
      case _TokenType.divide:
        return 2;
      default:
        return 0;
    }
  }

  static List<_Token> _toRpn(List<_Token> tokens) {
    final output = <_Token>[];
    final operatorStack = <_Token>[];

    _Token? lastToken;
    for (final token in tokens) {
      switch (token.type) {
        case _TokenType.number:
        case _TokenType.identifier:
          if (lastToken != null &&
              (lastToken.type == _TokenType.number ||
                  lastToken.type == _TokenType.identifier ||
                  lastToken.type == _TokenType.closeParen)) {
            throw const FormulaSyntaxException(
              'Fehlender Operator zwischen Operanden',
            );
          }
          output.add(token);
          break;

        case _TokenType.plus:
        case _TokenType.minus:
        case _TokenType.multiply:
        case _TokenType.divide:
          if (lastToken == null ||
              lastToken.type == _TokenType.plus ||
              lastToken.type == _TokenType.minus ||
              lastToken.type == _TokenType.multiply ||
              lastToken.type == _TokenType.divide ||
              lastToken.type == _TokenType.openParen) {
            throw const FormulaSyntaxException('Unerwarteter Operator');
          }
          while (operatorStack.isNotEmpty &&
              operatorStack.last.type != _TokenType.openParen &&
              _precedence(operatorStack.last.type) >= _precedence(token.type)) {
            output.add(operatorStack.removeLast());
          }
          operatorStack.add(token);
          break;

        case _TokenType.openParen:
          operatorStack.add(token);
          break;

        case _TokenType.closeParen:
          if (lastToken != null &&
              (lastToken.type == _TokenType.plus ||
                  lastToken.type == _TokenType.minus ||
                  lastToken.type == _TokenType.multiply ||
                  lastToken.type == _TokenType.divide ||
                  lastToken.type == _TokenType.openParen)) {
            throw const FormulaSyntaxException(
              'Unerwartete schließende Klammer',
            );
          }
          var foundOpen = false;
          while (operatorStack.isNotEmpty) {
            final top = operatorStack.removeLast();
            if (top.type == _TokenType.openParen) {
              foundOpen = true;
              break;
            }
            output.add(top);
          }
          if (!foundOpen) {
            throw const FormulaSyntaxException('Fehlende öffnende Klammer');
          }
          break;
      }
      lastToken = token;
    }

    if (lastToken != null &&
        (lastToken.type == _TokenType.plus ||
            lastToken.type == _TokenType.minus ||
            lastToken.type == _TokenType.multiply ||
            lastToken.type == _TokenType.divide)) {
      throw const FormulaSyntaxException(
        'Ausdruck darf nicht mit Operator enden',
      );
    }

    while (operatorStack.isNotEmpty) {
      final top = operatorStack.removeLast();
      if (top.type == _TokenType.openParen) {
        throw const FormulaSyntaxException('Nicht geschlossene Klammer');
      }
      output.add(top);
    }

    return output;
  }

  static double _evaluateRpn(List<_Token> rpn, Map<String, double> variables) {
    final stack = <double>[];

    for (final token in rpn) {
      if (token.type == _TokenType.number) {
        stack.add(token.numberValue!);
      } else if (token.type == _TokenType.identifier) {
        if (!variables.containsKey(token.text)) {
          throw MissingVariableException(token.text);
        }
        final val = variables[token.text];
        if (val == null) {
          throw MissingVariableException(token.text);
        }
        stack.add(val);
      } else {
        if (stack.length < 2) {
          throw const FormulaSyntaxException(
            'Ungenügend Operanden für Operation',
          );
        }
        final b = stack.removeLast();
        final a = stack.removeLast();

        double res;
        switch (token.type) {
          case _TokenType.plus:
            res = a + b;
            break;
          case _TokenType.minus:
            res = a - b;
            break;
          case _TokenType.multiply:
            res = a * b;
            break;
          case _TokenType.divide:
            if (b == 0.0) {
              throw const DivisionByZeroException();
            }
            res = a / b;
            break;
          default:
            throw FormulaSyntaxException('Unbekannter Operator: ${token.text}');
        }
        stack.add(res);
      }
    }

    if (stack.length != 1) {
      throw const FormulaSyntaxException('Ungültiger mathematischer Ausdruck');
    }

    return stack.single;
  }
}
