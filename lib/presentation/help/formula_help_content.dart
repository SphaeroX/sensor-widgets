import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

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

/// Explanatory sections of the formula help in the language of [l10n].
List<FormulaHelpSection> formulaHelpSections(AppLocalizations l10n) => [
  FormulaHelpSection(
    title: l10n.helpVariablesTitle,
    body: l10n.helpVariablesBody,
  ),
  FormulaHelpSection(
    title: l10n.helpOperatorsTitle,
    body: l10n.helpOperatorsBody,
  ),
  FormulaHelpSection(title: l10n.helpStepsTitle, body: l10n.helpStepsBody),
  FormulaHelpSection(title: l10n.helpHistoryTitle, body: l10n.helpHistoryBody),
  FormulaHelpSection(title: l10n.helpErrorsTitle, body: l10n.helpErrorsBody),
];

/// All functions and constants of the formula language, described in the
/// language of [l10n]. Names, examples and results are language-neutral.
List<FormulaHelpEntry> formulaHelpEntries(AppLocalizations l10n) => [
  FormulaHelpEntry(
    name: 'min',
    signature: 'min(a, b, …)',
    description: l10n.helpFnMin,
    example: 'min(4, 2, 7)',
    exampleResult: 2,
  ),
  FormulaHelpEntry(
    name: 'max',
    signature: 'max(a, b, …)',
    description: l10n.helpFnMax,
    example: 'max(4, 2, 7)',
    exampleResult: 7,
  ),
  FormulaHelpEntry(
    name: 'clamp',
    signature: l10n.helpFnClampSignature,
    description: l10n.helpFnClamp,
    example: 'clamp(140, 0, 100)',
    exampleResult: 100,
  ),
  FormulaHelpEntry(
    name: 'abs',
    signature: 'abs(x)',
    description: l10n.helpFnAbs,
    example: 'abs(0 - 3)',
    exampleResult: 3,
  ),
  FormulaHelpEntry(
    name: 'pow',
    signature: l10n.helpFnPowSignature,
    description: l10n.helpFnPow,
    example: 'pow(2, 10)',
    exampleResult: 1024,
  ),
  FormulaHelpEntry(
    name: 'sqrt',
    signature: 'sqrt(x)',
    description: l10n.helpFnSqrt,
    example: 'sqrt(16)',
    exampleResult: 4,
  ),
  FormulaHelpEntry(
    name: 'ln',
    signature: 'ln(x)',
    description: l10n.helpFnLn,
    example: 'ln(e)',
    exampleResult: 1,
  ),
  FormulaHelpEntry(
    name: 'log10',
    signature: 'log10(x)',
    description: l10n.helpFnLog10,
    example: 'log10(1000)',
    exampleResult: 3,
  ),
  FormulaHelpEntry(
    name: 'exp',
    signature: 'exp(x)',
    description: l10n.helpFnExp,
    example: 'exp(0)',
    exampleResult: 1,
  ),
  FormulaHelpEntry(
    name: 'round',
    signature: 'round(x)',
    description: l10n.helpFnRound,
    example: 'round(2.5)',
    exampleResult: 3,
  ),
  FormulaHelpEntry(
    name: 'floor',
    signature: 'floor(x)',
    description: l10n.helpFnFloor,
    example: 'floor(0 - 1.2)',
    exampleResult: -2,
  ),
  FormulaHelpEntry(
    name: 'ceil',
    signature: 'ceil(x)',
    description: l10n.helpFnCeil,
    example: 'ceil(1.2)',
    exampleResult: 2,
  ),
  FormulaHelpEntry(
    name: 'if',
    signature: l10n.helpFnIfSignature,
    description: l10n.helpFnIf,
    example: 'if(5 > 3, 10, 20)',
    exampleResult: 10,
  ),
  FormulaHelpEntry(
    name: 'pi',
    signature: 'pi',
    description: l10n.helpConstPi,
    example: 'round(pi * 100) / 100',
    exampleResult: 3.14,
  ),
  FormulaHelpEntry(
    name: 'e',
    signature: 'e',
    description: l10n.helpConstE,
    example: 'round(e * 100) / 100',
    exampleResult: 2.72,
  ),
];

/// Ready-made formulas; titles, descriptions and variable labels follow
/// [l10n], formulas and variable names are language-neutral.
List<FormulaTemplate> formulaTemplates(AppLocalizations l10n) => [
  FormulaTemplate(
    id: 'iaq_sen66',
    title: 'IAQ (Sensirion SEN66)',
    description: l10n.templateIaqDescription,
    formula: 'min(s_co2, s_voc, s_pm25, s_rh)',
    steps: const [
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
      const FormulaVariable(name: 'co2', field: '', label: 'CO₂ (ppm)'),
      FormulaVariable(name: 'voc', field: '', label: l10n.templateIaqVocLabel),
      const FormulaVariable(name: 'pm25', field: '', label: 'PM2.5 (µg/m³)'),
      FormulaVariable(name: 'rh', field: '', label: l10n.templateIaqRhLabel),
    ],
  ),
  FormulaTemplate(
    id: 'celsius_to_fahrenheit',
    title: l10n.templateFahrenheitTitle,
    description: l10n.templateFahrenheitDescription,
    formula: 'temp * 1.8 + 32',
    variables: [
      FormulaVariable(
        name: 'temp',
        field: '',
        label: l10n.templateFahrenheitTempLabel,
      ),
    ],
  ),
  FormulaTemplate(
    id: 'average_two',
    title: l10n.templateAverageTitle,
    description: l10n.templateAverageDescription,
    formula: '(a + b) / 2',
    variables: [
      FormulaVariable(
        name: 'a',
        field: '',
        label: l10n.templateAverageSensorLabel(1),
      ),
      FormulaVariable(
        name: 'b',
        field: '',
        label: l10n.templateAverageSensorLabel(2),
      ),
    ],
  ),
];
