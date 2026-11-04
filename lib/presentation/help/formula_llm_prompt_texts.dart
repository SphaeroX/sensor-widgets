import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// Text blocks of the LLM prompts, one set per app language.
///
/// The prompts are long technical documents with JSON examples, whose braces
/// would clash with the ICU placeholder syntax of the ARB files, so they live
/// here instead of in `lib/l10n/`. A new app language adds a set to [_byLanguage];
/// languages without a set use English.
class PromptTexts {
  final String formulaIntro;
  final String widgetCodeIntro;
  final String stepsHeading;
  final String stepsBody;
  final String processHeading;
  final String processOk;
  final String formulaProcessDescribe;
  final String formulaProcessFormula;
  final String formulaProcessSteps;
  final String formulaProcessMapping;
  final String formulaProcessOnlyFormula;
  final String widgetCodeProcessDescribe;
  final String widgetCodeProcessFieldsOnly;
  final String currentCodeHeading;
  final String currentCodeBody;
  final String languageHeading;
  final String languageNumbers;
  final String languageOperators;
  final String languageComparisons;
  final String languageVariableNames;
  final String languageFunctionsIntro;
  final String exampleLabel;
  final String languageErrors;
  final String languageNotAllowed;
  final String dataHeading;
  final String dataNoSchema;
  final String dataCurrentMeasurement;
  final String dataAvailableMeasurements;
  final String dataAvailableFields;
  final String dataNotNumeric;
  final String dataMapping;
  final String widgetCodeSpec;

  const PromptTexts({
    required this.formulaIntro,
    required this.widgetCodeIntro,
    required this.stepsHeading,
    required this.stepsBody,
    required this.processHeading,
    required this.processOk,
    required this.formulaProcessDescribe,
    required this.formulaProcessFormula,
    required this.formulaProcessSteps,
    required this.formulaProcessMapping,
    required this.formulaProcessOnlyFormula,
    required this.widgetCodeProcessDescribe,
    required this.widgetCodeProcessFieldsOnly,
    required this.currentCodeHeading,
    required this.currentCodeBody,
    required this.languageHeading,
    required this.languageNumbers,
    required this.languageOperators,
    required this.languageComparisons,
    required this.languageVariableNames,
    required this.languageFunctionsIntro,
    required this.exampleLabel,
    required this.languageErrors,
    required this.languageNotAllowed,
    required this.dataHeading,
    required this.dataNoSchema,
    required this.dataCurrentMeasurement,
    required this.dataAvailableMeasurements,
    required this.dataAvailableFields,
    required this.dataNotNumeric,
    required this.dataMapping,
    required this.widgetCodeSpec,
  });

  static const Map<String, PromptTexts> _byLanguage = {
    'en': _english,
    'de': _german,
  };

  /// The set for the language of [l10n], English if there is none.
  static PromptTexts of(AppLocalizations l10n) =>
      _byLanguage[l10n.localeName.split('_').first] ?? _english;
}

const PromptTexts _english = PromptTexts(
  formulaIntro:
      'You are an assistant that writes calculation formulas for a '
      'sensor widget app. The formulas combine readings from InfluxDB '
      'before they are displayed. Read the rules first.',
  widgetCodeIntro:
      'You are an assistant that writes complete widgets for a sensor widget '
      'app as JSON code. The widgets show readings from InfluxDB, optionally '
      'combined by a formula. Read the rules first.',
  stepsHeading: '## Intermediate steps (optional)',
  stepsBody:
      'You may split complex formulas into named intermediate steps. '
      'Each step has a name (like a variable name) and an expression. Steps '
      'are calculated from top to bottom and may use variables and earlier '
      'steps. The main formula is the result and may use all steps. Only use '
      'steps if they make the formula clearly more readable.',
  processHeading: '## Your process',
  processOk:
      '1. Reply only with "OK" now if you have understood the rules. '
      'Do not write anything else.',
  formulaProcessDescribe:
      '2. Then I describe what should be calculated. Reply in exactly '
      'this format and without explanations:',
  formulaProcessFormula:
      '   - Formula: only the formula in a code block, ready to copy.',
  formulaProcessSteps:
      '   - Intermediate steps (only if used): one `name = expression` '
      'per line in its own code block.',
  formulaProcessMapping:
      '   - Variable mapping: a list "variable -> field '
      '(measurement, tag filters if needed)" that tells me which variable '
      'I have to assign to which field in the app.',
  formulaProcessOnlyFormula:
      '3. Use only the functions allowed above and output only the '
      'formula, no prose around it.',
  widgetCodeProcessDescribe:
      '2. Then I describe what the widget should show. Reply with exactly '
      'one JSON code block that contains the complete widget (type, formula, '
      'intermediate steps, variables with fields, display). No explanations '
      'before or after the code block.',
  widgetCodeProcessFieldsOnly:
      '3. Use only fields from the available data and only the allowed '
      'functions. If information is missing, ask briefly instead of '
      'guessing.',
  currentCodeHeading: '## Current widget code',
  currentCodeBody:
      'This is what the widget looks like at the moment. If I ask for a '
      'change, return the complete changed code:',
  languageHeading: '## Formula language',
  languageNumbers:
      '- Numbers (decimal point, e.g. 1.8), variables, parentheses.',
  languageOperators: '- Operators: + - * / and unary minus.',
  languageComparisons:
      '- Comparisons: < > <= >= == != (result 1 = true, 0 = false).',
  languageVariableNames:
      '- Variable names: letters, digits and _, not starting with a digit '
      '(e.g. A, co2, temp_in). Case matters.',
  languageFunctionsIntro: '- There are no functions other than these:',
  exampleLabel: 'Example',
  languageErrors:
      '- Errors such as division by zero or sqrt of a negative number '
      'never silently become 0, so guard with if(...) when needed, '
      'e.g. if(B == 0, 0, A / B).',
  languageNotAllowed:
      '- Not allowed: variables with dots or spaces, strings, '
      'assignments, semicolons, functions outside the list.',
  dataHeading: '## Available data (selected environment)',
  dataNoSchema:
      'No schema information is available. Ask for the field names '
      'or use descriptive variable names and tell me which fields '
      'I have to assign.',
  dataCurrentMeasurement: 'Current measurement',
  dataAvailableMeasurements: 'Available measurements',
  dataAvailableFields: 'Available fields (type):',
  dataNotNumeric: ', not numeric, not usable',
  dataMapping:
      'Every variable of the formula is assigned to one of these fields in '
      'the app (optionally with another measurement or tag filters). '
      'Use only numeric fields.',
  widgetCodeSpec: '''
## Widget code (JSON)
A widget is described as one JSON object. All keys except "type" are optional unless stated otherwise. The app adds id and connection itself; do not write them.

General (all types):
- "type": one of single_value, history_chart, indicator_lamp, multi_value, aggregate, gauge_bar.
- "title": title of the widget.
- "measurement": measurement; if omitted, the currently selected one is used.
- "unit": unit, e.g. "°C". "decimalPlaces": 0 to 2. "refreshIntervalMinutes": whole number, default 15.
- "tagFilters": object {"tag": "value"}, narrows the query.
- "formula": main formula (string). "formulaSteps": list of {"name", "expression"}. "formulaVariables": list of {"name", "field", optional "measurement", "tagFilters", "label"}. With a formula the widget has no "field"; every variable used in the formula or the steps needs an entry in "formulaVariables" with a field from the list of available data.
- "appearance" (optional): {"backgroundColor", "textColor", "accentColor" as "#RRGGBB", "backgroundOpacity" 0 to 1, "fontScale" 0.8 to 1.4, "cornerRadius" 0 to 32}.
- "alerts" (optional): push notifications [{"target", "operator" ("greaterThan" or "lessThan"), "value": number}]. "target" is "value" for the (calculated) main value, for multi_value the "field" of a row, for aggregate "min", "max" or "mean".

Per type:
- single_value: without a formula, give "field".
- history_chart: "timeRange" (1h, 6h, 24h, 7d, 30d), "aggregationInterval" (1m, 5m, 15m, 1h, 1d), "gapPolicy" ("skip" skips buckets with missing values, "previous" carries the last value over), "chartStyle": {"colorStops": [{"value": number, "color": "#RRGGBB"}], "fillArea", "showGrid", "showAxes", "markMinMax" (booleans), "lineWidth": number greater than 0}. The line is colored by value between the colorStops.
- aggregate: "timeRange" as above; shows min, max and average, with a formula calculated per bucket ("gapPolicy" as above).
- gauge_bar: "min" and "max" of the scale.
- indicator_lamp: "threshold": {"operator": "greaterThan" or "lessThan", "value": number, "color": "#RRGGBB"}.
- multi_value: "items": list of rows {"field", "label", "unit", "decimalPlaces"}. A calculated row also gets "formula", "formulaVariables" and optionally "formulaSteps"; its "field" is then just a unique name such as "formula_1". The top-level formula keys are not used for multi_value.

Example (history chart with intermediate steps):
```json
{
  "type": "history_chart",
  "title": "Air quality",
  "timeRange": "24h",
  "aggregationInterval": "1h",
  "gapPolicy": "previous",
  "formula": "min(s_co2, s_rh)",
  "formulaSteps": [
    {"name": "s_co2", "expression": "clamp(100 * (2000 - co2) / 1400, 0, 100)"},
    {"name": "s_rh", "expression": "clamp(100 - 100 * abs(rh - 50) / 30, 0, 100)"}
  ],
  "formulaVariables": [
    {"name": "co2", "field": "co2", "label": "CO₂ (ppm)"},
    {"name": "rh", "field": "humidity", "label": "Rel. humidity (%)"}
  ],
  "chartStyle": {
    "colorStops": [
      {"value": 0, "color": "#F44336"},
      {"value": 50, "color": "#FFC107"},
      {"value": 100, "color": "#4CAF50"}
    ],
    "fillArea": true,
    "showAxes": true
  }
}
```''',
);

const PromptTexts _german = PromptTexts(
  formulaIntro:
      'Du bist ein Assistent, der Berechnungsformeln für eine '
      'Sensor-Widget-App schreibt. Die Formeln verrechnen Messwerte aus '
      'InfluxDB, bevor sie angezeigt werden. Lies zuerst die Regeln.',
  widgetCodeIntro:
      'Du bist ein Assistent, der komplette Widgets für eine Sensor-Widget-App '
      'als JSON-Code schreibt. Die Widgets zeigen Messwerte aus InfluxDB, '
      'optional per Formel verrechnet. Lies zuerst die Regeln.',
  stepsHeading: '## Zwischenschritte (optional)',
  stepsBody:
      'Komplexe Formeln darfst du in benannte Zwischenschritte zerlegen. '
      'Jeder Schritt hat einen Namen (wie ein Variablenname) und einen '
      'Ausdruck. Schritte werden von oben nach unten berechnet und dürfen '
      'Variablen und frühere Schritte verwenden. Die Hauptformel ist das '
      'Ergebnis und darf alle Schritte verwenden. Nutze Schritte nur, wenn '
      'sie die Formel deutlich lesbarer machen.',
  processHeading: '## Dein Ablauf',
  processOk:
      '1. Antworte jetzt nur mit "OK", wenn du die Regeln verstanden hast. '
      'Schreibe sonst nichts.',
  formulaProcessDescribe:
      '2. Danach beschreibe ich, was berechnet werden soll. Antworte dann '
      'in genau diesem Format und ohne Erklärungen:',
  formulaProcessFormula:
      '   - Formel: nur die Formel in einem Codeblock, zum Kopieren.',
  formulaProcessSteps:
      '   - Zwischenschritte (nur falls verwendet): je Zeile '
      '`name = ausdruck` in einem eigenen Codeblock.',
  formulaProcessMapping:
      '   - Variablen-Zuweisung: eine Liste "Variable -> Feld '
      '(Measurement, Tag-Filter falls nötig)", die mir sagt, welche Variable '
      'ich in der App welchem Feld zuweisen muss.',
  formulaProcessOnlyFormula:
      '3. Verwende ausschließlich die oben erlaubten Funktionen und gib nur '
      'die Formel aus, keine Prosa um sie herum.',
  widgetCodeProcessDescribe:
      '2. Danach beschreibe ich, was das Widget zeigen soll. Antworte dann '
      'mit genau einem JSON-Codeblock, der das komplette Widget enthält '
      '(Typ, Formel, Zwischenschritte, Variablen mit Feldern, Darstellung). '
      'Keine Erklärungen vor oder nach dem Codeblock.',
  widgetCodeProcessFieldsOnly:
      '3. Nutze nur Felder aus den verfügbaren Daten und nur die erlaubten '
      'Funktionen. Fehlt dir eine Information, frage kurz nach, statt zu '
      'raten.',
  currentCodeHeading: '## Aktueller Widget-Code',
  currentCodeBody:
      'Das Widget sieht im Moment so aus. Wenn ich eine Änderung '
      'wünsche, gib den kompletten geänderten Code zurück:',
  languageHeading: '## Formelsprache',
  languageNumbers: '- Zahlen (Dezimalpunkt, z. B. 1.8), Variablen, Klammern.',
  languageOperators: '- Operatoren: + - * / sowie unäres Minus.',
  languageComparisons:
      '- Vergleiche: < > <= >= == != (Ergebnis 1 = wahr, 0 = falsch).',
  languageVariableNames:
      '- Variablennamen: Buchstaben, Ziffern und _, nicht mit einer Ziffer '
      'beginnend (z. B. A, co2, temp_in). Groß-/Kleinschreibung zählt.',
  languageFunctionsIntro: '- Es gibt keine weiteren Funktionen als diese:',
  exampleLabel: 'Beispiel',
  languageErrors:
      '- Fehler wie Division durch Null oder sqrt einer negativen Zahl '
      'werden nie still zu 0, daher bei Bedarf mit if(...) absichern, '
      'z. B. if(B == 0, 0, A / B).',
  languageNotAllowed:
      '- Nicht erlaubt: Variablen mit Punkt oder Leerzeichen, Strings, '
      'Zuweisungen, Semikolons, Funktionen außerhalb der Liste.',
  dataHeading: '## Verfügbare Daten (ausgewählte Umgebung)',
  dataNoSchema:
      'Es liegen keine Schema-Informationen vor. Frage nach den Feldnamen '
      'oder nutze sprechende Variablennamen und sage mir, welche Felder '
      'ich zuweisen muss.',
  dataCurrentMeasurement: 'Aktuelles Measurement',
  dataAvailableMeasurements: 'Verfügbare Measurements',
  dataAvailableFields: 'Verfügbare Felder (Typ):',
  dataNotNumeric: ', nicht numerisch, nicht verwendbar',
  dataMapping:
      'Jede Variable der Formel wird in der App einem dieser Felder '
      'zugewiesen (optional mit anderem Measurement oder Tag-Filtern). '
      'Nutze nur numerische Felder.',
  widgetCodeSpec: '''
## Widget-Code (JSON)
Ein Widget wird als ein JSON-Objekt beschrieben. Alle Schlüssel außer "type" sind optional, solange nichts anderes dabeisteht. Die App ergänzt id und Verbindung selbst; schreibe sie nicht.

Allgemein (alle Typen):
- "type": einer von single_value, history_chart, indicator_lamp, multi_value, aggregate, gauge_bar.
- "title": Titel des Widgets.
- "measurement": Measurement; ohne Angabe gilt das aktuell gewählte.
- "unit": Einheit, z. B. "°C". "decimalPlaces": 0 bis 2. "refreshIntervalMinutes": ganze Zahl, Standard 15.
- "tagFilters": Objekt {"tag": "wert"}, schränkt die Abfrage ein.
- "formula": Hauptformel (String). "formulaSteps": Liste von {"name", "expression"}. "formulaVariables": Liste von {"name", "field", optional "measurement", "tagFilters", "label"}. Mit Formel entfällt "field" am Widget; jede in der Formel oder den Schritten benutzte Variable braucht einen Eintrag in "formulaVariables" mit einem Feld aus der Liste der verfügbaren Daten.
- "appearance" (optional): {"backgroundColor", "textColor", "accentColor" als "#RRGGBB", "backgroundOpacity" 0 bis 1, "fontScale" 0.8 bis 1.4, "cornerRadius" 0 bis 32}.
- "alerts" (optional): Push-Benachrichtigungen [{"target", "operator" ("greaterThan" oder "lessThan"), "value": Zahl}]. "target" ist "value" für den (berechneten) Hauptwert, bei multi_value das "field" einer Zeile, bei aggregate "min", "max" oder "mean".

Je nach Typ:
- single_value: ohne Formel "field" angeben.
- history_chart: "timeRange" (1h, 6h, 24h, 7d, 30d), "aggregationInterval" (1m, 5m, 15m, 1h, 1d), "gapPolicy" ("skip" überspringt Buckets mit fehlenden Werten, "previous" übernimmt den letzten Wert), "chartStyle": {"colorStops": [{"value": Zahl, "color": "#RRGGBB"}], "fillArea", "showGrid", "showAxes", "markMinMax" (Wahrheitswerte), "lineWidth": Zahl größer 0}. Die Linie wird je nach Wert zwischen den colorStops eingefärbt.
- aggregate: "timeRange" wie oben; zeigt min, max und Mittelwert, bei Formel pro Bucket berechnet ("gapPolicy" wie oben).
- gauge_bar: "min" und "max" der Skala.
- indicator_lamp: "threshold": {"operator": "greaterThan" oder "lessThan", "value": Zahl, "color": "#RRGGBB"}.
- multi_value: "items": Liste von Zeilen {"field", "label", "unit", "decimalPlaces"}. Eine berechnete Zeile bekommt zusätzlich "formula", "formulaVariables" und optional "formulaSteps"; ihr "field" ist dann nur ein eindeutiger Name wie "formula_1". Die Formel-Schlüssel auf oberster Ebene entfallen bei multi_value.

Beispiel (Verlaufschart mit Zwischenschritten):
```json
{
  "type": "history_chart",
  "title": "Luftqualität",
  "timeRange": "24h",
  "aggregationInterval": "1h",
  "gapPolicy": "previous",
  "formula": "min(s_co2, s_rh)",
  "formulaSteps": [
    {"name": "s_co2", "expression": "clamp(100 * (2000 - co2) / 1400, 0, 100)"},
    {"name": "s_rh", "expression": "clamp(100 - 100 * abs(rh - 50) / 30, 0, 100)"}
  ],
  "formulaVariables": [
    {"name": "co2", "field": "co2", "label": "CO₂ (ppm)"},
    {"name": "rh", "field": "humidity", "label": "Rel. Feuchte (%)"}
  ],
  "chartStyle": {
    "colorStops": [
      {"value": 0, "color": "#F44336"},
      {"value": 50, "color": "#FFC107"},
      {"value": 100, "color": "#4CAF50"}
    ],
    "fillArea": true,
    "showAxes": true
  }
}
```''',
);
