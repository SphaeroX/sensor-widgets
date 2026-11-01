import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';

/// Help text for one function or constant of the formula language.
///
/// [example] is a variable-free formula and [exampleResult] its value; a test
/// evaluates every example so the help cannot drift from the evaluator.
class FormulaHelpEntry {
  final String name;
  final String signature;
  final String description;
  final String example;
  final double exampleResult;

  const FormulaHelpEntry({
    required this.name,
    required this.signature,
    required this.description,
    required this.example,
    required this.exampleResult,
  });
}

/// A titled block of explanatory text.
class FormulaHelpSection {
  final String title;
  final String body;

  const FormulaHelpSection({required this.title, required this.body});
}

/// A ready-made formula that can be applied in the editor. Its variables are
/// placeholders (empty `field`) that the user still maps to database fields.
class FormulaTemplate {
  final String id;
  final String title;
  final String description;
  final String formula;
  final List<FormulaStep> steps;
  final List<FormulaVariable> variables;

  const FormulaTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.formula,
    this.steps = const [],
    required this.variables,
  });
}

const List<FormulaHelpSection> formulaHelpSections = [
  FormulaHelpSection(
    title: 'Variablen',
    body:
        'Jede Variable (z. B. A, B oder co2) steht für ein Feld aus der Datenbank. '
        'Messwerte werden aus dem Schema gewählt; optional mit eigenem Measurement '
        'und Tag-Filtern. In der Formel verwendest du nur den Namen der Variable.',
  ),
  FormulaHelpSection(
    title: 'Operatoren',
    body:
        '+ - * / und Klammern. Vergleiche (< > <= >= == !=) liefern 1 (wahr) '
        'oder 0 (falsch). Beispiel: (A + B) / 2 oder A > 25.',
  ),
  FormulaHelpSection(
    title: 'Zwischenschritte',
    body:
        'Zwischenschritte sind benannte Teilformeln. Sie werden von oben nach '
        'unten berechnet und dürfen Variablen und frühere Schritte verwenden. '
        'Die Formel oben ist das Ergebnis und darf alle Schritte verwenden.',
  ),
  FormulaHelpSection(
    title: 'Verlauf und Aggregat',
    body:
        'Beim Verlaufschart und beim Aggregat wird die Formel je Zeit-Bucket '
        'berechnet (Mittelwert pro Intervall). Fehlt in einem Bucket ein Wert, '
        'wird der Bucket übersprungen oder der letzte Wert übernommen '
        '(Lückenregel). Aggregat bildet min/max/mean über die berechneten Werte.',
  ),
  FormulaHelpSection(
    title: 'Fehler',
    body:
        'Syntaxfehler zeigen die Position im Text. "Division durch Null", '
        '"Unbekannte Funktion", falsche Argumentzahl, "Fehlende Variable" und '
        'Bereichsfehler (z. B. sqrt einer negativen Zahl, ln(0)) werden nie '
        'still als 0 angezeigt, sondern als lesbare Fehlermeldung.',
  ),
];

const List<FormulaHelpEntry> formulaHelpEntries = [
  FormulaHelpEntry(
    name: 'min',
    signature: 'min(a, b, …)',
    description: 'Kleinster Wert (beliebig viele Argumente, mindestens eins).',
    example: 'min(4, 2, 7)',
    exampleResult: 2,
  ),
  FormulaHelpEntry(
    name: 'max',
    signature: 'max(a, b, …)',
    description: 'Größter Wert (beliebig viele Argumente, mindestens eins).',
    example: 'max(4, 2, 7)',
    exampleResult: 7,
  ),
  FormulaHelpEntry(
    name: 'clamp',
    signature: 'clamp(x, unten, oben)',
    description: 'Begrenzt x auf den Bereich unten bis oben.',
    example: 'clamp(140, 0, 100)',
    exampleResult: 100,
  ),
  FormulaHelpEntry(
    name: 'abs',
    signature: 'abs(x)',
    description: 'Betrag (ohne Vorzeichen).',
    example: 'abs(0 - 3)',
    exampleResult: 3,
  ),
  FormulaHelpEntry(
    name: 'pow',
    signature: 'pow(basis, exponent)',
    description: 'Potenz.',
    example: 'pow(2, 10)',
    exampleResult: 1024,
  ),
  FormulaHelpEntry(
    name: 'sqrt',
    signature: 'sqrt(x)',
    description: 'Quadratwurzel (x darf nicht negativ sein).',
    example: 'sqrt(16)',
    exampleResult: 4,
  ),
  FormulaHelpEntry(
    name: 'ln',
    signature: 'ln(x)',
    description: 'Natürlicher Logarithmus (x muss größer als 0 sein).',
    example: 'ln(e)',
    exampleResult: 1,
  ),
  FormulaHelpEntry(
    name: 'log10',
    signature: 'log10(x)',
    description: 'Logarithmus zur Basis 10 (x muss größer als 0 sein).',
    example: 'log10(1000)',
    exampleResult: 3,
  ),
  FormulaHelpEntry(
    name: 'exp',
    signature: 'exp(x)',
    description: 'e hoch x.',
    example: 'exp(0)',
    exampleResult: 1,
  ),
  FormulaHelpEntry(
    name: 'round',
    signature: 'round(x)',
    description: 'Rundet auf die nächste ganze Zahl (.5 weg von 0).',
    example: 'round(2.5)',
    exampleResult: 3,
  ),
  FormulaHelpEntry(
    name: 'floor',
    signature: 'floor(x)',
    description: 'Rundet ab.',
    example: 'floor(0 - 1.2)',
    exampleResult: -2,
  ),
  FormulaHelpEntry(
    name: 'ceil',
    signature: 'ceil(x)',
    description: 'Rundet auf.',
    example: 'ceil(1.2)',
    exampleResult: 2,
  ),
  FormulaHelpEntry(
    name: 'if',
    signature: 'if(bedingung, dann, sonst)',
    description:
        'Wählt je nach Bedingung (ungleich 0 = wahr) einen von zwei Werten. '
        'Nur der gewählte Zweig wird berechnet, z. B. if(B == 0, 0, A / B).',
    example: 'if(5 > 3, 10, 20)',
    exampleResult: 10,
  ),
  FormulaHelpEntry(
    name: 'pi',
    signature: 'pi',
    description: 'Kreiszahl 3,14159…',
    example: 'round(pi * 100) / 100',
    exampleResult: 3.14,
  ),
  FormulaHelpEntry(
    name: 'e',
    signature: 'e',
    description: 'Eulersche Zahl 2,71828…',
    example: 'round(e * 100) / 100',
    exampleResult: 2.72,
  ),
];

const List<FormulaTemplate> formulaTemplates = [
  FormulaTemplate(
    id: 'iaq_sen66',
    title: 'IAQ (Sensirion SEN66)',
    description:
        'Luftqualitäts-Index 0 bis 100. Jeder Teil-Score ist eine lineare Rampe '
        '(CO₂ 600 ppm = 100, 2000 ppm = 0; VOC-Index 100 = 100, 250 = 0; '
        'PM2.5 5 µg/m³ = 100, 35 = 0; Feuchte 50 % = 100, 20 % oder 80 % = 0). '
        'Der schlechteste Teil-Score bestimmt das Ergebnis. Schwellen lassen sich '
        'in den Zwischenschritten anpassen.',
    formula: 'min(s_co2, s_voc, s_pm25, s_rh)',
    steps: [
      FormulaStep(
        name: 's_co2',
        expression: 'clamp(100 * (2000 - co2) / 1400, 0, 100)',
      ),
      FormulaStep(
        name: 's_voc',
        expression: 'clamp(100 * (250 - voc) / 150, 0, 100)',
      ),
      FormulaStep(
        name: 's_pm25',
        expression: 'clamp(100 * (35 - pm25) / 30, 0, 100)',
      ),
      FormulaStep(
        name: 's_rh',
        expression: 'clamp(100 - 100 * abs(rh - 50) / 30, 0, 100)',
      ),
    ],
    variables: [
      FormulaVariable(name: 'co2', field: '', label: 'CO₂ (ppm)'),
      FormulaVariable(name: 'voc', field: '', label: 'VOC-Index'),
      FormulaVariable(name: 'pm25', field: '', label: 'PM2.5 (µg/m³)'),
      FormulaVariable(name: 'rh', field: '', label: 'Rel. Feuchte (%)'),
    ],
  ),
  FormulaTemplate(
    id: 'celsius_to_fahrenheit',
    title: 'Celsius in Fahrenheit',
    description: 'Rechnet eine Temperatur von °C in °F um.',
    formula: 'temp * 1.8 + 32',
    variables: [FormulaVariable(name: 'temp', field: '', label: 'Temperatur')],
  ),
  FormulaTemplate(
    id: 'average_two',
    title: 'Mittelwert zweier Sensoren',
    description: 'Durchschnitt von zwei Messwerten.',
    formula: '(a + b) / 2',
    variables: [
      FormulaVariable(name: 'a', field: '', label: 'Sensor 1'),
      FormulaVariable(name: 'b', field: '', label: 'Sensor 2'),
    ],
  ),
];
