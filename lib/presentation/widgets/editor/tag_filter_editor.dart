import 'package:flutter/material.dart';
import 'package:sensor_widgets/presentation/controllers/schema_discovery_state.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// Interactive widget for viewing, adding, and removing InfluxDB tag filters.
class TagFilterEditor extends StatefulWidget {
  final Map<String, String> tagFilters;
  final SchemaListState<String> tagKeysState;
  final Map<String, SchemaListState<String>> tagValuesByKey;
  final ValueChanged<Map<String, String>> onTagFiltersChanged;
  final ValueChanged<String>? onLoadTagValues;
  final VoidCallback? onReloadTagKeys;
  final bool enabled;

  const TagFilterEditor({
    super.key,
    required this.tagFilters,
    this.tagKeysState = const SchemaListState.idle(),
    this.tagValuesByKey = const {},
    required this.onTagFiltersChanged,
    this.onLoadTagValues,
    this.onReloadTagKeys,
    this.enabled = true,
  });

  @override
  State<TagFilterEditor> createState() => _TagFilterEditorState();
}

class _TagFilterEditorState extends State<TagFilterEditor> {
  late final ValueNotifier<Map<String, SchemaListState<String>>>
  _tagValuesNotifier;

  @override
  void initState() {
    super.initState();
    _tagValuesNotifier = ValueNotifier(widget.tagValuesByKey);
  }

  @override
  void didUpdateWidget(TagFilterEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tagValuesByKey != oldWidget.tagValuesByKey) {
      _tagValuesNotifier.value = widget.tagValuesByKey;
    }
  }

  @override
  void dispose() {
    _tagValuesNotifier.dispose();
    super.dispose();
  }

  void _removeTag(String key) {
    final updated = Map<String, String>.from(widget.tagFilters)..remove(key);
    widget.onTagFiltersChanged(updated);
  }

  void _addTag(String key, String value) {
    final updated = Map<String, String>.from(widget.tagFilters)..[key] = value;
    widget.onTagFiltersChanged(updated);
  }

  void _openAddFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _AddTagFilterBottomSheet(
        tagKeys: widget.tagKeysState.items,
        tagValuesListenable: _tagValuesNotifier,
        onLoadTagValues: widget.onLoadTagValues,
        onFilterSelected: (key, value) {
          _addTag(key, value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilters = widget.tagFilters.isNotEmpty;
    final isLoading = widget.tagKeysState.isLoading;
    final hasError = widget.tagKeysState.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context).tagFilterTitle,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (hasError && widget.onReloadTagKeys != null)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: AppLocalizations.of(context).tagFilterReloadTags,
                onPressed: widget.onReloadTagKeys,
              ),
          ],
        ),
        if (hasError && widget.tagKeysState.errorMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.tagKeysState.errorMessage!,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
          ),
        ],
        const SizedBox(height: 6),
        if (hasFilters)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.tagFilters.entries.map((entry) {
              return InputChip(
                label: Text('${entry.key} = ${entry.value}'),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: widget.enabled ? () => _removeTag(entry.key) : null,
              );
            }).toList(),
          )
        else
          Text(
            AppLocalizations.of(context).tagFilterNone,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('add_tag_filter_button'),
          icon: const Icon(Icons.add, size: 18),
          label: Text(AppLocalizations.of(context).tagFilterAdd),
          onPressed: widget.enabled ? _openAddFilterSheet : null,
        ),
      ],
    );
  }
}

class _AddTagFilterBottomSheet extends StatefulWidget {
  final List<String> tagKeys;
  final ValueNotifier<Map<String, SchemaListState<String>>> tagValuesListenable;
  final ValueChanged<String>? onLoadTagValues;
  final void Function(String key, String value) onFilterSelected;

  const _AddTagFilterBottomSheet({
    required this.tagKeys,
    required this.tagValuesListenable,
    required this.onLoadTagValues,
    required this.onFilterSelected,
  });

  @override
  State<_AddTagFilterBottomSheet> createState() =>
      _AddTagFilterBottomSheetState();
}

class _AddTagFilterBottomSheetState extends State<_AddTagFilterBottomSheet> {
  String? _selectedKey;
  final _manualKeyController = TextEditingController();
  final _manualValueController = TextEditingController();

  @override
  void dispose() {
    _manualKeyController.dispose();
    _manualValueController.dispose();
    super.dispose();
  }

  void _onKeyChosen(String key) {
    setState(() => _selectedKey = key);
    widget.onLoadTagValues?.call(key);
  }

  void _onValueChosen(String val) {
    if (_selectedKey != null && val.trim().isNotEmpty) {
      widget.onFilterSelected(_selectedKey!, val.trim());
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStepKey = _selectedKey == null;

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
                  if (!isStepKey)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _selectedKey = null),
                    ),
                  Expanded(
                    child: Text(
                      isStepKey
                          ? AppLocalizations.of(context).tagFilterPickKey
                          : AppLocalizations.of(context)
                                .tagFilterPickValue(_selectedKey ?? ''),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              if (isStepKey) ...[
                if (widget.tagKeys.isNotEmpty) ...[
                  Text(
                    AppLocalizations.of(context).schemaPickFromDb,
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: widget.tagKeys.map((k) {
                      return ActionChip(
                        label: Text(k),
                        onPressed: () => _onKeyChosen(k),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  AppLocalizations.of(context).schemaOrEnterManually,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('manual_tag_key_input'),
                        controller: _manualKeyController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)
                              .tagFilterKeyHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const Key('confirm_tag_key_button'),
                      onPressed: () {
                        final k = _manualKeyController.text.trim();
                        if (k.isNotEmpty) _onKeyChosen(k);
                      },
                      child: Text(AppLocalizations.of(context).commonNext),
                    ),
                  ],
                ),
              ] else ...[
                ValueListenableBuilder<Map<String, SchemaListState<String>>>(
                  valueListenable: widget.tagValuesListenable,
                  builder: (context, valuesByKey, _) {
                    final valuesState = _selectedKey != null
                        ? valuesByKey[_selectedKey!]
                        : null;
                    final availableValues =
                        valuesState?.items ?? const <String>[];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (valuesState?.isLoading == true)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)
                                      .tagFilterLoadingValues,
                                ),
                              ],
                            ),
                          ),
                        if (availableValues.isNotEmpty) ...[
                          Text(
                            AppLocalizations.of(context).schemaPickFromDb,
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: availableValues.map((v) {
                              return ActionChip(
                                label: Text(v),
                                onPressed: () => _onValueChosen(v),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
                Text(
                  AppLocalizations.of(context).schemaOrEnterManually,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('manual_tag_value_input'),
                        controller: _manualValueController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)
                              .tagFilterValueHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const Key('confirm_tag_value_button'),
                      onPressed: () {
                        final v = _manualValueController.text.trim();
                        if (v.isNotEmpty) _onValueChosen(v);
                      },
                      child: Text(AppLocalizations.of(context).commonAdd),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
