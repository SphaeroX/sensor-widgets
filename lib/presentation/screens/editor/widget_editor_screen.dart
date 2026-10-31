import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_widgets/domain/models/sensor_query_item.dart';
import 'package:sensor_widgets/domain/models/threshold_rule.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/controllers/connections_controller.dart';
import 'package:sensor_widgets/presentation/controllers/schema_discovery_controller.dart';
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/widgets/preview/widget_live_preview_card.dart';

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

  List<String> _measurementSuggestions = [];
  List<String> _fieldSuggestions = [];
  bool _isLoadingSchema = false;

  WidgetPreviewData? _previewData;
  bool _isLoadingPreview = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.widgetToEdit;
    _selectedType = edit?.type ?? WidgetType.singleValue;
    _selectedConnectionId = edit?.connectionId;
    _refreshInterval = edit?.refreshIntervalMinutes ?? 15;

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
      text: edit?.items?.map((i) => i.field).join(', ') ?? '',
    );

    if (_selectedConnectionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMeasurements();
      });
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

  Future<void> _loadMeasurements() async {
    if (_selectedConnectionId == null) return;
    setState(() => _isLoadingSchema = true);
    final discovery = ref.read(schemaDiscoveryControllerProvider);
    final list = await discovery.getMeasurements(_selectedConnectionId!);
    if (mounted) {
      setState(() {
        _measurementSuggestions = list;
        _isLoadingSchema = false;
      });
    }
  }

  Future<void> _loadFields() async {
    if (_selectedConnectionId == null ||
        _measurementController.text.trim().isEmpty) {
      return;
    }
    final discovery = ref.read(schemaDiscoveryControllerProvider);
    final list = await discovery.getFieldKeys(
      _selectedConnectionId!,
      _measurementController.text.trim(),
    );
    if (mounted) {
      setState(() => _fieldSuggestions = list);
    }
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
      final rawFields = _multiFieldsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      items = rawFields
          .map<SensorQueryItem>((f) => SensorQueryItem(field: f, label: f))
          .toList();
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
      decimalPlaces: int.tryParse(_decimalPlacesController.text.trim()),
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
    if (!_formKey.currentState!.validate()) return;
    final def = _buildCurrentDefinition();
    await ref.read(widgetsControllerProvider.notifier).saveWidget(def);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(connectionsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.widgetToEdit == null
              ? 'Widget konfigurieren'
              : 'Widget bearbeiten',
        ),
        actions: [
          IconButton(
            key: const Key('save_widget_button'),
            icon: const Icon(Icons.check),
            tooltip: 'Speichern',
            onPressed: _save,
          ),
        ],
      ),
      body: connectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Fehler: $err')),
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
                    const Text(
                      'Keine InfluxDB-Verbindung vorhanden.\nBitte zuerst eine Verbindung erstellen.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Zurück'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_selectedConnectionId == null && connections.isNotEmpty) {
            _selectedConnectionId = connections.first.id;
            _loadMeasurements();
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
                      label: const Text('Vorschau laden'),
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
                            'Basis-Einstellungen',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('widget_title_field'),
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Widget Titel',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Bitte Titel eingeben'
                                : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: const Key('widget_connection_dropdown'),
                            initialValue: _selectedConnectionId,
                            decoration: const InputDecoration(
                              labelText: 'InfluxDB Verbindung',
                              border: OutlineInputBorder(),
                            ),
                            items: connections.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.name} (${c.database})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedConnectionId = val;
                                  _measurementSuggestions.clear();
                                  _fieldSuggestions.clear();
                                });
                                _loadMeasurements();
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<WidgetType>(
                            key: const Key('widget_type_dropdown'),
                            initialValue: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Widget Typ',
                              border: OutlineInputBorder(),
                            ),
                            items: WidgetType.values.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(t.label),
                              );
                            }).toList(),
                            onChanged: (t) {
                              if (t != null) {
                                setState(() => _selectedType = t);
                              }
                            },
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Datenquelle (InfluxQL)',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              if (_isLoadingSchema)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Measurement Autocomplete / Text
                          Autocomplete<String>(
                            initialValue: TextEditingValue(
                              text: _measurementController.text,
                            ),
                            optionsBuilder: (textVal) {
                              if (_measurementSuggestions.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              return _measurementSuggestions.where(
                                (s) => s.toLowerCase().contains(
                                  textVal.text.toLowerCase(),
                                ),
                              );
                            },
                            onSelected: (val) {
                              _measurementController.text = val;
                              _loadFields();
                              setState(() {});
                            },
                            fieldViewBuilder:
                                (
                                  context,
                                  textEditingController,
                                  focusNode,
                                  onFieldSubmitted,
                                ) {
                                  return TextFormField(
                                    key: const Key('widget_measurement_field'),
                                    controller: textEditingController,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'Measurement',
                                      hintText: 'z. B. climate, home_sensors',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Bitte Measurement eingeben'
                                        : null,
                                    onChanged: (v) {
                                      _measurementController.text = v;
                                      _loadFields();
                                    },
                                  );
                                },
                          ),
                          const SizedBox(height: 12),

                          // Field or Multi-fields
                          if (_selectedType == WidgetType.multiValue) ...[
                            TextFormField(
                              key: const Key('widget_field_field'),
                              controller: _multiFieldsController,
                              decoration: const InputDecoration(
                                labelText: 'Felder (kommagetrennt)',
                                hintText: 'z. B. temp, humidity, co2',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Mindestens 1 Feld angeben'
                                  : null,
                            ),
                          ] else ...[
                            Autocomplete<String>(
                              initialValue: TextEditingValue(
                                text: _fieldController.text,
                              ),
                              optionsBuilder: (textVal) {
                                if (_fieldSuggestions.isEmpty) {
                                  return const Iterable<String>.empty();
                                }
                                return _fieldSuggestions.where(
                                  (s) => s.toLowerCase().contains(
                                    textVal.text.toLowerCase(),
                                  ),
                                );
                              },
                              onSelected: (val) {
                                _fieldController.text = val;
                                setState(() {});
                              },
                              fieldViewBuilder:
                                  (
                                    context,
                                    textEditingController,
                                    focusNode,
                                    onFieldSubmitted,
                                  ) {
                                    return TextFormField(
                                      key: const Key('widget_field_field'),
                                      controller: textEditingController,
                                      focusNode: focusNode,
                                      decoration: const InputDecoration(
                                        labelText: 'Feld',
                                        hintText: 'z. B. temperature, power',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                          ? 'Bitte Feld angeben'
                                          : null,
                                      onChanged: (v) {
                                        _fieldController.text = v;
                                      },
                                    );
                                  },
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Unit and Decimals
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: const Key('widget_unit_field'),
                                  controller: _unitController,
                                  decoration: const InputDecoration(
                                    labelText: 'Einheit (optional)',
                                    hintText: '°C, %, W',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  key: const Key('widget_decimals_field'),
                                  controller: _decimalPlacesController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Nachkommastellen',
                                    hintText: 'z. B. 1',
                                    border: OutlineInputBorder(),
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

                  // Type-Specific Configuration
                  _buildTypeSpecificSettings(context),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Widget Speichern'),
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
                  'Verlauf-Einstellungen',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('history_timerange_field'),
                  initialValue: _historyTimeRangeController.text,
                  decoration: const InputDecoration(
                    labelText: 'Zeitraum',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '1h', child: Text('1 Stunde')),
                    DropdownMenuItem(value: '6h', child: Text('6 Stunden')),
                    DropdownMenuItem(value: '24h', child: Text('24 Stunden')),
                    DropdownMenuItem(value: '7d', child: Text('7 Tage')),
                    DropdownMenuItem(value: '30d', child: Text('30 Tage')),
                  ],
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
                  decoration: const InputDecoration(
                    labelText: 'Aggregations-Intervall',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '1m', child: Text('1 Minute')),
                    DropdownMenuItem(value: '5m', child: Text('5 Minuten')),
                    DropdownMenuItem(value: '15m', child: Text('15 Minuten')),
                    DropdownMenuItem(value: '1h', child: Text('1 Stunde')),
                    DropdownMenuItem(value: '1d', child: Text('1 Tag')),
                  ],
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
                  'Schwellenwert-Bedingung',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: DropdownButtonFormField<String>(
                        initialValue: _indicatorOperator,
                        decoration: const InputDecoration(
                          labelText: 'Op',
                          border: OutlineInputBorder(),
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
                        decoration: const InputDecoration(
                          labelText: 'Schwellenwert',
                          border: OutlineInputBorder(),
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
                  'Skala & Grenzen',
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
                        decoration: const InputDecoration(
                          labelText: 'Minimum',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('gauge_max_field'),
                        controller: _gaugeMaxController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Maximum',
                          border: OutlineInputBorder(),
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
                  'Aggregat-Zeitraum',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _historyTimeRangeController.text,
                  decoration: const InputDecoration(
                    labelText: 'Zeitraum',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '1h', child: Text('1 Stunde')),
                    DropdownMenuItem(value: '6h', child: Text('6 Stunden')),
                    DropdownMenuItem(value: '24h', child: Text('24 Stunden')),
                    DropdownMenuItem(value: '7d', child: Text('7 Tage')),
                    DropdownMenuItem(value: '30d', child: Text('30 Tage')),
                  ],
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
