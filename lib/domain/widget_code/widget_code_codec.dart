import 'dart:convert';

import 'package:sensor_widgets/domain/formula/formula_evaluator.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/sensor_query_item.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';

/// Outcome of [WidgetCodeCodec.decode]: either a [definition] or [errors].
class WidgetCodeResult {
  final WidgetDefinition? definition;
  final List<String> errors;

  const WidgetCodeResult.success(WidgetDefinition this.definition)
    : errors = const [];

  const WidgetCodeResult.failure(this.errors) : definition = null;

  bool get ok => definition != null;
}

/// Converts a widget to and from its "widget as code" text: the widget
/// definition JSON without the app-internal `id` and `connectionId`.
class WidgetCodeCodec {
  WidgetCodeCodec._();

  static const _internalKeys = {'id', 'connectionId'};

  static String encode(WidgetDefinition definition) {
    final map = definition.toJson()
      ..removeWhere((key, _) => _internalKeys.contains(key));
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Parses [code] on top of [base]: `id` and `connectionId` always come from
  /// [base]; `measurement` and `title` fall back to it when the code omits them.
  static WidgetCodeResult decode(
    String code, {
    required WidgetDefinition base,
  }) {
    final Object? parsed;
    try {
      parsed = jsonDecode(_stripFence(code));
    } on FormatException catch (e) {
      return WidgetCodeResult.failure(['Kein gültiges JSON: ${e.message}']);
    }
    if (parsed is! Map<String, dynamic>) {
      return const WidgetCodeResult.failure([
        'Der Code muss ein JSON-Objekt sein.',
      ]);
    }

    final json = <String, dynamic>{
      'title': base.title.trim().isEmpty ? 'Widget' : base.title,
      'measurement': base.measurement,
      ...parsed,
      'id': base.id,
      'connectionId': base.connectionId,
    };
    final type = json['type'];
    if (type == null) {
      json['type'] = base.type.toJson();
    }

    final WidgetDefinition def;
    try {
      def = WidgetDefinition.fromJson(json);
    } on ArgumentError catch (e) {
      return WidgetCodeResult.failure([
        'Unbekannter Widget-Typ "${json['type']}" (${e.message}).',
      ]);
    } on TypeError catch (e) {
      return WidgetCodeResult.failure(['Ein Wert hat den falschen Typ: $e']);
    }

    final errors = _validate(def);
    return errors.isEmpty
        ? WidgetCodeResult.success(def)
        : WidgetCodeResult.failure(errors);
  }

  static String _stripFence(String code) {
    final trimmed = code.trim();
    final fence = RegExp(r'^```[A-Za-z]*\s*\n([\s\S]*?)\n?```$');
    final match = fence.firstMatch(trimmed);
    return match != null ? match.group(1)! : trimmed;
  }

  static List<String> _validate(WidgetDefinition def) {
    final errors = <String>[];
    if (def.measurement.trim().isEmpty) {
      errors.add('Measurement fehlt.');
    }
    if (def.gapPolicy != null &&
        def.gapPolicy != 'skip' &&
        def.gapPolicy != 'previous') {
      errors.add('gapPolicy muss "skip" oder "previous" sein.');
    }
    if (def.chartStyle != null && !def.chartStyle!.isValid) {
      errors.add(
        'chartStyle ist ungültig (Farben als #RRGGBB, lineWidth > 0).',
      );
    }
    if (def.appearance != null && !def.appearance!.isValid) {
      errors.add(
        'appearance ist ungültig (Farben als #RRGGBB, Werte im Bereich).',
      );
    }

    final hasFormula = def.formula != null && def.formula!.trim().isNotEmpty;
    if (hasFormula) {
      errors.addAll(
        _validateFormula(
          'Formel',
          def.formula!,
          def.formulaSteps,
          def.formulaVariables,
        ),
      );
    }
    for (final item in def.items ?? const <SensorQueryItem>[]) {
      if (!item.hasFormula) continue;
      errors.addAll(
        _validateFormula(
          'Formel der Zeile "${item.label ?? item.field}"',
          item.formula!,
          item.formulaSteps,
          item.formulaVariables,
        ),
      );
    }

    final hasRows = (def.items ?? const <SensorQueryItem>[]).isNotEmpty;
    final hasField = def.field != null && def.field!.trim().isNotEmpty;
    final complete = hasFormula
        ? true
        : def.type == WidgetType.multiValue
        ? hasRows
        : hasField;
    if (errors.isEmpty && !complete) {
      errors.add(
        'Das Widget ist unvollständig: ohne Formel wird ein "field" '
        '(bzw. "items" bei multi_value) benötigt.',
      );
    }
    return errors;
  }

  static List<String> _validateFormula(
    String what,
    String formula,
    List<FormulaStep>? steps,
    List<FormulaVariable>? variables,
  ) {
    final syntax = FormulaEvaluator.validateSyntax(formula);
    if (syntax != null) return ['$what: Syntaxfehler: $syntax'];
    final vars = variables ?? const <FormulaVariable>[];
    if (vars.isEmpty) return ['$what: Es ist keine Variable definiert.'];
    final errors = <String>[];
    for (final v in vars.where((v) => v.field.trim().isEmpty)) {
      errors.add('$what: Variable ${v.name} hat kein Feld.');
    }
    final stepErr = FormulaEvaluator.validateSteps(
      steps ?? const [],
      formula,
      variableNames: vars.map((v) => v.name).toList(),
    );
    if (stepErr != null) errors.add('$what: $stepErr');
    return errors;
  }
}
