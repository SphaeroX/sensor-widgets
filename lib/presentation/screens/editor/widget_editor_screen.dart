import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_widgets/domain/formula/formula_evaluator.dart';
import 'package:sensor_widgets/domain/models/chart_style.dart';
import 'package:sensor_widgets/domain/models/formula_step.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/domain/models/sensor_query_item.dart';
import 'package:sensor_widgets/domain/models/threshold_rule.dart';
import 'package:sensor_widgets/domain/models/alert_rule.dart';
import 'package:sensor_widgets/domain/models/widget_appearance.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/domain/widget_code/widget_code_codec.dart';
import 'package:sensor_widgets/l10n/formula_error_text.dart';
import 'package:sensor_widgets/presentation/controllers/connections_controller.dart';
import 'package:sensor_widgets/presentation/controllers/schema_discovery_controller.dart';
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/widgets/editor/alert_rules_editor.dart';
import 'package:sensor_widgets/presentation/widgets/editor/appearance_editor.dart';
import 'package:sensor_widgets/presentation/widgets/editor/chart_style_editor.dart';
import 'package:sensor_widgets/presentation/widgets/editor/formula_editor_section.dart';
import 'package:sensor_widgets/presentation/widgets/editor/multi_field_selector.dart';
import 'package:sensor_widgets/presentation/widgets/editor/searchable_schema_picker.dart';
import 'package:sensor_widgets/presentation/widgets/editor/tag_filter_editor.dart';
import 'package:sensor_widgets/presentation/widgets/editor/widget_code_section.dart';
import 'package:sensor_widgets/presentation/widgets/editor/widget_type_selector.dart';
import 'package:sensor_widgets/presentation/widgets/preview/widget_live_preview_card.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// Form screen for creating or editing a widget configuration with live preview and schema discovery.
class WidgetEditorScreen extends ConsumerStatefulWidget {
  final WidgetDefinition? widgetToEdit;

  const WidgetEditorScreen({super.key, this.widgetToEdit});

  @override
  ConsumerState<WidgetEditorScreen> createState() => _WidgetEditorScreenState();
}

class _WidgetEditorScreenState extends ConsumerState<WidgetEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _measurementController;
  late TextEditingController _fieldController;
  late TextEditingController _unitController;
  late TextEditingController _decimalPlacesController;
  late TextEditingController _historyTimeRangeController;
  late TextEditingController _historyIntervalController;
  late TextEditingController _indicatorThresholdController;
  late TextEditingController _gaugeMinController;
  late TextEditingController _gaugeMaxController;
  late TextEditingController _multiFieldsController;

  String? _selectedConnectionId;
  late WidgetType _selectedType;
  int _refreshInterval = 15;
  String _indicatorOperator = '>';

  Map<String, String> _tagFilters = {};
  List<SensorQueryItem> _multiItems = [];

  bool _isFormulaEnabled = false;
  String _formula = '';
  List<FormulaVariable> _formulaVariables = [];
  List<FormulaStep> _formulaSteps = [];
  ChartStyle? _chartStyle;
  WidgetAppearance? _appearance;
  List<AlertRule> _alerts = [];

  /// Gap handling of time buckets: null = skip (default) or 'previous'.
  String? _gapPolicy;

  /// Multi-value rows that are calculated by their own formula.
  List<SensorQueryItem> _formulaRows = [];

  WidgetPreviewData? _previewData;
  bool _isLoadingPreview = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.widgetToEdit;
    _selectedType = edit?.type ?? WidgetType.singleValue;
    _selectedConnectionId = edit?.connectionId;
    _refreshInterval = edit?.refreshIntervalMinutes ?? 15;
    _tagFilters = edit?.tagFilters != null
        ? Map<String, String>.from(edit!.tagFilters!)
        : {};
    _multiItems = edit?.items != null
        ? edit!.items!.where((i) => !i.hasFormula).toList()
        : [];
    _formulaRows = edit?.items != null
        ? edit!.items!.where((i) => i.hasFormula).toList()
        : [];
    _isFormulaEnabled =
        edit?.formula != null && edit!.formula!.trim().isNotEmpty;
    _formula = edit?.formula ?? '';
    _formulaVariables = edit?.formulaVariables != null
        ? List<FormulaVariable>.from(edit!.formulaVariables!)
        : [];
    _chartStyle = edit?.chartStyle;
    _appearance = edit?.appearance;
    _alerts = List.of(edit?.alerts ?? const <AlertRule>[]);
    _gapPolicy = edit?.gapPolicy == 'previous' ? 'previous' : null;
    _formulaSteps = edit?.formulaSteps != null
        ? List<FormulaStep>.from(edit!.formulaSteps!)
        : [];

    _titleController = TextEditingController(text: edit?.title ?? '');
    _measurementController = TextEditingController(
      text: edit?.measurement ?? '',
    );
    _fieldController = TextEditingController(text: edit?.field ?? '');
    _unitController = TextEditingController(text: edit?.unit ?? '');
    _decimalPlacesController = TextEditingController(
      text: edit?.decimalPlaces != null ? edit!.decimalPlaces.toString() : '',
    );
    _historyTimeRangeController = TextEditingController(
      text: edit?.timeRange ?? '24h',
    );
    _historyIntervalController = TextEditingController(
      text: edit?.aggregationInterval ?? '1h',
    );
    _indicatorThresholdController = TextEditingController(
      text: edit?.threshold?.value != null
          ? edit!.threshold!.value.toString()
          : '25.0',
    );
    _indicatorOperator = edit?.threshold?.operator == ThresholdOperator.lessThan
        ? '<'
        : '>';
    _gaugeMinController = TextEditingController(
      text: (edit?.min ?? 0.0).toString(),
    );
    _gaugeMaxController = TextEditingController(
      text: (edit?.max ?? 100.0).toString(),
    );
    _multiFieldsController = TextEditingController(
      text:
          edit?.items
              ?.where((i) => !i.hasFormula)
              .map((i) => i.field)
              .join(', ') ??
          '',
    );

    if (_selectedConnectionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initSchema();
      });
    }
  }

  void _initSchema() {
    final connId = _selectedConnectionId;
    if (connId != null) {
      final schemaNotifier = ref.read(editorSchemaControllerProvider.notifier);
      schemaNotifier.selectConnection(connId);
      if (_measurementController.text.trim().isNotEmpty) {
        schemaNotifier.selectMeasurement(_measurementController.text.trim());
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _measurementController.dispose();
    _fieldController.dispose();
    _unitController.dispose();
    _decimalPlacesController.dispose();
    _historyTimeRangeController.dispose();
    _historyIntervalController.dispose();
    _indicatorThresholdController.dispose();
    _gaugeMinController.dispose();
    _gaugeMaxController.dispose();
    _multiFieldsController.dispose();
    super.dispose();
  }

  WidgetDefinition _buildCurrentDefinition() {
    final randId = Random().nextInt(999999).toString().padLeft(6, '0');
    final id =
        widget.widgetToEdit?.id ??
        'widget_${DateTime.now().millisecondsSinceEpoch}_$randId';

    ThresholdRule? threshold;
    if (_selectedType == WidgetType.indicatorLamp) {
      final val =
          double.tryParse(_indicatorThresholdController.text.trim()) ?? 0.0;
      final op = _indicatorOperator == '<'
          ? ThresholdOperator.lessThan
          : ThresholdOperator.greaterThan;
      threshold = ThresholdRule(operator: op, value: val, color: '#4CAF50');
    }

    List<SensorQueryItem>? items;
    if (_selectedType == WidgetType.multiValue) {
      var plain = <SensorQueryItem>[];
      if (_multiItems.isNotEmpty) {
        plain = _multiItems;
      } else if (_multiFieldsController.text.trim().isNotEmpty) {
        final rawFields = _multiFieldsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        plain = rawFields
            .map<SensorQueryItem>((f) => SensorQueryItem(field: f, label: f))
            .toList();
      }
      final all = [...plain, ..._formulaRows];
      items = all.isEmpty ? null : all;
    }

    return WidgetDefinition(
      id: id,
      type: _selectedType,
      title: _titleController.text.trim(),
      connectionId: _selectedConnectionId ?? '',
      measurement: _measurementController.text.trim(),
      field: _selectedType == WidgetType.multiValue
          ? null
          : _fieldController.text.trim(),
      unit: _unitController.text.trim().isNotEmpty
          ? _unitController.text.trim()
          : null,
      decimalPlaces: int.tryParse(_decimalPlacesController.text.trim())
          ?.clamp(0, 2),
      refreshIntervalMinutes: _refreshInterval,
      timeRange:
          _selectedType == WidgetType.historyChart ||
              _selectedType == WidgetType.aggregate
          ? _historyTimeRangeController.text.trim()
          : null,
      aggregationInterval: _selectedType == WidgetType.historyChart
          ? _historyIntervalController.text.trim()
          : null,
      threshold: threshold,
      min: _selectedType == WidgetType.gaugeBar
          ? double.tryParse(_gaugeMinController.text.trim())
          : null,
      max: _selectedType == WidgetType.gaugeBar
          ? double.tryParse(_gaugeMaxController.text.trim())
          : null,
      items: items,
      tagFilters: _tagFilters.isNotEmpty ? _tagFilters : null,
      formula: _isFormulaEnabled && _formula.trim().isNotEmpty
          ? _formula.trim()
          : null,
      formulaVariables: _isFormulaEnabled && _formulaVariables.isNotEmpty
          ? _formulaVariables
          : null,
      formulaSteps: _isFormulaEnabled && _formulaSteps.isNotEmpty
          ? _formulaSteps
          : null,
      chartStyle: _selectedType == WidgetType.historyChart ? _chartStyle : null,
      appearance: _appearance,
      alerts: _alerts.isNotEmpty ? List.of(_alerts) : null,
      gapPolicy: _usesTimeBuckets && _gapPolicy == 'previous'
          ? _gapPolicy
          : null,
    );
  }

  /// Parses [code] and, if valid, moves the whole widget into the editor state.
  List<String> _applyWidgetCode(String code) {
    final result = WidgetCodeCodec.decode(
      code,
      base: _buildCurrentDefinition(),
      l10n: AppLocalizations.of(context),
    );
    final def = result.definition;
    if (def == null) return result.errors;

    final measurementChanged =
        def.measurement != _measurementController.text.trim();
    setState(() {
      _selectedType = def.type;
      _titleController.text = def.title;
      _measurementController.text = def.measurement;
      _fieldController.text = def.field ?? '';
      _unitController.text = def.unit ?? '';
      _decimalPlacesController.text = def.decimalPlaces?.toString() ?? '';
      _refreshInterval = def.refreshIntervalMinutes;
      _tagFilters = Map.of(def.tagFilters ?? const {});
      _historyTimeRangeController.text = def.timeRange ?? '24h';
      _historyIntervalController.text = def.aggregationInterval ?? '1h';
      _indicatorOperator = def.threshold?.operator == ThresholdOperator.lessThan
          ? '<'
          : '>';
      _indicatorThresholdController.text = (def.threshold?.value ?? 25.0)
          .toString();
      _gaugeMinController.text = (def.min ?? 0.0).toString();
      _gaugeMaxController.text = (def.max ?? 100.0).toString();
      final items = def.items ?? const <SensorQueryItem>[];
      _multiItems = items.where((i) => !i.hasFormula).toList();
      _formulaRows = items.where((i) => i.hasFormula).toList();
      _multiFieldsController.text = _multiItems.map((i) => i.field).join(', ');
      _isFormulaEnabled = def.formula != null && def.formula!.trim().isNotEmpty;
      _formula = def.formula ?? '';
      _formulaSteps = List.of(def.formulaSteps ?? const []);
      _formulaVariables = List.of(def.formulaVariables ?? const []);
      _chartStyle = def.chartStyle;
      _appearance = def.appearance;
      _alerts = List.of(def.alerts ?? const <AlertRule>[]);
      _gapPolicy = def.gapPolicy == 'previous' ? 'previous' : null;
    });
    if (measurementChanged && def.measurement.isNotEmpty) {
      ref
          .read(editorSchemaControllerProvider.notifier)
          .selectMeasurement(def.measurement);
    }
    return const [];
  }

  /// Values of the current widget type a notification rule can watch.
  List<AlertTarget> get _alertTargets {
    switch (_selectedType) {
      case WidgetType.multiValue:
        final rows = _buildCurrentDefinition().items ?? const [];
        return [
          for (final item in rows)
            AlertTarget(id: item.field, label: item.label ?? item.field),
        ];
      case WidgetType.aggregate:
        return [
          AlertTarget(
            id: 'mean',
            label: AppLocalizations.of(context).alertTargetMean,
          ),
          AlertTarget(
            id: 'min',
            label: AppLocalizations.of(context).alertTargetMin,
          ),
          AlertTarget(
            id: 'max',
            label: AppLocalizations.of(context).alertTargetMax,
          ),
        ];
      case WidgetType.historyChart:
        return [
          AlertTarget(
            id: AlertRule.targetValue,
            label: AppLocalizations.of(context).alertTargetLatest,
          ),
        ];
      default:
        return [
          AlertTarget(
            id: AlertRule.targetValue,
            label: _isFormulaEnabled
                ? AppLocalizations.of(context).alertTargetCalculated
                : AppLocalizations.of(context).alertTargetValue,
          ),
        ];
    }
  }

  /// History charts and aggregates with a formula are calculated per time bucket.
  bool get _usesTimeBuckets =>
      _isFormulaEnabled &&
      (_selectedType == WidgetType.historyChart ||
          _selectedType == WidgetType.aggregate);

  Widget _buildGapPolicyCard() {
    return Card(
      key: const Key('gap_policy_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).gapPolicyTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).gapPolicyQuestion,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  key: const Key('gap_policy_skip'),
                  label: Text(AppLocalizations.of(context).gapPolicySkip),
                  selected: _gapPolicy != 'previous',
                  onSelected: (_) => setState(() => _gapPolicy = null),
                ),
                ChoiceChip(
                  key: const Key('gap_policy_previous'),
                  label: Text(AppLocalizations.of(context).gapPolicyPrevious),
                  selected: _gapPolicy == 'previous',
                  onSelected: (_) => setState(() => _gapPolicy = 'previous'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<List<InfluxFieldInfo>> _loadFieldInfos(String measurement) async {
    final connectionId = _selectedConnectionId;
    if (connectionId == null) return const [];
    return ref
        .read(schemaDiscoveryControllerProvider)
        .getFieldInfos(connectionId, measurement);
  }

  Future<List<String>> _loadTagKeys(String measurement) async {
    final connectionId = _selectedConnectionId;
    if (connectionId == null) return const [];
    return ref
        .read(schemaDiscoveryControllerProvider)
        .getTagKeys(connectionId, measurement);
  }

  Future<List<String>> _loadTagValues(String measurement, String key) async {
    final connectionId = _selectedConnectionId;
    if (connectionId == null) return const [];
    return ref
        .read(schemaDiscoveryControllerProvider)
        .getTagValues(connectionId, measurement, key);
  }

  void _addFormulaRow(EditorSchemaState schemaState) {
    final taken = {
      ..._multiItems.map((i) => i.field),
      ..._formulaRows.map((i) => i.field),
    };
    var n = _formulaRows.length + 1;
    while (taken.contains('formula_$n')) {
      n++;
    }
    final defaultField = schemaState.fields.items.isNotEmpty
        ? schemaState.fields.items.first.key
        : 'value';
    setState(() {
      _formulaRows = [
        ..._formulaRows,
        SensorQueryItem(
          field: 'formula_$n',
          label: AppLocalizations.of(context).formulaRowDefaultLabel(n),
          formula: '',
          formulaVariables: [FormulaVariable(name: 'A', field: defaultField)],
          formulaSteps: const [],
        ),
      ];
    });
  }

  void _updateFormulaRow(
    int index, {
    String? label,
    String? formula,
    List<FormulaVariable>? variables,
    List<FormulaStep>? steps,
  }) {
    final old = _formulaRows[index];
    final updated = List<SensorQueryItem>.from(_formulaRows);
    updated[index] = SensorQueryItem(
      field: old.field,
      label: label ?? old.label,
      unit: old.unit,
      decimalPlaces: old.decimalPlaces,
      formula: formula ?? old.formula,
      formulaVariables: variables ?? old.formulaVariables,
      formulaSteps: steps ?? old.formulaSteps,
    );
    setState(() => _formulaRows = updated);
  }

  Widget _buildFormulaRowsSection(EditorSchemaState schemaState) {
    return Card(
      key: const Key('multi_formula_rows_section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).formulaRowsTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton.icon(
                  key: const Key('add_formula_row_button'),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(AppLocalizations.of(context).formulaRowsAdd),
                  onPressed: () => _addFormulaRow(schemaState),
                ),
              ],
            ),
            if (_formulaRows.isEmpty)
              Text(
                AppLocalizations.of(context).formulaRowsHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            for (var i = 0; i < _formulaRows.length; i++)
              Padding(
                key: Key('formula_row_$i'),
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: Key('formula_row_label_$i'),
                            initialValue: _formulaRows[i].label,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .formulaRowLabel,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) => _updateFormulaRow(i, label: v),
                          ),
                        ),
                        IconButton(
                          key: Key('delete_formula_row_$i'),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: AppLocalizations.of(context)
                              .formulaRowDelete,
                          onPressed: () => setState(
                            () =>
                                _formulaRows = List.of(_formulaRows)
                                  ..removeAt(i),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FormulaEditorSection(
                      showEnableSwitch: false,
                      isEnabled: true,
                      onEnabledChanged: (_) {},
                      formula: _formulaRows[i].formula ?? '',
                      onFormulaChanged: (v) => _updateFormulaRow(i, formula: v),
                      variables: _formulaRows[i].formulaVariables ?? const [],
                      onVariablesChanged: (v) =>
                          _updateFormulaRow(i, variables: v),
                      steps: _formulaRows[i].formulaSteps ?? const [],
                      onStepsChanged: (v) => _updateFormulaRow(i, steps: v),
                      availableFields: schemaState.fields.items,
                      availableMeasurements: schemaState.measurements.items,
                      defaultMeasurement: _measurementController.text.trim(),
                      fieldLoader: _loadFieldInfos,
                      tagKeyLoader: _loadTagKeys,
                      tagValueLoader: _loadTagValues,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchPreview() async {
    final def = _buildCurrentDefinition();
    setState(() => _isLoadingPreview = true);
    final preview = await ref
        .read(widgetsControllerProvider.notifier)
        .fetchPreviewData(def);
    if (mounted) {
      setState(() {
        _previewData = preview;
        _isLoadingPreview = false;
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_isFormulaEnabled) {
      if (_formula.trim().isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.editorEnterFormula)));
        return;
      }
      final err = FormulaEvaluator.syntaxError(_formula);
      if (err != null) {
        final text = formulaErrorText(l10n, err, withPosition: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.editorInvalidFormula(text))),
        );
        return;
      }
      if (_formulaVariables.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.editorAddVariable)));
        return;
      }
      if (_formulaVariables.any((v) => v.field.trim().isEmpty)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.editorAssignFields)));
        return;
      }
      final stepErr = FormulaEvaluator.stepsError(
        _formulaSteps,
        _formula,
        variableNames: _formulaVariables.map((v) => v.name).toList(),
      );
      if (stepErr != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.editorInvalidSteps(formulaErrorText(l10n, stepErr)),
            ),
          ),
        );
        return;
      }
    }

    if (_selectedType == WidgetType.multiValue) {
      for (final row in _formulaRows) {
        final vars = row.formulaVariables ?? const <FormulaVariable>[];
        final rowErr = (row.formula ?? '').trim().isEmpty
            ? l10n.formulaErrorEmpty
            : vars.isEmpty
            ? l10n.editorNoVariable
            : _stepsErrorText(
                l10n,
                row.formulaSteps ?? const [],
                row.formula!,
                vars.map((v) => v.name).toList(),
              );
        if (rowErr != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.editorFormulaRowError(row.label ?? row.field, rowErr),
              ),
            ),
          );
          return;
        }
      }
    }

    if (!_formKey.currentState!.validate()) return;
    final def = _buildCurrentDefinition();
    await ref.read(widgetsControllerProvider.notifier).saveWidget(def);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _stepsErrorText(
    AppLocalizations l10n,
    List<FormulaStep> steps,
    String formula,
    List<String> variableNames,
  ) {
    final error = FormulaEvaluator.stepsError(
      steps,
      formula,
      variableNames: variableNames,
    );
    return error == null ? null : formulaErrorText(l10n, error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final connectionsAsync = ref.watch(connectionsControllerProvider);
    final schemaState = ref.watch(editorSchemaControllerProvider);
    final schemaNotifier = ref.read(editorSchemaControllerProvider.notifier);

    ref.listen<AsyncValue<List<InfluxConnection>>>(
      connectionsControllerProvider,
      (previous, next) {
        if (_selectedConnectionId == null &&
            next.hasValue &&
            next.value!.isNotEmpty) {
          final firstId = next.value!.first.id;
          setState(() => _selectedConnectionId = firstId);
          schemaNotifier.selectConnection(firstId);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.widgetToEdit == null
              ? l10n.editorTitleNew
              : l10n.editorTitleEdit,
        ),
        actions: [
          IconButton(
            key: const Key('save_widget_button'),
            icon: const Icon(Icons.check),
            tooltip: l10n.commonSave,
            onPressed: _save,
          ),
        ],
      ),
      body: connectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.commonErrorDetails('$err'))),
        data: (connections) {
          if (connections.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(l10n.editorNoConnection, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.commonBack),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_selectedConnectionId == null && connections.isNotEmpty) {
            _selectedConnectionId = connections.first.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                schemaNotifier.selectConnection(connections.first.id);
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Live Preview Card
                  WidgetLivePreviewCard(
                    widgetDef: _buildCurrentDefinition(),
                    previewData: _previewData,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      key: const Key('preview_data_button'),
                      icon: _isLoadingPreview
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(l10n.editorLoadPreview),
                      onPressed: _isLoadingPreview ? null : _fetchPreview,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Base Settings
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.editorBasicSettings,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('widget_title_field'),
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .editorWidgetTitle,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l10n.editorTitleRequired
                                : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: const Key('widget_connection_dropdown'),
                            initialValue: _selectedConnectionId,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .editorConnection,
                              border: const OutlineInputBorder(),
                            ),
                            items: connections.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  l10n.editorConnectionItem(c.name, c.database),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedConnectionId = val;
                                });
                                schemaNotifier.selectConnection(val);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(height: 16),
                          Text(
                            l10n.editorWidgetType,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          WidgetTypeSelector(
                            key: const Key('widget_type_selector'),
                            selected: _selectedType,
                            onSelected: (t) =>
                                setState(() => _selectedType = t),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Influx Schema & Queries
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.editorDataSource,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),

                          // Measurement Searchable Picker
                          SearchableSchemaPicker(
                            fieldKey: const Key('widget_measurement_field'),
                            label: 'Measurement',
                            hintText: l10n.editorMeasurementHint,
                            selectedValue: _measurementController.text,
                            options: schemaState.measurements.items
                                .map(SchemaPickerOption.fromString)
                                .toList(),
                            status: schemaState.measurements.status,
                            errorMessage: schemaState.measurements.errorMessage,
                            onSelected: (val) {
                              _measurementController.text = val;
                              schemaNotifier.selectMeasurement(val);
                              setState(() {});
                            },
                            onReload: () => schemaNotifier.reloadMeasurements(),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l10n.editorMeasurementRequired
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Field or Multi-fields
                          if (_selectedType == WidgetType.multiValue) ...[
                            MultiFieldSelector(
                              items: _multiItems,
                              fieldsState: schemaState.fields,
                              onItemsChanged: (items) {
                                setState(() {
                                  _multiItems = items;
                                  _multiFieldsController.text = items
                                      .map((i) => i.field)
                                      .join(', ');
                                });
                              },
                              onReload: () =>
                                  schemaNotifier.reloadFieldsAndTags(),
                              validator: (items) =>
                                  ((items == null || items.isEmpty) &&
                                      _formulaRows.isEmpty)
                                  ? l10n.editorFieldsRequired
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _buildFormulaRowsSection(schemaState),
                          ] else ...[
                            SearchableSchemaPicker(
                              fieldKey: const Key('widget_field_field'),
                              label: l10n.editorField,
                              hintText: l10n.editorFieldHint,
                              selectedValue: _fieldController.text,
                              options: schemaState.fields.items
                                  .map(SchemaPickerOption.fromFieldInfo)
                                  .toList(),
                              status: schemaState.fields.status,
                              errorMessage: schemaState.fields.errorMessage,
                              requireNumericHint:
                                  _selectedType == WidgetType.historyChart ||
                                  _selectedType == WidgetType.indicatorLamp ||
                                  _selectedType == WidgetType.aggregate ||
                                  _selectedType == WidgetType.gaugeBar,
                              onSelected: (val) {
                                _fieldController.text = val;
                                setState(() {});
                              },
                              onReload: () =>
                                  schemaNotifier.reloadFieldsAndTags(),
                              validator: (v) =>
                                  (!_isFormulaEnabled &&
                                      (v == null || v.trim().isEmpty))
                                  ? l10n.editorFieldRequired
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Tag Filter Editor
                          TagFilterEditor(
                            tagFilters: _tagFilters,
                            tagKeysState: schemaState.tagKeys,
                            tagValuesByKey: schemaState.tagValuesByKey,
                            onTagFiltersChanged: (map) =>
                                setState(() => _tagFilters = map),
                            onLoadTagValues: (key) =>
                                schemaNotifier.loadTagValues(key),
                            onReloadTagKeys: () =>
                                schemaNotifier.reloadFieldsAndTags(),
                          ),
                          const SizedBox(height: 12),

                          // Formula & Calculation Section
                          if (_selectedType != WidgetType.multiValue) ...[
                            FormulaEditorSection(
                              showPromptButtons: false,
                              steps: _formulaSteps,
                              onStepsChanged: (steps) =>
                                  setState(() => _formulaSteps = steps),
                              defaultMeasurement: _measurementController.text
                                  .trim(),
                              fieldLoader: _loadFieldInfos,
                              tagKeyLoader: _loadTagKeys,
                              tagValueLoader: _loadTagValues,
                              isEnabled: _isFormulaEnabled,
                              onEnabledChanged: (val) =>
                                  setState(() => _isFormulaEnabled = val),
                              formula: _formula,
                              onFormulaChanged: (val) =>
                                  setState(() => _formula = val),
                              variables: _formulaVariables,
                              onVariablesChanged: (vars) =>
                                  setState(() => _formulaVariables = vars),
                              availableFields: schemaState.fields.items,
                              availableMeasurements:
                                  schemaState.measurements.items,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Unit and Decimals
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: const Key('widget_unit_field'),
                                  controller: _unitController,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)
                                        .editorUnit,
                                    hintText: '°C, %, W',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  key: const Key('widget_decimals_field'),
                                  controller: _decimalPlacesController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)
                                        .editorDecimals,
                                    hintText: AppLocalizations.of(context)
                                        .editorDecimalsHint,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  WidgetCodeSection(
                    generatedCode: WidgetCodeCodec.encode(
                      _buildCurrentDefinition(),
                    ),
                    onApply: _applyWidgetCode,
                    measurement: _measurementController.text.trim(),
                    availableMeasurements: schemaState.measurements.items,
                    availableFields: schemaState.fields.items,
                  ),
                  const SizedBox(height: 16),

                  // Type-Specific Configuration
                  _buildTypeSpecificSettings(context),
                  if (_usesTimeBuckets) ...[
                    const SizedBox(height: 16),
                    _buildGapPolicyCard(),
                  ],
                  if (_selectedType == WidgetType.historyChart) ...[
                    const SizedBox(height: 16),
                    ChartStyleEditor(
                      style: _chartStyle,
                      onChanged: (style) => setState(() => _chartStyle = style),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppearanceEditor(
                    appearance: _appearance,
                    onChanged: (a) => setState(() => _appearance = a),
                  ),
                  const SizedBox(height: 16),
                  AlertRulesEditor(
                    rules: _alerts,
                    targets: _alertTargets,
                    onChanged: (rules) => setState(() => _alerts = rules),
                    onRuleAdded: () =>
                        ref.read(notificationPermissionProvider).request(),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.save),
                    label: Text(l10n.editorSaveWidget),
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<String>> _timeRangeItems() {
    final l10n = AppLocalizations.of(context);
    return [
      DropdownMenuItem(value: '1h', child: Text(l10n.durationHours(1))),
      DropdownMenuItem(value: '6h', child: Text(l10n.durationHours(6))),
      DropdownMenuItem(value: '24h', child: Text(l10n.durationHours(24))),
      DropdownMenuItem(value: '7d', child: Text(l10n.durationDays(7))),
      DropdownMenuItem(value: '30d', child: Text(l10n.durationDays(30))),
    ];
  }

  List<DropdownMenuItem<String>> _intervalItems() {
    final l10n = AppLocalizations.of(context);
    return [
      DropdownMenuItem(value: '1m', child: Text(l10n.durationMinutes(1))),
      DropdownMenuItem(value: '5m', child: Text(l10n.durationMinutes(5))),
      DropdownMenuItem(value: '15m', child: Text(l10n.durationMinutes(15))),
      DropdownMenuItem(value: '1h', child: Text(l10n.durationHours(1))),
      DropdownMenuItem(value: '1d', child: Text(l10n.durationDays(1))),
    ];
  }

  Widget _buildTypeSpecificSettings(BuildContext context) {
    switch (_selectedType) {
      case WidgetType.historyChart:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).editorHistorySettings,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('history_timerange_field'),
                  initialValue: _historyTimeRangeController.text,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).editorTimeRange,
                    border: const OutlineInputBorder(),
                  ),
                  items: _timeRangeItems(),
                  onChanged: (val) {
                    if (val != null) {
                      _historyTimeRangeController.text = val;
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('history_interval_field'),
                  initialValue: _historyIntervalController.text,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).editorInterval,
                    border: const OutlineInputBorder(),
                  ),
                  items: _intervalItems(),
                  onChanged: (val) {
                    if (val != null) {
                      _historyIntervalController.text = val;
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        );

      case WidgetType.indicatorLamp:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).editorThresholdCondition,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: DropdownButtonFormField<String>(
                        initialValue: _indicatorOperator,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)
                              .editorOperator,
                          border: const OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '>', child: Text('>')),
                          DropdownMenuItem(value: '<', child: Text('<')),
                          DropdownMenuItem(value: '==', child: Text('==')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _indicatorOperator = v);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('indicator_threshold_field'),
                        controller: _indicatorThresholdController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)
                              .alertsThreshold,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

      case WidgetType.gaugeBar:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).editorScale,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('gauge_min_field'),
                        controller: _gaugeMinController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)
                              .alertTargetMin,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('gauge_max_field'),
                        controller: _gaugeMaxController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)
                              .alertTargetMax,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

      case WidgetType.aggregate:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).editorAggregateRange,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _historyTimeRangeController.text,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).editorTimeRange,
                    border: const OutlineInputBorder(),
                  ),
                  items: _timeRangeItems(),
                  onChanged: (val) {
                    if (val != null) {
                      _historyTimeRangeController.text = val;
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        );

      case WidgetType.singleValue:
      case WidgetType.multiValue:
        return const SizedBox.shrink();
    }
  }
}
