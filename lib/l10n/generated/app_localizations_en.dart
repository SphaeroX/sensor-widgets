// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sensor Widgets';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDuplicate => 'Duplicate';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonReset => 'Reset';

  @override
  String commonErrorDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get dashboardSyncTooltip => 'Sync native widgets';

  @override
  String get dashboardSyncDone => 'Native widgets updated.';

  @override
  String get dashboardHelpTooltip => 'Formula help';

  @override
  String get dashboardConnectionsTooltip => 'InfluxDB connections';

  @override
  String get dashboardEmptyTitle => 'No widgets configured yet';

  @override
  String get dashboardEmptyBody => 'Create your first home-screen widget!';

  @override
  String get dashboardCreateWidget => 'Create widget';

  @override
  String dashboardCardSubtitle(String measurement, int minutes) {
    return '$measurement • every $minutes min';
  }

  @override
  String get dashboardActionsTooltip => 'Actions';

  @override
  String get connectionsTitle => 'InfluxDB Connections';

  @override
  String get connectionsEmptyTitle => 'No connections configured';

  @override
  String get connectionsEmptyHint => 'Tap + to add an InfluxDB server';

  @override
  String connectionsSubtitle(String url, String database) {
    return '$url • DB: $database';
  }

  @override
  String get connectionsDeleteTitle => 'Delete Connection';

  @override
  String connectionsDeleteConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String connectionsLoadError(String error) {
    return 'Error loading connections: $error';
  }

  @override
  String get connectionTestSuccess => 'Connection successful!';

  @override
  String get connectionTestNoResponse => 'Connection failed: no response';

  @override
  String connectionTestFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String connectionSaveFailed(String error) {
    return 'Failed to save connection: $error';
  }

  @override
  String get connectionEditTitle => 'Edit Connection';

  @override
  String get connectionNewTitle => 'New Connection';

  @override
  String get connectionNameLabel => 'Connection Name';

  @override
  String get connectionNameHint => 'e.g. Home Server';

  @override
  String get connectionNameRequired => 'Please enter a connection name';

  @override
  String get connectionUrlLabel => 'Host URL';

  @override
  String get connectionUrlRequired => 'Please enter host URL';

  @override
  String get connectionUrlScheme => 'URL must start with http:// or https://';

  @override
  String get connectionDatabaseLabel => 'Database / Bucket';

  @override
  String get connectionDatabaseHint => 'e.g. sensors';

  @override
  String get connectionDatabaseRequired => 'Please enter database name';

  @override
  String get connectionOrgLabel => 'Organization (optional)';

  @override
  String get connectionOrgHint => 'e.g. home-org';

  @override
  String get connectionTokenLabel => 'API Token';

  @override
  String get connectionTokenKeepHint => '(Keep current token)';

  @override
  String get connectionTokenRequiredHint => 'Required for auth';

  @override
  String get connectionTokenRequired => 'Please enter API token';

  @override
  String get connectionTestButton => 'Test Connection';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceBackgroundColor => 'Background color';

  @override
  String get appearanceBackgroundOpacity => 'Background opacity';

  @override
  String get appearanceTextColor => 'Text color';

  @override
  String get appearanceAccentColor => 'Accent color';

  @override
  String get appearanceFontScale => 'Font size';

  @override
  String get appearanceCornerRadius => 'Corner radius';

  @override
  String get appearanceIosCornerHint =>
      'Note: on iOS the system decides the corner radius of widgets.';

  @override
  String get appearanceColorHint => '#RRGGBB (empty = default)';

  @override
  String get colorInvalid => 'Invalid color (#RRGGBB)';

  @override
  String get chartStyleTitle => 'Color gradient & chart style';

  @override
  String get chartStyleDescription =>
      'The line is colored by value. Without color stops it keeps the default color.';

  @override
  String get chartStylePresetGreenToRed => 'Green → Red';

  @override
  String get chartStylePresetRedToGreen => 'Red → Green';

  @override
  String get chartStyleAddStop => 'Add color stop';

  @override
  String get chartStyleFillArea => 'Fill area';

  @override
  String get chartStyleGrid => 'Grid';

  @override
  String get chartStyleAxes => 'Axis labels';

  @override
  String get chartStyleMarkMinMax => 'Mark min/max';

  @override
  String get chartStyleLineWidth => 'Line width';

  @override
  String get chartStyleStopValue => 'Value';

  @override
  String get chartStyleStopColor => 'Color';

  @override
  String get chartStyleDeleteStop => 'Delete color stop';

  @override
  String get alertsTitle => 'Notifications';

  @override
  String get alertsDescription =>
      'Push notification as soon as a value crosses the threshold. Again only after it has gone back.';

  @override
  String get alertsAdd => 'Add notification';

  @override
  String get alertsAbove => 'above';

  @override
  String get alertsBelow => 'below';

  @override
  String get alertsThreshold => 'Threshold';

  @override
  String get alertsRemove => 'Remove notification';

  @override
  String get widgetCodeApplied => 'Code applied.';

  @override
  String get widgetCodePromptCopied =>
      'Prompt copied. Paste it into an AI, then describe the task.';

  @override
  String get widgetCodeShareSubject => 'Widget prompt for AI';

  @override
  String get widgetCodeTitle => 'Widget as code';

  @override
  String get widgetCodeDescription =>
      'The whole widget (type, formula, intermediate steps, variables, display) as JSON. Let an AI write it, paste it here and tap \"Apply code\".';

  @override
  String get widgetCodeCopyPrompt => 'Copy prompt for AI';

  @override
  String get commonShare => 'Share';

  @override
  String get widgetCodeFieldLabel => 'Widget code (JSON)';

  @override
  String get widgetCodeDirty => 'Changes not applied';

  @override
  String get widgetCodeMirrorsForm => 'Mirrors the form';

  @override
  String get widgetCodeRegenerate => 'Regenerate from form';

  @override
  String get widgetCodeApply => 'Apply code';

  @override
  String get widgetTypeSingleValueDescription => 'A current reading';

  @override
  String get widgetTypeHistoryChartDescription => 'History over time';

  @override
  String get widgetTypeIndicatorLampDescription => 'Lamp with threshold';

  @override
  String get widgetTypeMultiValueDescription => 'Several values at a glance';

  @override
  String get widgetTypeAggregateDescription => 'Min, max and average';

  @override
  String get widgetTypeGaugeBarDescription => 'Level with color zones';

  @override
  String get helpTitle => 'Formula help';

  @override
  String get helpFunctionsTitle => 'Functions and constants';

  @override
  String helpExample(String example) {
    return 'Example: $example';
  }

  @override
  String get helpTemplatesTitle => 'Templates';

  @override
  String helpTemplateResult(String formula) {
    return 'Result = $formula';
  }

  @override
  String get helpApplyTemplate => 'Apply template';

  @override
  String get helpVariablesTitle => 'Variables';

  @override
  String get helpVariablesBody =>
      'Each variable (e.g. A, B or co2) stands for a field from the database. Readings are picked from the schema, optionally with their own measurement and tag filters. In the formula you only use the name of the variable.';

  @override
  String get helpOperatorsTitle => 'Operators';

  @override
  String get helpOperatorsBody =>
      '+ - * / and parentheses. Comparisons (< > <= >= == !=) return 1 (true) or 0 (false). Example: (A + B) / 2 or A > 25.';

  @override
  String get helpStepsTitle => 'Intermediate steps';

  @override
  String get helpStepsBody =>
      'Intermediate steps are named partial formulas. They are calculated from top to bottom and may use variables and earlier steps. The formula at the top is the result and may use all steps.';

  @override
  String get helpHistoryTitle => 'History and aggregate';

  @override
  String get helpHistoryBody =>
      'For the history chart and the aggregate the formula is calculated per time bucket (average per interval). If a value is missing in a bucket, the bucket is skipped or the last value is carried over (gap policy). Aggregate computes min/max/mean over the calculated values.';

  @override
  String get helpErrorsTitle => 'Errors';

  @override
  String get helpErrorsBody =>
      'Syntax errors show the position in the text. \"Division by zero\", \"Unknown function\", a wrong number of arguments, \"Missing variable\" and domain errors (e.g. sqrt of a negative number, ln(0)) are never silently shown as 0, but as a readable error message.';

  @override
  String get helpFnMin =>
      'Smallest value (any number of arguments, at least one).';

  @override
  String get helpFnMax =>
      'Largest value (any number of arguments, at least one).';

  @override
  String get helpFnClampSignature => 'clamp(x, low, high)';

  @override
  String get helpFnClamp => 'Limits x to the range low to high.';

  @override
  String get helpFnAbs => 'Absolute value (without sign).';

  @override
  String get helpFnPowSignature => 'pow(base, exponent)';

  @override
  String get helpFnPow => 'Power.';

  @override
  String get helpFnSqrt => 'Square root (x must not be negative).';

  @override
  String get helpFnLn => 'Natural logarithm (x must be greater than 0).';

  @override
  String get helpFnLog10 => 'Base-10 logarithm (x must be greater than 0).';

  @override
  String get helpFnExp => 'e to the power of x.';

  @override
  String get helpFnRound =>
      'Rounds to the nearest whole number (.5 away from 0).';

  @override
  String get helpFnFloor => 'Rounds down.';

  @override
  String get helpFnCeil => 'Rounds up.';

  @override
  String get helpFnIfSignature => 'if(condition, then, else)';

  @override
  String get helpFnIf =>
      'Picks one of two values depending on the condition (not 0 = true). Only the chosen branch is calculated, e.g. if(B == 0, 0, A / B).';

  @override
  String get helpConstPi => 'Pi 3.14159…';

  @override
  String get helpConstE => 'Euler\'s number 2.71828…';

  @override
  String get templateIaqDescription =>
      'Air quality index 0 to 100. Each partial score is a linear ramp (CO₂ 600 ppm = 100, 2000 ppm = 0; VOC index 100 = 100, 250 = 0; PM2.5 5 µg/m³ = 100, 35 = 0; humidity 50 % = 100, 20 % or 80 % = 0). The worst partial score determines the result. Thresholds can be adjusted in the intermediate steps.';

  @override
  String get templateIaqVocLabel => 'VOC index';

  @override
  String get templateIaqRhLabel => 'Rel. humidity (%)';

  @override
  String get templateFahrenheitTitle => 'Celsius to Fahrenheit';

  @override
  String get templateFahrenheitDescription =>
      'Converts a temperature from °C to °F.';

  @override
  String get templateFahrenheitTempLabel => 'Temperature';

  @override
  String get templateAverageTitle => 'Average of two sensors';

  @override
  String get templateAverageDescription => 'Average of two readings.';

  @override
  String templateAverageSensorLabel(int number) {
    return 'Sensor $number';
  }

  @override
  String get schemaLoadingFromDb => 'Loading from database...';

  @override
  String get commonReload => 'Reload';

  @override
  String get schemaPickFromList => 'Pick from list';

  @override
  String schemaPickTitle(String title) {
    return 'Select $title';
  }

  @override
  String get commonSearchHint => 'Search...';

  @override
  String get schemaNumericOnly => 'Numeric fields only';

  @override
  String get schemaNoMatches => 'No matches found';

  @override
  String get tagFilterTitle => 'Tag filters (optional)';

  @override
  String get tagFilterReloadTags => 'Reload tags';

  @override
  String get tagFilterNone => 'No tag filters active (fetch data for all tags)';

  @override
  String get tagFilterAdd => 'Add filter';

  @override
  String get tagFilterPickKey => 'Select tag key';

  @override
  String tagFilterPickValue(String key) {
    return 'Select tag value for \"$key\"';
  }

  @override
  String get schemaPickFromDb => 'Pick from database:';

  @override
  String get schemaOrEnterManually => 'Or enter manually:';

  @override
  String get tagFilterKeyHint => 'Tag key (e.g. room)';

  @override
  String get commonNext => 'Next';

  @override
  String get tagFilterLoadingValues => 'Loading values from database...';

  @override
  String get tagFilterValueHint => 'Tag value (e.g. living_room)';

  @override
  String get commonAdd => 'Add';

  @override
  String multiFieldTitle(int count) {
    return 'Fields (multi value) ($count selected)';
  }

  @override
  String get multiFieldReload => 'Reload fields';

  @override
  String get multiFieldNone => 'No fields selected (at least 1 field required)';

  @override
  String get multiFieldRemove => 'Remove field';

  @override
  String get multiFieldSelect => 'Select fields';

  @override
  String get multiFieldAddManual => 'Add field manually';

  @override
  String get multiFieldPickTitle => 'Select fields from database';

  @override
  String get multiFieldSearchHint => 'Search fields...';

  @override
  String get multiFieldNoneFound => 'No fields found';

  @override
  String multiFieldConfirm(int count) {
    return 'Apply ($count)';
  }

  @override
  String get multiFieldNameLabel => 'Field name (e.g. temperature)';

  @override
  String get multiFieldLabelLabel => 'Display name / label (optional)';

  @override
  String get multiFieldUnitLabel => 'Unit (optional, e.g. °C)';

  @override
  String get formulaErrorEmpty => 'Formula must not be empty';

  @override
  String formulaErrorUnexpectedCharacter(String char) {
    return 'Unexpected character: \"$char\"';
  }

  @override
  String get formulaErrorUnexpectedAssign =>
      'Unexpected character: \"=\" (comparison: \"==\")';

  @override
  String formulaErrorInvalidNumber(String text) {
    return 'Invalid number: $text';
  }

  @override
  String formulaErrorUnknownOperator(String op) {
    return 'Unknown operator: $op';
  }

  @override
  String get formulaErrorMissingOpeningParen => 'Missing opening parenthesis';

  @override
  String get formulaErrorMissingOperator => 'Missing operator between operands';

  @override
  String get formulaErrorIncomplete => 'Incomplete expression';

  @override
  String get formulaErrorUnclosedParen => 'Unclosed parenthesis';

  @override
  String formulaErrorInvalidStepName(String name) {
    return 'Invalid step name: \"$name\"';
  }

  @override
  String formulaErrorStepNameIsFunction(String name) {
    return 'Step name \"$name\" is a function name';
  }

  @override
  String formulaErrorDuplicateName(String name) {
    return 'Duplicate name: \"$name\"';
  }

  @override
  String formulaErrorStepSelfReference(String name) {
    return 'Step \"$name\" refers to itself';
  }

  @override
  String formulaErrorStepForwardReference(String name) {
    return 'Step refers to a later step \"$name\"';
  }

  @override
  String get formulaErrorDivisionByZero => 'Division by zero';

  @override
  String formulaErrorMissingVariable(String name) {
    return 'Missing variable: $name';
  }

  @override
  String formulaErrorUnknownFunction(String name) {
    return 'Unknown function: $name';
  }

  @override
  String formulaErrorWrongArgumentCount(
    String name,
    String expected,
    String actual,
  ) {
    return 'Function $name expects $expected argument(s), got: $actual';
  }

  @override
  String formulaArityAtLeast(String min) {
    return 'at least $min';
  }

  @override
  String formulaArityRange(String min, String max) {
    return '$min to $max';
  }

  @override
  String get formulaErrorClampBounds =>
      'clamp: lower bound greater than upper bound';

  @override
  String get formulaErrorSqrtNegative => 'sqrt: argument must not be negative';

  @override
  String get formulaErrorLnNonPositive => 'ln: argument must be greater than 0';

  @override
  String get formulaErrorLog10NonPositive =>
      'log10: argument must be greater than 0';

  @override
  String formulaErrorNotFinite(String function) {
    return '$function: result is not finite';
  }

  @override
  String get formulaErrorResultNotFinite => 'Result is not finite';

  @override
  String get formulaErrorNoFormula => 'Widget has no formula';

  @override
  String get formulaErrorNoVariables => 'No variables defined for the formula';

  @override
  String formulaErrorAtPosition(String message, int position) {
    return '$message (position $position)';
  }

  @override
  String get influxErrorAuth =>
      'Authentication error (401): please check the API token and the read permissions for the database or bucket.';

  @override
  String get influxErrorDatabaseNotFound =>
      'Database or bucket not found: in InfluxDB v2 the bucket needs a v1 DBRP mapping, or the bucket name must match the database name exactly.';

  @override
  String influxErrorQuery(String detail) {
    return 'Query error: $detail';
  }

  @override
  String get influxErrorEndpointNotFound =>
      'Endpoint not found (404): please check the base URL and port of the InfluxDB instance.';

  @override
  String influxErrorNetwork(String detail) {
    return 'Network connection failed ($detail): the InfluxDB instance could not be reached. Please check the network connection, host and port.';
  }

  @override
  String influxErrorParse(String detail) {
    return 'Unexpected response format ($detail): the InfluxDB response could not be processed.';
  }

  @override
  String influxErrorUnexpected(String detail) {
    return 'Unexpected error: $detail';
  }

  @override
  String get schemaConnectionNotFound => 'Connection not found.';

  @override
  String get schemaTokenNotFound => 'API token for this connection not found.';

  @override
  String get schemaNoConnectionSelected => 'No connection selected.';

  @override
  String get schemaConnectionOrTokenNotFound =>
      'Connection or token not found.';

  @override
  String widgetCopySuffix(String title) {
    return '$title (copy)';
  }

  @override
  String previewBucketErrors(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count time buckets could not be calculated: $error',
      one: '1 time bucket could not be calculated: $error',
    );
    return '$_temp0';
  }

  @override
  String get previewNoToken => 'No authentication token available.';

  @override
  String get previewNoField => 'No field given.';

  @override
  String get previewNoFields => 'No sensor fields configured.';

  @override
  String formulaSyntaxError(String error) {
    return 'Syntax error: $error';
  }

  @override
  String formulaUndefinedVariables(String names) {
    return 'Undefined variable: $names';
  }

  @override
  String formulaStepError(String error) {
    return 'Step error: $error';
  }

  @override
  String formulaTemplateApplied(String title) {
    return 'Template \"$title\" applied. Please map the variables.';
  }

  @override
  String get formulaShareSubject => 'Formula prompt for AI';

  @override
  String get formulaDefaultStepName => 'step';

  @override
  String get formulaEnableTitle => 'Use calculation formula';

  @override
  String get formulaEnableSubtitle =>
      'Calculate values from InfluxDB locally before display';

  @override
  String get formulaTitle => 'Mathematical formula';

  @override
  String get formulaHelpTooltip => 'Help and templates';

  @override
  String get formulaInputLabel => 'Formula (e.g. (A + B) / 2 or min(A, B))';

  @override
  String get formulaInputHelper =>
      'Supports + - * /, parentheses, comparisons, functions and if(...)';

  @override
  String get formulaVariablesTitle => 'Variable mapping';

  @override
  String get formulaAddVariable => 'Add variable';

  @override
  String get formulaNoVariables =>
      'No variables yet. Add at least one variable.';

  @override
  String get formulaStepsTitle => 'Intermediate steps';

  @override
  String get formulaAddStep => 'Add step';

  @override
  String get formulaStepsHint =>
      'Optional: named partial formulas that are used in the formula above. The formula above is the result.';

  @override
  String get formulaStepName => 'Name';

  @override
  String get formulaStepExpression => 'Expression';

  @override
  String get formulaDeleteStep => 'Delete step';

  @override
  String formulaVariableTitle(String name) {
    return 'Variable $name';
  }

  @override
  String get formulaNoFieldAssigned => 'No field assigned';

  @override
  String get formulaEditField => 'Edit field';

  @override
  String get formulaDeleteVariable => 'Delete variable';

  @override
  String formulaVariableDialogTitle(String name) {
    return 'Edit variable $name';
  }

  @override
  String get formulaVariableMeasurement => 'Different measurement (optional)';

  @override
  String get formulaVariableTagFilters => 'Tag filters';

  @override
  String get formulaVariableTag => 'Tag';

  @override
  String get formulaVariableTagValue => 'Value';

  @override
  String get formulaVariableAddTag => 'Add tag filter';

  @override
  String get formulaVariableLabel => 'Label (optional)';

  @override
  String get commonApply => 'Apply';

  @override
  String get previewDefaultTitle => 'Widget preview';

  @override
  String get previewNotLoaded =>
      'No preview loaded yet.\nTap \"Load preview\".';

  @override
  String get previewNoPoints =>
      'No data points found in the selected time range.';

  @override
  String previewHistorySummary(
    String latest,
    String unit,
    String min,
    String max,
  ) {
    return 'Current: $latest $unit  (min: $min, max: $max)';
  }

  @override
  String previewLampCondition(String op, String value, String state) {
    return 'Condition: $op $value ($state)';
  }

  @override
  String get previewLampActive => 'Active';

  @override
  String get previewLampInactive => 'Inactive';

  @override
  String get previewNoThreshold => 'No threshold configured';

  @override
  String get previewNoMultiPoints => 'No multi-value data points loaded.';

  @override
  String codeErrorInvalidJson(String detail) {
    return 'Invalid JSON: $detail';
  }

  @override
  String get codeErrorNotObject => 'The code must be a JSON object.';

  @override
  String codeErrorUnknownType(String type, String detail) {
    return 'Unknown widget type \"$type\" ($detail).';
  }

  @override
  String codeErrorWrongType(String detail) {
    return 'A value has the wrong type: $detail';
  }

  @override
  String get codeErrorMeasurementMissing => 'Measurement is missing.';

  @override
  String get codeErrorGapPolicy =>
      'gapPolicy must be \"skip\" or \"previous\".';

  @override
  String get codeErrorChartStyle =>
      'chartStyle is invalid (colors as #RRGGBB, lineWidth > 0).';

  @override
  String get codeErrorAppearance =>
      'appearance is invalid (colors as #RRGGBB, values within range).';

  @override
  String get codeFormulaMain => 'Formula';

  @override
  String codeFormulaRow(String row) {
    return 'Formula of row \"$row\"';
  }

  @override
  String get codeErrorIncomplete =>
      'The widget is incomplete: without a formula a \"field\" (or \"items\" for multi_value) is required.';

  @override
  String codeErrorFormulaSyntax(String what, String error) {
    return '$what: syntax error: $error';
  }

  @override
  String codeErrorNoVariable(String what) {
    return '$what: no variable is defined.';
  }

  @override
  String codeErrorVariableNoField(String what, String name) {
    return '$what: variable $name has no field.';
  }

  @override
  String codeErrorFormula(String what, String error) {
    return '$what: $error';
  }

  @override
  String get alertTargetMean => 'Average';

  @override
  String get alertTargetMin => 'Minimum';

  @override
  String get alertTargetMax => 'Maximum';

  @override
  String get alertTargetLatest => 'Latest value';

  @override
  String get alertTargetCalculated => 'Calculated value';

  @override
  String get alertTargetValue => 'Value';

  @override
  String get gapPolicyTitle => 'Gaps in the history';

  @override
  String get gapPolicyQuestion =>
      'What happens when a formula value is missing in a time bucket?';

  @override
  String get gapPolicySkip => 'Skip bucket';

  @override
  String get gapPolicyPrevious => 'Carry over last value';

  @override
  String formulaRowDefaultLabel(int number) {
    return 'Calculation $number';
  }

  @override
  String get formulaRowsTitle => 'Calculated rows (formula)';

  @override
  String get formulaRowsAdd => 'Formula row';

  @override
  String get formulaRowsHint =>
      'Optional: rows whose value is calculated from their own formula.';

  @override
  String get formulaRowLabel => 'Row label';

  @override
  String get formulaRowDelete => 'Delete row';

  @override
  String get editorEnterFormula => 'Please enter a calculation formula.';

  @override
  String editorInvalidFormula(String error) {
    return 'Invalid formula: $error';
  }

  @override
  String get editorAddVariable => 'Please add at least one variable.';

  @override
  String get editorAssignFields => 'Please assign a field to every variable.';

  @override
  String editorInvalidSteps(String error) {
    return 'Invalid intermediate steps: $error';
  }

  @override
  String get editorNoVariable => 'No variable defined';

  @override
  String editorFormulaRowError(String row, String error) {
    return 'Formula row \"$row\": $error';
  }

  @override
  String get editorTitleNew => 'Configure widget';

  @override
  String get editorTitleEdit => 'Edit widget';

  @override
  String get editorNoConnection =>
      'No InfluxDB connection yet.\nPlease create a connection first.';

  @override
  String get commonBack => 'Back';

  @override
  String get editorLoadPreview => 'Load preview';

  @override
  String get editorBasicSettings => 'Basic settings';

  @override
  String get editorWidgetTitle => 'Widget title';

  @override
  String get editorTitleRequired => 'Please enter a title';

  @override
  String get editorConnection => 'InfluxDB connection';

  @override
  String editorConnectionItem(String name, String database) {
    return '$name ($database)';
  }

  @override
  String get editorWidgetType => 'Widget type';

  @override
  String get editorDataSource => 'Data source (InfluxQL)';

  @override
  String get editorMeasurementHint => 'e.g. climate, home_sensors';

  @override
  String get editorMeasurementRequired => 'Please enter a measurement';

  @override
  String get editorFieldsRequired => 'Select at least 1 field';

  @override
  String get editorField => 'Field';

  @override
  String get editorFieldHint => 'e.g. temperature, power';

  @override
  String get editorFieldRequired => 'Please enter a field';

  @override
  String get editorUnit => 'Unit (optional)';

  @override
  String get editorDecimals => 'Decimal places';

  @override
  String get editorDecimalsHint => 'Max. 2 (e.g. 1 or 2)';

  @override
  String get editorSaveWidget => 'Save widget';

  @override
  String get editorHistorySettings => 'History settings';

  @override
  String get editorTimeRange => 'Time range';

  @override
  String get editorInterval => 'Aggregation interval';

  @override
  String get editorThresholdCondition => 'Threshold condition';

  @override
  String get editorOperator => 'Op';

  @override
  String get editorScale => 'Scale & limits';

  @override
  String get editorAggregateRange => 'Aggregate time range';

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }
}
