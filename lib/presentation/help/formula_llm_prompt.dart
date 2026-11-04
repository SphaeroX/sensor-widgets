import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';
import 'package:sensor_widgets/presentation/help/formula_help_content.dart';
import 'package:sensor_widgets/presentation/help/formula_llm_prompt_texts.dart';

/// Builds a prompt the user pastes into an LLM so that it writes formulas in
/// the app's formula language. The language reference comes from
/// [formulaHelpEntries], so the prompt cannot drift from the evaluator.
///
/// The prompt is written in the language of [l10n] (English fallback), so the
/// LLM answers in the user's language.
String buildFormulaLlmPrompt({
  required AppLocalizations l10n,
  String? measurement,
  List<String> availableMeasurements = const [],
  List<InfluxFieldInfo> availableFields = const [],
  bool supportsSteps = true,
}) {
  final t = PromptTexts.of(l10n);
  final b = StringBuffer()
    ..writeln(t.formulaIntro)
    ..writeln();
  _writeLanguage(b, t, l10n);
  if (supportsSteps) {
    b
      ..writeln()
      ..writeln(t.stepsHeading)
      ..writeln(t.stepsBody);
  }
  b.writeln();
  _writeData(b, t, measurement, availableMeasurements, availableFields);
  b
    ..writeln()
    ..writeln(t.processHeading)
    ..writeln(t.processOk)
    ..writeln(t.formulaProcessDescribe)
    ..writeln(t.formulaProcessFormula);
  if (supportsSteps) b.writeln(t.formulaProcessSteps);
  b
    ..writeln(t.formulaProcessMapping)
    ..writeln(t.formulaProcessOnlyFormula);
  return b.toString().trimRight();
}

/// Builds the prompt for the "widget as code" feature: the LLM returns the
/// complete widget as one JSON block that the user pastes into the editor.
String buildWidgetCodePrompt({
  required AppLocalizations l10n,
  String? measurement,
  List<String> availableMeasurements = const [],
  List<InfluxFieldInfo> availableFields = const [],
  String? currentCode,
}) {
  final t = PromptTexts.of(l10n);
  final b = StringBuffer()
    ..writeln(t.widgetCodeIntro)
    ..writeln();
  _writeLanguage(b, t, l10n);
  b
    ..writeln()
    ..writeln(t.widgetCodeSpec)
    ..writeln();
  _writeData(b, t, measurement, availableMeasurements, availableFields);
  if (currentCode != null && currentCode.trim().isNotEmpty) {
    b
      ..writeln()
      ..writeln(t.currentCodeHeading)
      ..writeln(t.currentCodeBody)
      ..writeln('```json')
      ..writeln(currentCode.trim())
      ..writeln('```');
  }
  b
    ..writeln()
    ..writeln(t.processHeading)
    ..writeln(t.processOk)
    ..writeln(t.widgetCodeProcessDescribe)
    ..writeln(t.widgetCodeProcessFieldsOnly);
  return b.toString().trimRight();
}

void _writeLanguage(StringBuffer b, PromptTexts t, AppLocalizations l10n) {
  b
    ..writeln(t.languageHeading)
    ..writeln(t.languageNumbers)
    ..writeln(t.languageOperators)
    ..writeln(t.languageComparisons)
    ..writeln(t.languageVariableNames)
    ..writeln(t.languageFunctionsIntro);
  for (final e in formulaHelpEntries(l10n)) {
    b.writeln(
      '  - ${e.signature}: ${e.description} ${t.exampleLabel}: ${e.example}',
    );
  }
  b
    ..writeln(t.languageErrors)
    ..writeln(t.languageNotAllowed);
}

void _writeData(
  StringBuffer b,
  PromptTexts t,
  String? measurement,
  List<String> availableMeasurements,
  List<InfluxFieldInfo> availableFields,
) {
  b.writeln(t.dataHeading);
  final hasSchema =
      measurement != null && measurement.isNotEmpty ||
      availableMeasurements.isNotEmpty ||
      availableFields.isNotEmpty;
  if (!hasSchema) {
    b.writeln(t.dataNoSchema);
    return;
  }
  if (measurement != null && measurement.isNotEmpty) {
    b.writeln('${t.dataCurrentMeasurement}: $measurement');
  }
  if (availableMeasurements.isNotEmpty) {
    b.writeln(
      '${t.dataAvailableMeasurements}: ${availableMeasurements.join(', ')}',
    );
  }
  if (availableFields.isNotEmpty) {
    b.writeln(t.dataAvailableFields);
    for (final f in availableFields) {
      final note = f.isNumeric ? '' : t.dataNotNumeric;
      b.writeln('- ${f.key} (${f.type}$note)');
    }
  }
  b.writeln(t.dataMapping);
}
