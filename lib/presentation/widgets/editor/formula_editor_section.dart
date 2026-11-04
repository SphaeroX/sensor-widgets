import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sensor_widgets/domain/formula/formula_evaluator.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/presentation/controllers/schema_discovery_state.dart';
import 'package:sensor_widgets/l10n/formula_error_text.dart';
import 'package:sensor_widgets/presentation/help/formula_help_content.dart';
import 'package:sensor_widgets/presentation/help/formula_help_screen.dart';
import 'package:sensor_widgets/presentation/help/formula_llm_prompt.dart';
import 'package:sensor_widgets/presentation/widgets/editor/searchable_schema_picker.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// Loads the field keys (with type) of a measurement.
typedef FieldInfoLoader = Future<List<InfluxFieldInfo>> Function(
  String measurement,
);

/// Loads the tag keys of a measurement.
typedef TagKeyLoader = Future<List<String>> Function(String measurement);

/// Loads the values of a tag key in a measurement.
typedef TagValueLoader = Future<List<String>> Function(
  String measurement,
  String tagKey,
);

const List<String> _formulaFunctions = [
  'min',
  'max',
  'clamp',
  'abs',
  'pow',
  'sqrt',
  'ln',
  'log10',
  'exp',
  'round',
  'floor',
  'ceil',
  'if',
];

/// Card section in the Widget Editor for defining custom calculation formulas,
/// variables (picked from the DB schema) and named intermediate steps.
class FormulaEditorSection extends StatefulWidget {
  final bool isEnabled;
  final ValueChanged<bool> onEnabledChanged;
  final String formula;
  final ValueChanged<String> onFormulaChanged;
  final List<FormulaVariable> variables;
  final ValueChanged<List<FormulaVariable>> onVariablesChanged;
  final List<InfluxFieldInfo> availableFields;
  final List<String> availableMeasurements;

  /// Intermediate formulas; the step UI is shown when [onStepsChanged] is set.
  final List<FormulaStep> steps;
  final ValueChanged<List<FormulaStep>>? onStepsChanged;

  /// Measurement a variable falls back to when it has none of its own.
  final String? defaultMeasurement;
  final FieldInfoLoader? fieldLoader;
  final TagKeyLoader? tagKeyLoader;
  final TagValueLoader? tagValueLoader;

  /// Hides the enable switch (used for multi-value rows that always have a formula).
  final bool showEnableSwitch;

  /// Shares the LLM prompt; defaults to the system share sheet.
  final Future<void> Function(String text)? onSharePrompt;

  /// Shows the copy and share buttons for the formula-only LLM prompt.
  final bool showPromptButtons;

  const FormulaEditorSection({
    super.key,
    required this.isEnabled,
    required this.onEnabledChanged,
    required this.formula,
    required this.onFormulaChanged,
    required this.variables,
    required this.onVariablesChanged,
    this.availableFields = const [],
    this.availableMeasurements = const [],
    this.steps = const [],
    this.onStepsChanged,
    this.defaultMeasurement,
    this.fieldLoader,
    this.tagKeyLoader,
    this.tagValueLoader,
    this.showEnableSwitch = true,
    this.onSharePrompt,
    this.showPromptButtons = true,
  });

  @override
  State<FormulaEditorSection> createState() => _FormulaEditorSectionState();
}

class _FormulaEditorSectionState extends State<FormulaEditorSection> {
  late TextEditingController _formulaController;
  final List<TextEditingController> _stepNameControllers = [];
  final List<TextEditingController> _stepExprControllers = [];

  @override
  void initState() {
    super.initState();
    _formulaController = TextEditingController(text: widget.formula);
    _syncStepControllers();
  }

  @override
  void didUpdateWidget(covariant FormulaEditorSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFormulaController();
    _syncStepControllers();
  }

  /// Controllers that already have listeners (the text fields) must not change
  /// while the framework is building, so those updates run after the frame.
  void _applyAfterFrame(VoidCallback update) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) update();
    });
  }

  void _syncFormulaController() {
    if (widget.formula == _formulaController.text) return;
    _applyAfterFrame(() {
      if (widget.formula != _formulaController.text) {
        _formulaController.text = widget.formula;
      }
    });
  }

  @override
  void dispose() {
    _formulaController.dispose();
    for (final c in [..._stepNameControllers, ..._stepExprControllers]) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncStepControllers() {
    final existing = _stepNameControllers.length;
    while (_stepNameControllers.length < widget.steps.length) {
      _stepNameControllers.add(TextEditingController());
      _stepExprControllers.add(TextEditingController());
    }
    while (_stepNameControllers.length > widget.steps.length) {
      _stepNameControllers.removeLast().dispose();
      _stepExprControllers.removeLast().dispose();
    }
    for (var i = 0; i < widget.steps.length; i++) {
      final step = widget.steps[i];
      final name = _stepNameControllers[i];
      final expression = _stepExprControllers[i];
      // New controllers have no listeners yet and can be filled right away.
      if (i >= existing) {
        name.text = step.name;
        expression.text = step.expression;
        continue;
      }
      if (name.text != step.name || expression.text != step.expression) {
        _applyAfterFrame(() {
          if (i >= widget.steps.length || i >= _stepNameControllers.length) {
            return;
          }
          final current = widget.steps[i];
          if (_stepNameControllers[i].text != current.name) {
            _stepNameControllers[i].text = current.name;
          }
          if (_stepExprControllers[i].text != current.expression) {
            _stepExprControllers[i].text = current.expression;
          }
        });
      }
    }
  }

  /// Problem of the current formula, if any; [syntax] marks syntax errors
  /// (shown as field error) apart from warnings (shown as helper text).
  ({String text, bool syntax})? _validation() {
    final l10n = AppLocalizations.of(context);
    final formula = _formulaController.text.trim();
    if (formula.isEmpty) {
      return null;
    }
    final syntaxErr = FormulaEvaluator.syntaxError(formula);
    if (syntaxErr != null) {
      final text = formulaErrorText(l10n, syntaxErr, withPosition: true);
      return (text: l10n.formulaSyntaxError(text), syntax: true);
    }
    final referenced = FormulaEvaluator.extractVariables(formula);
    final defined = {
      ...widget.variables.map((v) => v.name),
      ...widget.steps.map((s) => s.name),
    };
    final missing = referenced.where((r) => !defined.contains(r)).toList();
    if (missing.isNotEmpty) {
      return (
        text: l10n.formulaUndefinedVariables(missing.join(', ')),
        syntax: false,
      );
    }
    if (widget.steps.isNotEmpty) {
      final stepErr = FormulaEvaluator.stepsError(
        widget.steps,
        formula,
        variableNames: widget.variables.map((v) => v.name).toList(),
      );
      if (stepErr != null) {
        return (
          text: l10n.formulaStepError(formulaErrorText(l10n, stepErr)),
          syntax: false,
        );
      }
    }
    return null;
  }

  void _addVariable() {
    final existingNames = widget.variables.map((v) => v.name).toSet();
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    var nextName = 'A';
    for (var i = 0; i < alphabet.length; i++) {
      final letter = alphabet[i];
      if (!existingNames.contains(letter)) {
        nextName = letter;
        break;
      }
    }

    final defaultField = widget.availableFields.isNotEmpty
        ? widget.availableFields.first.key
        : 'value';

    final updated = List<FormulaVariable>.from(widget.variables)
      ..add(FormulaVariable(name: nextName, field: defaultField));
    widget.onVariablesChanged(updated);
  }

  void _removeVariable(int index) {
    final updated = List<FormulaVariable>.from(widget.variables)
      ..removeAt(index);
    widget.onVariablesChanged(updated);
  }

  void _updateVariable(int index, FormulaVariable updatedVar) {
    final updated = List<FormulaVariable>.from(widget.variables);
    updated[index] = updatedVar;
    widget.onVariablesChanged(updated);
  }

  Future<void> _openHelp() async {
    final template = await Navigator.of(context).push<FormulaTemplate>(
      MaterialPageRoute(
        builder: (_) => const FormulaHelpScreen(applyEnabled: true),
      ),
    );
    if (template == null || !mounted) return;

    final existing = {for (final v in widget.variables) v.name: v};
    widget.onVariablesChanged([
      for (final v in template.variables)
        existing[v.name]?.field.isNotEmpty == true ? existing[v.name]! : v,
    ]);
    widget.onStepsChanged?.call(List.of(template.steps));
    widget.onFormulaChanged(template.formula);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).formulaTemplateApplied(template.title),
        ),
      ),
    );
  }

  String _llmPrompt() => buildFormulaLlmPrompt(
    l10n: AppLocalizations.of(context),
    measurement: widget.defaultMeasurement,
    availableMeasurements: widget.availableMeasurements,
    availableFields: widget.availableFields,
    supportsSteps: widget.onStepsChanged != null,
  );

  Future<void> _shareLlmPrompt() async {
    final share = widget.onSharePrompt ?? _shareViaSystem;
    await share(_llmPrompt());
  }

  Future<void> _shareViaSystem(String text) async {
    final subject = AppLocalizations.of(context).formulaShareSubject;
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  Future<void> _copyLlmPrompt() async {
    final prompt = _llmPrompt();
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).widgetCodePromptCopied),
      ),
    );
  }

  void _addStep() {
    final taken = widget.steps.map((s) => s.name).toSet();
    final prefix = AppLocalizations.of(context).formulaDefaultStepName;
    var n = 1;
    while (taken.contains('$prefix$n')) {
      n++;
    }
    widget.onStepsChanged?.call([
      ...widget.steps,
      FormulaStep(name: '$prefix$n', expression: ''),
    ]);
  }

  void _updateStep(int index, {String? name, String? expression}) {
    final updated = List<FormulaStep>.from(widget.steps);
    final old = updated[index];
    updated[index] = FormulaStep(
      name: name ?? old.name,
      expression: expression ?? old.expression,
      label: old.label,
    );
    widget.onStepsChanged?.call(updated);
  }

  void _removeStep(int index) {
    final updated = List<FormulaStep>.from(widget.steps)..removeAt(index);
    widget.onStepsChanged?.call(updated);
  }

  /// Inserts [text] at the cursor of the formula field. [cursorBack] moves
  /// the cursor back from the end of the inserted text (e.g. into `min()`).
  void _insertIntoFormula(String text, {int cursorBack = 0}) {
    final value = _formulaController.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final newText = value.text.replaceRange(start, end, text);
    _formulaController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + text.length - cursorBack,
      ),
    );
    widget.onFormulaChanged(newText);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final validation = _validation();
    final validationMsg = validation?.text;
    final isSyntaxError = validation?.syntax ?? false;
    final isWarning = validation != null && !isSyntaxError;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showEnableSwitch)
              SwitchListTile(
                key: const Key('formula_enabled_switch'),
                secondary: const Icon(Icons.calculate_outlined, size: 28),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.formulaEnableTitle),
                subtitle: Text(l10n.formulaEnableSubtitle),
                value: widget.isEnabled,
                onChanged: (val) {
                  widget.onEnabledChanged(val);
                  if (val && widget.variables.isEmpty) {
                    _addVariable();
                  }
                },
              ),
            if (widget.isEnabled) ...[
              if (widget.showEnableSwitch) const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.formulaTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    key: const Key('formula_help_button'),
                    icon: const Icon(Icons.help_outline, size: 20),
                    tooltip: l10n.formulaHelpTooltip,
                    visualDensity: VisualDensity.compact,
                    onPressed: _openHelp,
                  ),
                ],
              ),
              if (widget.showPromptButtons)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    children: [
                      TextButton.icon(
                        key: const Key('copy_llm_prompt_button'),
                        icon: const Icon(Icons.copy_all_outlined, size: 18),
                        label: Text(l10n.widgetCodeCopyPrompt),
                        onPressed: _copyLlmPrompt,
                      ),
                      TextButton.icon(
                        key: const Key('share_llm_prompt_button'),
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: Text(l10n.commonShare),
                        onPressed: _shareLlmPrompt,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              TextFormField(
                key: const Key('formula_input_field'),
                controller: _formulaController,
                decoration: InputDecoration(
                  labelText: l10n.formulaInputLabel,
                  border: const OutlineInputBorder(),
                  errorText: isSyntaxError ? validationMsg : null,
                  helperText: isWarning
                      ? validationMsg
                      : (validationMsg == null
                            ? l10n.formulaInputHelper
                            : null),
                  helperStyle: isWarning
                      ? TextStyle(color: Theme.of(context).colorScheme.error)
                      : null,
                ),
                onChanged: widget.onFormulaChanged,
              ),
              const SizedBox(height: 8),
              _buildInsertChips(),
              if (widget.onStepsChanged != null) ...[
                const SizedBox(height: 16),
                _buildStepsSection(),
              ],
              const SizedBox(height: 16),
              // Wrap: on narrow phones the button moves below the title.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    l10n.formulaVariablesTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  TextButton.icon(
                    key: const Key('add_formula_variable_button'),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.formulaAddVariable),
                    onPressed: _addVariable,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.variables.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.formulaNoVariables,
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.variables.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final v = widget.variables[index];
                    return _buildVariableTile(v, index);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsertChips() {
    final names = [
      ...widget.variables.map((v) => v.name),
      ...widget.steps.map((s) => s.name),
    ];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final name in names)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                key: Key('insert_chip_$name'),
                label: Text(name),
                visualDensity: VisualDensity.compact,
                onPressed: () => _insertIntoFormula(name),
              ),
            ),
          for (final fn in _formulaFunctions)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                key: Key('insert_chip_$fn'),
                label: Text('$fn()'),
                visualDensity: VisualDensity.compact,
                onPressed: () => _insertIntoFormula('$fn()', cursorBack: 1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepsSection() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.formulaStepsTitle, style: theme.textTheme.titleSmall),
            TextButton.icon(
              key: const Key('add_formula_step_button'),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.formulaAddStep),
              onPressed: _addStep,
            ),
          ],
        ),
        if (widget.steps.isEmpty)
          Text(l10n.formulaStepsHint, style: theme.textTheme.bodySmall),
        for (var i = 0; i < widget.steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    key: Key('step_name_$i'),
                    controller: _stepNameControllers[i],
                    decoration: InputDecoration(
                      labelText: l10n.formulaStepName,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => _updateStep(i, name: v.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: Key('step_expression_$i'),
                    controller: _stepExprControllers[i],
                    decoration: InputDecoration(
                      labelText: l10n.formulaStepExpression,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: _stepSyntaxError(widget.steps[i].expression),
                    ),
                    onChanged: (v) => _updateStep(i, expression: v),
                  ),
                ),
                IconButton(
                  key: Key('delete_step_$i'),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: l10n.formulaDeleteStep,
                  onPressed: () => _removeStep(i),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String? _stepSyntaxError(String expression) {
    if (expression.trim().isEmpty) return null;
    final error = FormulaEvaluator.syntaxError(expression);
    return error == null
        ? null
        : formulaErrorText(
            AppLocalizations.of(context),
            error,
            withPosition: true,
          );
  }

  Widget _buildVariableTile(FormulaVariable variable, int index) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final details = [
      if (variable.measurement != null) variable.measurement!,
      if (variable.tagFilters != null && variable.tagFilters!.isNotEmpty)
        variable.tagFilters!.entries
            .map((e) => '${e.key}=${e.value}')
            .join(', '),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            child: Text(
              variable.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.formulaVariableTitle(variable.name),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  variable.field.isNotEmpty
                      ? variable.field
                      : l10n.formulaNoFieldAssigned,
                  style: theme.textTheme.bodySmall,
                ),
                if (details.isNotEmpty)
                  Text(
                    details.join(' • '),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            key: Key('edit_variable_${variable.name}_button'),
            icon: const Icon(Icons.edit, size: 20),
            tooltip: l10n.formulaEditField,
            onPressed: () => _editVariableDialog(variable, index),
          ),
          IconButton(
            key: Key('delete_variable_${variable.name}_button'),
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: l10n.formulaDeleteVariable,
            onPressed: () => _removeVariable(index),
          ),
        ],
      ),
    );
  }

  Future<void> _editVariableDialog(FormulaVariable variable, int index) async {
    final result = await showDialog<FormulaVariable>(
      context: context,
      builder: (context) => _VariableDialog(
        variable: variable,
        availableMeasurements: widget.availableMeasurements,
        availableFields: widget.availableFields,
        defaultMeasurement: widget.defaultMeasurement,
        fieldLoader: widget.fieldLoader,
        tagKeyLoader: widget.tagKeyLoader,
        tagValueLoader: widget.tagValueLoader,
      ),
    );
    if (result != null) _updateVariable(index, result);
  }
}

class _VariableDialog extends StatefulWidget {
  final FormulaVariable variable;
  final List<String> availableMeasurements;
  final List<InfluxFieldInfo> availableFields;
  final String? defaultMeasurement;
  final FieldInfoLoader? fieldLoader;
  final TagKeyLoader? tagKeyLoader;
  final TagValueLoader? tagValueLoader;

  const _VariableDialog({
    required this.variable,
    required this.availableMeasurements,
    required this.availableFields,
    required this.defaultMeasurement,
    required this.fieldLoader,
    required this.tagKeyLoader,
    required this.tagValueLoader,
  });

  @override
  State<_VariableDialog> createState() => _VariableDialogState();
}

class _VariableDialogState extends State<_VariableDialog> {
  late String _measurement = widget.variable.measurement ?? '';
  late String _field = widget.variable.field;
  late final Map<String, String> _tags;
  late final TextEditingController _labelController = TextEditingController(
    text: widget.variable.label ?? '',
  );
  String _tagKey = '';
  String _tagValue = '';

  List<InfluxFieldInfo> _fields = const [];
  SchemaStatus _fieldStatus = SchemaStatus.idle;
  List<String> _tagKeys = const [];
  List<String> _tagValues = const [];
  int _requestId = 0;

  String get _effectiveMeasurement => _measurement.trim().isNotEmpty
      ? _measurement.trim()
      : (widget.defaultMeasurement ?? '');

  @override
  void initState() {
    super.initState();
    _tags = Map.of(widget.variable.tagFilters ?? {});
    _fields = widget.availableFields;
    _loadSchema();
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _loadSchema() async {
    final measurement = _effectiveMeasurement;
    final requestId = ++_requestId;
    if (measurement.isEmpty ||
        (widget.fieldLoader == null && widget.tagKeyLoader == null)) {
      return;
    }
    setState(() => _fieldStatus = SchemaStatus.loading);
    try {
      final fields =
          await widget.fieldLoader?.call(measurement) ??
          const <InfluxFieldInfo>[];
      final tagKeys =
          await widget.tagKeyLoader?.call(measurement) ?? const <String>[];
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _fields = fields.isNotEmpty ? fields : widget.availableFields;
        _tagKeys = tagKeys;
        _fieldStatus = SchemaStatus.loaded;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _fieldStatus = SchemaStatus.error);
    }
  }

  Future<void> _loadTagValues(String key) async {
    final measurement = _effectiveMeasurement;
    final loader = widget.tagValueLoader;
    if (measurement.isEmpty || key.isEmpty || loader == null) return;
    final values = await loader(measurement, key);
    if (!mounted || key != _tagKey) return;
    setState(() => _tagValues = values);
  }

  void _addTag() {
    if (_tagKey.trim().isEmpty || _tagValue.trim().isEmpty) return;
    setState(() {
      _tags[_tagKey.trim()] = _tagValue.trim();
      _tagKey = '';
      _tagValue = '';
      _tagValues = const [];
    });
  }

  FormulaVariable _result() {
    final measurement = _measurement.trim();
    final label = _labelController.text.trim();
    return FormulaVariable(
      name: widget.variable.name,
      field: _field.trim().isNotEmpty ? _field.trim() : widget.variable.field,
      measurement:
          measurement.isNotEmpty && measurement != widget.defaultMeasurement
          ? measurement
          : null,
      tagFilters: _tags.isNotEmpty ? Map.of(_tags) : null,
      label: label.isNotEmpty ? label : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.formulaVariableDialogTitle(widget.variable.name)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchableSchemaPicker(
              fieldKey: const Key('variable_measurement_input'),
              label: l10n.formulaVariableMeasurement,
              hintText: widget.defaultMeasurement,
              selectedValue: _measurement,
              options: widget.availableMeasurements
                  .map(SchemaPickerOption.fromString)
                  .toList(),
              onSelected: (v) {
                _measurement = v;
                _loadSchema();
              },
            ),
            const SizedBox(height: 12),
            SearchableSchemaPicker(
              fieldKey: const Key('variable_field_input'),
              label: l10n.multiFieldNameLabel,
              selectedValue: _field,
              options: _fields.map(SchemaPickerOption.fromFieldInfo).toList(),
              status: _fieldStatus,
              requireNumericHint: true,
              onSelected: (v) => _field = v,
              onReload: widget.fieldLoader == null ? null : _loadSchema,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.formulaVariableTagFilters,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 6,
                children: [
                  for (final entry in _tags.entries)
                    InputChip(
                      label: Text('${entry.key} = ${entry.value}'),
                      deleteIcon: const Icon(Icons.cancel, size: 18),
                      onDeleted: () => setState(() => _tags.remove(entry.key)),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            SearchableSchemaPicker(
              fieldKey: const Key('variable_tag_key_input'),
              label: l10n.formulaVariableTag,
              selectedValue: _tagKey,
              options: _tagKeys.map(SchemaPickerOption.fromString).toList(),
              onSelected: (v) {
                _tagKey = v;
                _loadTagValues(v);
              },
            ),
            const SizedBox(height: 8),
            SearchableSchemaPicker(
              fieldKey: const Key('variable_tag_value_input'),
              label: l10n.formulaVariableTagValue,
              selectedValue: _tagValue,
              options: _tagValues.map(SchemaPickerOption.fromString).toList(),
              onSelected: (v) => _tagValue = v,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('add_variable_tag_button'),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.formulaVariableAddTag),
                onPressed: _addTag,
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              key: const Key('variable_label_input'),
              controller: _labelController,
              decoration: InputDecoration(
                labelText: l10n.formulaVariableLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        ElevatedButton(
          key: const Key('apply_variable_button'),
          onPressed: () => Navigator.of(context).pop(_result()),
          child: Text(l10n.commonApply),
        ),
      ],
    );
  }
}
