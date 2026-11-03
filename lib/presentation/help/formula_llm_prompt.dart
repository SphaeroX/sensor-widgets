import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/presentation/help/formula_help_content.dart';

/// Builds a prompt the user pastes into an LLM so that it writes formulas in
/// the app's formula language. The language reference comes from
/// [formulaHelpEntries], so the prompt cannot drift from the evaluator.
String buildFormulaLlmPrompt({
  String? measurement,
  List<String> availableMeasurements = const [],
  List<InfluxFieldInfo> availableFields = const [],
  bool supportsSteps = true,
}) {
  final b = StringBuffer()
    ..writeln(
      'Du bist ein Assistent, der Berechnungsformeln für eine '
      'Sensor-Widget-App schreibt. Die Formeln verrechnen Messwerte aus '
      'InfluxDB, bevor sie angezeigt werden. Lies zuerst die Regeln.',
    )
    ..writeln();
  _writeLanguage(b);
  if (supportsSteps) {
    b
      ..writeln()
      ..writeln('## Zwischenschritte (optional)')
      ..writeln(
        'Komplexe Formeln darfst du in benannte Zwischenschritte zerlegen. '
        'Jeder Schritt hat einen Namen (wie ein Variablenname) und einen '
        'Ausdruck. Schritte werden von oben nach unten berechnet und dürfen '
        'Variablen und frühere Schritte verwenden. Die Hauptformel ist das '
        'Ergebnis und darf alle Schritte verwenden. Nutze Schritte nur, wenn '
        'sie die Formel deutlich lesbarer machen.',
      );
  }
  b.writeln();
  _writeData(b, measurement, availableMeasurements, availableFields);
  b
    ..writeln()
    ..writeln('## Dein Ablauf')
    ..writeln(
      '1. Antworte jetzt nur mit "OK", wenn du die Regeln verstanden hast. '
      'Schreibe sonst nichts.',
    )
    ..writeln(
      '2. Danach beschreibe ich, was berechnet werden soll. Antworte dann '
      'in genau diesem Format und ohne Erklärungen:',
    )
    ..writeln('   - Formel: nur die Formel in einem Codeblock, zum Kopieren.');
  if (supportsSteps) {
    b.writeln(
      '   - Zwischenschritte (nur falls verwendet): je Zeile '
      '`name = ausdruck` in einem eigenen Codeblock.',
    );
  }
  b
    ..writeln(
      '   - Variablen-Zuweisung: eine Liste "Variable -> Feld '
      '(Measurement, Tag-Filter falls nötig)", die mir sagt, welche Variable '
      'ich in der App welchem Feld zuweisen muss.',
    )
    ..writeln(
      '3. Verwende ausschließlich die oben erlaubten Funktionen und gib nur '
      'die Formel aus, keine Prosa um sie herum.',
    );
  return b.toString().trimRight();
}

const String _widgetCodeSpec = '''
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
```''';

/// Builds the prompt for the "widget as code" feature: the LLM returns the
/// complete widget as one JSON block that the user pastes into the editor.
String buildWidgetCodePrompt({
  String? measurement,
  List<String> availableMeasurements = const [],
  List<InfluxFieldInfo> availableFields = const [],
  String? currentCode,
}) {
  final b = StringBuffer()
    ..writeln(
      'Du bist ein Assistent, der komplette Widgets für eine Sensor-Widget-App '
      'als JSON-Code schreibt. Die Widgets zeigen Messwerte aus InfluxDB, '
      'optional per Formel verrechnet. Lies zuerst die Regeln.',
    )
    ..writeln();
  _writeLanguage(b);
  b
    ..writeln()
    ..writeln(_widgetCodeSpec)
    ..writeln();
  _writeData(b, measurement, availableMeasurements, availableFields);
  if (currentCode != null && currentCode.trim().isNotEmpty) {
    b
      ..writeln()
      ..writeln('## Aktueller Widget-Code')
      ..writeln(
        'Das Widget sieht im Moment so aus. Wenn ich eine Änderung '
        'wünsche, gib den kompletten geänderten Code zurück:',
      )
      ..writeln('```json')
      ..writeln(currentCode.trim())
      ..writeln('```');
  }
  b
    ..writeln()
    ..writeln('## Dein Ablauf')
    ..writeln(
      '1. Antworte jetzt nur mit "OK", wenn du die Regeln verstanden hast. '
      'Schreibe sonst nichts.',
    )
    ..writeln(
      '2. Danach beschreibe ich, was das Widget zeigen soll. Antworte dann '
      'mit genau einem JSON-Codeblock, der das komplette Widget enthält '
      '(Typ, Formel, Zwischenschritte, Variablen mit Feldern, Darstellung). '
      'Keine Erklärungen vor oder nach dem Codeblock.',
    )
    ..writeln(
      '3. Nutze nur Felder aus den verfügbaren Daten und nur die erlaubten '
      'Funktionen. Fehlt dir eine Information, frage kurz nach, statt zu '
      'raten.',
    );
  return b.toString().trimRight();
}

void _writeLanguage(StringBuffer b) {
  b
    ..writeln('## Formelsprache')
    ..writeln('- Zahlen (Dezimalpunkt, z. B. 1.8), Variablen, Klammern.')
    ..writeln('- Operatoren: + - * / sowie unäres Minus.')
    ..writeln('- Vergleiche: < > <= >= == != (Ergebnis 1 = wahr, 0 = falsch).')
    ..writeln(
      '- Variablennamen: Buchstaben, Ziffern und _, nicht mit einer Ziffer '
      'beginnend (z. B. A, co2, temp_in). Groß-/Kleinschreibung zählt.',
    )
    ..writeln('- Es gibt keine weiteren Funktionen als diese:');
  for (final e in formulaHelpEntries) {
    b.writeln('  - ${e.signature}: ${e.description} Beispiel: ${e.example}');
  }
  b
    ..writeln(
      '- Fehler wie Division durch Null oder sqrt einer negativen Zahl '
      'werden nie still zu 0, daher bei Bedarf mit if(...) absichern, '
      'z. B. if(B == 0, 0, A / B).',
    )
    ..writeln(
      '- Nicht erlaubt: Variablen mit Punkt oder Leerzeichen, Strings, '
      'Zuweisungen, Semikolons, Funktionen außerhalb der Liste.',
    );
}

void _writeData(
  StringBuffer b,
  String? measurement,
  List<String> availableMeasurements,
  List<InfluxFieldInfo> availableFields,
) {
  b.writeln('## Verfügbare Daten (ausgewählte Umgebung)');
  final hasSchema =
      measurement != null && measurement.isNotEmpty ||
      availableMeasurements.isNotEmpty ||
      availableFields.isNotEmpty;
  if (!hasSchema) {
    b.writeln(
      'Es liegen keine Schema-Informationen vor. Frage nach den Feldnamen '
      'oder nutze sprechende Variablennamen und sage mir, welche Felder '
      'ich zuweisen muss.',
    );
    return;
  }
  if (measurement != null && measurement.isNotEmpty) {
    b.writeln('Aktuelles Measurement: $measurement');
  }
  if (availableMeasurements.isNotEmpty) {
    b.writeln('Verfügbare Measurements: ${availableMeasurements.join(', ')}');
  }
  if (availableFields.isNotEmpty) {
    b.writeln('Verfügbare Felder (Typ):');
    for (final f in availableFields) {
      final note = f.isNumeric ? '' : ', nicht numerisch, nicht verwendbar';
      b.writeln('- ${f.key} (${f.type}$note)');
    }
  }
  b.writeln(
    'Jede Variable der Formel wird in der App einem dieser Felder '
    'zugewiesen (optional mit anderem Measurement oder Tag-Filtern). '
    'Nutze nur numerische Felder.',
  );
}
