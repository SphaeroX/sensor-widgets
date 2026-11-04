import 'package:flutter/material.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/presentation/controllers/schema_discovery_state.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// Represents a selectable schema option with optional data type badge and numeric flag.
@immutable
class SchemaPickerOption {
  final String value;
  final String? badge;
  final bool isNumeric;

  const SchemaPickerOption({
    required this.value,
    this.badge,
    this.isNumeric = true,
  });

  factory SchemaPickerOption.fromFieldInfo(InfluxFieldInfo info) {
    return SchemaPickerOption(
      value: info.key,
      badge: info.type,
      isNumeric: info.isNumeric,
    );
  }

  factory SchemaPickerOption.fromString(String value) {
    return SchemaPickerOption(value: value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchemaPickerOption &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          badge == other.badge &&
          isNumeric == other.isNumeric;

  @override
  int get hashCode => Object.hash(value, badge, isNumeric);
}

/// A searchable Material 3 picker with Bottom Sheet, status indicators, and manual input fallback.
class SearchableSchemaPicker extends StatefulWidget {
  final Key? fieldKey;
  final String label;
  final String? hintText;
  final String? selectedValue;
  final List<SchemaPickerOption> options;
  final SchemaStatus status;
  final String? errorMessage;
  final ValueChanged<String> onSelected;
  final VoidCallback? onReload;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool requireNumericHint;
  final bool initialManualMode;

  const SearchableSchemaPicker({
    super.key,
    this.fieldKey,
    required this.label,
    this.hintText,
    this.selectedValue,
    this.options = const [],
    this.status = SchemaStatus.idle,
    this.errorMessage,
    required this.onSelected,
    this.onReload,
    this.validator,
    this.enabled = true,
    this.requireNumericHint = false,
    this.initialManualMode = false,
  });

  @override
  State<SearchableSchemaPicker> createState() => _SearchableSchemaPickerState();
}

class _SearchableSchemaPickerState extends State<SearchableSchemaPicker> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.selectedValue ?? '');
  }

  @override
  void didUpdateWidget(SearchableSchemaPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue &&
        widget.selectedValue != _textController.text) {
      // The text field listens to the controller, so it must not change while
      // the framework is building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.selectedValue != _textController.text) {
          _textController.text = widget.selectedValue ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _openBottomSheet() {
    if (!widget.enabled || widget.options.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _SchemaPickerBottomSheet(
        title: widget.label,
        options: widget.options,
        selectedValue: widget.selectedValue ?? _textController.text,
        requireNumericHint: widget.requireNumericHint,
        onSelected: (val) {
          _textController.text = val;
          widget.onSelected(val);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasOptions = widget.options.isNotEmpty;
    final isLoading = widget.status == SchemaStatus.loading;
    final hasError = widget.status == SchemaStatus.error;

    Widget? helperWidget;
    if (isLoading) {
      helperWidget = Text(AppLocalizations.of(context).schemaLoadingFromDb);
    } else if (hasError && widget.errorMessage != null) {
      helperWidget = Text(
        widget.errorMessage!,
        style: TextStyle(color: theme.colorScheme.error),
      );
    }

    final suffixActions = <Widget>[];

    if (isLoading) {
      suffixActions.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (hasError) {
      if (widget.onReload != null) {
        suffixActions.add(
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppLocalizations.of(context).commonReload,
            onPressed: widget.onReload,
          ),
        );
      }
    } else {
      if (hasOptions) {
        suffixActions.add(
          IconButton(
            icon: const Icon(Icons.arrow_drop_down_circle_outlined),
            tooltip: AppLocalizations.of(context).schemaPickFromList,
            onPressed: _openBottomSheet,
          ),
        );
      }
      if (widget.onReload != null) {
        suffixActions.add(
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppLocalizations.of(context).commonReload,
            onPressed: widget.onReload,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: widget.fieldKey,
          controller: _textController,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            suffixIcon: suffixActions.isNotEmpty
                ? Row(mainAxisSize: MainAxisSize.min, children: suffixActions)
                : null,
          ),
          onChanged: widget.onSelected,
          onTap: hasOptions ? _openBottomSheet : null,
          validator: widget.validator,
        ),
        if (helperWidget != null) ...[const SizedBox(height: 4), helperWidget],
      ],
    );
  }
}

class _SchemaPickerBottomSheet extends StatefulWidget {
  final String title;
  final List<SchemaPickerOption> options;
  final String? selectedValue;
  final bool requireNumericHint;
  final ValueChanged<String> onSelected;

  const _SchemaPickerBottomSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.requireNumericHint,
    required this.onSelected,
  });

  @override
  State<_SchemaPickerBottomSheet> createState() =>
      _SchemaPickerBottomSheetState();
}

class _SchemaPickerBottomSheetState extends State<_SchemaPickerBottomSheet> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  bool _filterNumericOnly = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMixedTypes =
        widget.options.any((o) => o.isNumeric) &&
        widget.options.any((o) => !o.isNumeric);

    final filteredOptions = widget.options.where((option) {
      if (_filterNumericOnly && !option.isNumeric) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !option.value.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)
                          .schemaPickTitle(widget.title),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('schema_picker_search_input'),
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: AppLocalizations.of(context).commonSearchHint,
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
            ),
            if (widget.requireNumericHint && hasMixedTypes)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    key: const Key('numeric_filter_chip'),
                    label: Text(AppLocalizations.of(context).schemaNumericOnly),
                    selected: _filterNumericOnly,
                    onSelected: (val) =>
                        setState(() => _filterNumericOnly = val),
                  ),
                ),
              ),
            const Divider(),
            Expanded(
              child: filteredOptions.isEmpty
                  ? Center(
                      child: Text(AppLocalizations.of(context).schemaNoMatches),
                    )
                  : ListView.builder(
                      itemCount: filteredOptions.length,
                      itemBuilder: (context, index) {
                        final option = filteredOptions[index];
                        final isSelected = option.value == widget.selectedValue;

                        return ListTile(
                          title: Text(option.value),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (option.badge != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: option.isNumeric
                                        ? theme.colorScheme.primaryContainer
                                        : theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    option.badge!,
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: theme.colorScheme.primary,
                                ),
                            ],
                          ),
                          onTap: () {
                            widget.onSelected(option.value);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
