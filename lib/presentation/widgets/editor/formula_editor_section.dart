import 'package:flutter/material.dart';
import 'package:sensor_widgets/domain/formula/formula_evaluator.dart';
import 'package:sensor_widgets/domain/models/formula_variable.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';

/// Card section in the Widget Editor for defining custom calculation formulas and variables.
class FormulaEditorSection extends StatefulWidget {
  final bool isEnabled;
  final ValueChanged<bool> onEnabledChanged;
  final String formula;
  final ValueChanged<String> onFormulaChanged;
  final List<FormulaVariable> variables;
  final ValueChanged<List<FormulaVariable>> onVariablesChanged;
  final List<InfluxFieldInfo> availableFields;
  final List<String> availableMeasurements;

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
  });

  @override
  State<FormulaEditorSection> createState() => _FormulaEditorSectionState();
}

class _FormulaEditorSectionState extends State<FormulaEditorSection> {
  late TextEditingController _formulaController;

  @override
  void initState() {
    super.initState();
    _formulaController = TextEditingController(text: widget.formula);
  }

  @override
  void didUpdateWidget(covariant FormulaEditorSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.formula != _formulaController.text) {
      _formulaController.text = widget.formula;
    }
  }

  @override
  void dispose() {
    _formulaController.dispose();
    super.dispose();
  }

  String? _getValidationMessage() {
    final formula = _formulaController.text.trim();
    if (formula.isEmpty) {
      return null;
    }
    final syntaxErr = FormulaEvaluator.validateSyntax(formula);
    if (syntaxErr != null) {
      return 'Syntaxfehler: $syntaxErr';
    }
    final referenced = FormulaEvaluator.extractVariables(formula);
    final defined = widget.variables.map((v) => v.name).toSet();
    final missing = referenced.where((r) => !defined.contains(r)).toList();
    if (missing.isNotEmpty) {
      return 'Nicht definierte Variable: ${missing.join(', ')}';
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

  @override
  Widget build(BuildContext context) {
    final validationMsg = _getValidationMessage();
    final isSyntaxError =
        validationMsg != null && validationMsg.startsWith('Syntaxfehler:');
    final isWarning = validationMsg != null && !isSyntaxError;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              key: const Key('formula_enabled_switch'),
              secondary: const Icon(Icons.calculate_outlined, size: 28),
              contentPadding: EdgeInsets.zero,
              title: const Text('Berechnungsformel verwenden'),
              subtitle: const Text(
                'Werte aus InfluxDB vor der Anzeige lokal verrechnen',
              ),
              value: widget.isEnabled,
              onChanged: (val) {
                widget.onEnabledChanged(val);
                if (val && widget.variables.isEmpty) {
                  _addVariable();
                }
              },
            ),
            if (widget.isEnabled) ...[
              const Divider(height: 24),
              Text(
                'Mathematische Formel',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('formula_input_field'),
                controller: _formulaController,
                decoration: InputDecoration(
                  labelText: 'Formel (z. B. (A + B) / 2 oder A * 1.8 + 32)',
                  border: const OutlineInputBorder(),
                  errorText: isSyntaxError ? validationMsg : null,
                  helperText: isWarning
                      ? validationMsg
                      : (validationMsg == null
                            ? 'Unterstützt +, -, *, /, Klammern und Zahlenkonstanten'
                            : null),
                  helperStyle: isWarning
                      ? TextStyle(color: Theme.of(context).colorScheme.error)
                      : null,
                ),
                onChanged: widget.onFormulaChanged,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Variablen-Zuweisung',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  TextButton.icon(
                    key: const Key('add_formula_variable_button'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Variable hinzufügen'),
                    onPressed: _addVariable,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.variables.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Keine Variablen vorhanden. Füge mindestens eine Variable hinzu.',
                    style: TextStyle(color: Colors.grey),
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

  Widget _buildVariableTile(FormulaVariable variable, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                  'Variable ${variable.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  variable.field.isNotEmpty
                      ? variable.field
                      : 'Kein Feld zugewiesen',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('edit_variable_${variable.name}_button'),
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Feld bearbeiten',
            onPressed: () => _editVariableDialog(variable, index),
          ),
          IconButton(
            key: Key('delete_variable_${variable.name}_button'),
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Variable löschen',
            onPressed: () => _removeVariable(index),
          ),
        ],
      ),
    );
  }

  void _editVariableDialog(FormulaVariable variable, int index) {
    final fieldCtrl = TextEditingController(text: variable.field);
    final measurementCtrl = TextEditingController(
      text: variable.measurement ?? '',
    );

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Variable ${variable.name} anpassen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('variable_field_input'),
                  controller: fieldCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Feldname (z. B. temperature)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('variable_measurement_input'),
                  controller: measurementCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Abweichendes Measurement (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              key: const Key('apply_variable_button'),
              onPressed: () {
                final newField = fieldCtrl.text.trim();
                final newM = measurementCtrl.text.trim().isNotEmpty
                    ? measurementCtrl.text.trim()
                    : null;
                _updateVariable(
                  index,
                  FormulaVariable(
                    name: variable.name,
                    field: newField.isNotEmpty ? newField : variable.field,
                    measurement: newM,
                    tagFilters: variable.tagFilters,
                    label: variable.label,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Übernehmen'),
            ),
          ],
        );
      },
    );
  }
}
