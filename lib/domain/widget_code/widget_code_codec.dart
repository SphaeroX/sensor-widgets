import 'dart:convert';

import 'package:sensor_widgets/domain/formula/formula_evaluator.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/sensor_query_item.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/l10n/formula_error_text.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

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
  /// Error messages are in the language of [l10n].
  static WidgetCodeResult decode(
    String code, {
    required WidgetDefinition base,
    required AppLocalizations l10n,
  }) {
    final Object? parsed;
    try {
      parsed = jsonDecode(_stripFence(code));
    } on FormatException catch (e) {
      return WidgetCodeResult.failure([l10n.codeErrorInvalidJson(e.message)]);
    }
    if (parsed is! Map<String, dynamic>) {
      return WidgetCodeResult.failure([l10n.codeErrorNotObject]);
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
        l10n.codeErrorUnknownType('${json['type']}', '${e.message}'),
      ]);
    } on TypeError catch (e) {
      return WidgetCodeResult.failure([l10n.codeErrorWrongType('$e')]);
    }

    final errors = _validate(def, l10n);
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

  static List<String> _validate(WidgetDefinition def, AppLocalizations l10n) {
    final errors = <String>[];
    if (def.measurement.trim().isEmpty) {
      errors.add(l10n.codeErrorMeasurementMissing);
    }
    if (def.gapPolicy != null &&
        def.gapPolicy != 'skip' &&
        def.gapPolicy != 'previous') {
      errors.add(l10n.codeErrorGapPolicy);
    }
    if (def.chartStyle != null && !def.chartStyle!.isValid) {
      errors.add(l10n.codeErrorChartStyle);
    }
    if (def.appearance != null && !def.appearance!.isValid) {
      errors.add(l10n.codeErrorAppearance);
    }

    final hasFormula = def.formula != null && def.formula!.trim().isNotEmpty;
    if (hasFormula) {
      errors.addAll(
        _validateFormula(
          l10n.codeFormulaMain,
          def.formula!,
          def.formulaSteps,
          def.formulaVariables,
          l10n,
        ),
      );
    }
    for (final item in def.items ?? const <SensorQueryItem>[]) {
      if (!item.hasFormula) continue;
      errors.addAll(
        _validateFormula(
          l10n.codeFormulaRow(item.label ?? item.field),
          item.formula!,
          item.formulaSteps,
          item.formulaVariables,
          l10n,
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
      errors.add(l10n.codeErrorIncomplete);
    }
    return errors;
  }

  static List<String> _validateFormula(
    String what,
    String formula,
    List<FormulaStep>? steps,
    List<FormulaVariable>? variables,
    AppLocalizations l10n,
  ) {
    final syntax = FormulaEvaluator.syntaxError(formula);
    if (syntax != null) {
      final text = formulaErrorText(l10n, syntax, withPosition: true);
      return [l10n.codeErrorFormulaSyntax(what, text)];
    }
    final vars = variables ?? const <FormulaVariable>[];
    if (vars.isEmpty) return [l10n.codeErrorNoVariable(what)];
    final errors = <String>[];
    for (final v in vars.where((v) => v.field.trim().isEmpty)) {
      errors.add(l10n.codeErrorVariableNoField(what, v.name));
    }
    final stepErr = FormulaEvaluator.stepsError(
      steps ?? const [],
      formula,
      variableNames: vars.map((v) => v.name).toList(),
    );
    if (stepErr != null) {
      errors.add(l10n.codeErrorFormula(what, formulaErrorText(l10n, stepErr)));
    }
    return errors;
  }
}
