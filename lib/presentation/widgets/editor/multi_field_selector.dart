import 'package:flutter/material.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/domain/models/sensor_query_item.dart';
import 'package:sensor_widgets/presentation/controllers/schema_discovery_state.dart';

/// Component for multi-select field configuration in multi-value widgets.
class MultiFieldSelector extends StatefulWidget {
  final List<SensorQueryItem> items;
  final SchemaListState<InfluxFieldInfo> fieldsState;
  final ValueChanged<List<SensorQueryItem>> onItemsChanged;
  final VoidCallback? onReload;
  final bool enabled;
  final FormFieldValidator<List<SensorQueryItem>>? validator;

  const MultiFieldSelector({
    super.key,
    required this.items,
    this.fieldsState = const SchemaListState.idle(),
    required this.onItemsChanged,
    this.onReload,
    this.enabled = true,
    this.validator,
  });

  @override
  State<MultiFieldSelector> createState() => _MultiFieldSelectorState();
}

class _MultiFieldSelectorState extends State<MultiFieldSelector> {
  void _removeItem(int index) {
    final updated = List<SensorQueryItem>.from(widget.items)..removeAt(index);
    widget.onItemsChanged(updated);
  }

  void _addItem(SensorQueryItem item) {
    final updated = List<SensorQueryItem>.from(widget.items)..add(item);
    widget.onItemsChanged(updated);
  }

  void _openSelectionSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _MultiFieldBottomSheet(
        availableFields: widget.fieldsState.items,
        currentItems: widget.items,
        onConfirmed: (newItems) {
          widget.onItemsChanged(newItems);
        },
      ),
    );
  }

  void _openManualAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _ManualAddFieldBottomSheet(onAdded: _addItem),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = widget.fieldsState.isLoading;
    final hasError = widget.fieldsState.hasError;
    final hasItems = widget.items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Felder (Multi-Value) (${widget.items.length} ausgewählt)',
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (hasError && widget.onReload != null)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Felder neu laden',
                onPressed: widget.onReload,
              ),
          ],
        ),
        if (hasError && widget.fieldsState.errorMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.fieldsState.errorMessage!,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
          ),
        ],
        const SizedBox(height: 6),
        if (!hasItems)
          Text(
            'Keine Felder ausgewählt (mindestens 1 Feld erforderlich)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final subtitleParts = <String>[];
              if (item.label != null && item.label!.isNotEmpty) {
                subtitleParts.add(item.label!);
              }
              if (item.unit != null && item.unit!.isNotEmpty) {
                subtitleParts.add(item.unit!);
              }

              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  dense: true,
                  title: Text(
                    item.field,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: subtitleParts.isNotEmpty
                      ? Row(
                          children: subtitleParts
                              .map(
                                (part) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(part),
                                  ),
                                ),
                              )
                              .toList(),
                        )
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Feld entfernen',
                    onPressed: widget.enabled ? () => _removeItem(index) : null,
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('select_multi_fields_button'),
              icon: const Icon(Icons.checklist, size: 18),
              label: const Text('Felder auswählen'),
              onPressed: widget.enabled ? _openSelectionSheet : null,
            ),
            TextButton.icon(
              key: const Key('add_manual_multi_field_button'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Manuelles Feld hinzufügen'),
              onPressed: widget.enabled ? _openManualAddSheet : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _MultiFieldBottomSheet extends StatefulWidget {
  final List<InfluxFieldInfo> availableFields;
  final List<SensorQueryItem> currentItems;
  final ValueChanged<List<SensorQueryItem>> onConfirmed;

  const _MultiFieldBottomSheet({
    required this.availableFields,
    required this.currentItems,
    required this.onConfirmed,
  });

  @override
  State<_MultiFieldBottomSheet> createState() => _MultiFieldBottomSheetState();
}

class _MultiFieldBottomSheetState extends State<_MultiFieldBottomSheet> {
  late Set<String> _selectedFieldKeys;
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedFieldKeys = widget.currentItems.map((i) => i.field).toSet();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirm() {
    final existingMap = {
      for (final item in widget.currentItems) item.field: item,
    };
    final result = <SensorQueryItem>[];

    for (final key in _selectedFieldKeys) {
      if (existingMap.containsKey(key)) {
        result.add(existingMap[key]!);
      } else {
        result.add(SensorQueryItem(field: key));
      }
    }

    widget.onConfirmed(result);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = widget.availableFields.where((f) {
      if (_searchQuery.isEmpty) return true;
      return f.key.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Felder aus Datenbank auswählen',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Felder suchen...',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (q) => setState(() => _searchQuery = q.trim()),
              ),
              const Divider(),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Keine Felder gefunden'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final field = filtered[index];
                          final isChecked = _selectedFieldKeys.contains(
                            field.key,
                          );

                          return CheckboxListTile(
                            title: Text(field.key),
                            secondary: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: field.isNumeric
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                field.type,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                            value: isChecked,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedFieldKeys.add(field.key);
                                } else {
                                  _selectedFieldKeys.remove(field.key);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('confirm_multi_fields_button'),
                onPressed: _confirm,
                child: Text('Übernehmen (${_selectedFieldKeys.length})'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualAddFieldBottomSheet extends StatefulWidget {
  final ValueChanged<SensorQueryItem> onAdded;

  const _ManualAddFieldBottomSheet({required this.onAdded});

  @override
  State<_ManualAddFieldBottomSheet> createState() =>
      _ManualAddFieldBottomSheetState();
}

class _ManualAddFieldBottomSheetState
    extends State<_ManualAddFieldBottomSheet> {
  final _fieldController = TextEditingController();
  final _labelController = TextEditingController();
  final _unitController = TextEditingController();

  @override
  void dispose() {
    _fieldController.dispose();
    _labelController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _submit() {
    final field = _fieldController.text.trim();
    if (field.isNotEmpty) {
      widget.onAdded(
        SensorQueryItem(
          field: field,
          label: _labelController.text.trim().isEmpty
              ? null
              : _labelController.text.trim(),
          unit: _unitController.text.trim().isEmpty
              ? null
              : _unitController.text.trim(),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Manuelles Feld hinzufügen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('manual_field_name_input'),
            controller: _fieldController,
            decoration: const InputDecoration(
              labelText: 'Feldname (z. B. temperature)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Anzeigename / Label (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _unitController,
            decoration: const InputDecoration(
              labelText: 'Einheit (Optional, z. B. °C)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('confirm_manual_field_button'),
            onPressed: _submit,
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }
}
