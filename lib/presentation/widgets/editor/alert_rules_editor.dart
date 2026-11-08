import 'package:flutter/material.dart';
import 'package:sensor_widgets/domain/models/alert_rule.dart';
import 'package:sensor_widgets/domain/models/threshold_rule.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// A value of the widget a notification rule can watch.
class AlertTarget {
  final String id;
  final String label;

  const AlertTarget({required this.id, required this.label});
}

/// Editor card "Benachrichtigungen": push notification rules ("über"/"unter"
/// a threshold) for the widget's value, its rows or its statistics.
class AlertRulesEditor extends StatefulWidget {
  final List<AlertRule> rules;
  final List<AlertTarget> targets;
  final ValueChanged<List<AlertRule>> onChanged;

  /// Called after the user added a rule, e.g. to ask for the OS permission.
  final VoidCallback onRuleAdded;

  /// Inside the editor accordion: no own card and no title (the section
  /// header shows it).
  final bool embedded;

  const AlertRulesEditor({
    super.key,
    required this.rules,
    required this.targets,
    required this.onChanged,
    required this.onRuleAdded,
    this.embedded = false,
  });

  @override
  State<AlertRulesEditor> createState() => _AlertRulesEditorState();
}

class _AlertRulesEditorState extends State<AlertRulesEditor> {
  final List<TextEditingController> _valueControllers = [];

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(AlertRulesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  /// Keeps one value controller per rule; existing ones keep the user's text.
  void _syncControllers() {
    while (_valueControllers.length > widget.rules.length) {
      _valueControllers.removeLast().dispose();
    }
    for (var i = _valueControllers.length; i < widget.rules.length; i++) {
      _valueControllers.add(
        TextEditingController(text: _format(widget.rules[i].value)),
      );
    }
  }

  static String _format(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    for (final c in _valueControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _replace(int index, AlertRule rule) {
    final next = List<AlertRule>.of(widget.rules)..[index] = rule;
    widget.onChanged(next);
  }

  void _add() {
    final target = widget.targets.isNotEmpty
        ? widget.targets.first.id
        : AlertRule.targetValue;
    widget.onChanged([
      ...widget.rules,
      AlertRule(
        target: target,
        operator: ThresholdOperator.greaterThan,
        value: 0,
      ),
    ]);
    widget.onRuleAdded();
  }

  void _remove(int index) {
    _valueControllers.removeAt(index).dispose();
    widget.onChanged(List<AlertRule>.of(widget.rules)..removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded) ...[
          Text(l10n.alertsTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
        ],
        Text(l10n.alertsDescription, style: theme.textTheme.bodySmall),
        for (var i = 0; i < widget.rules.length; i++) _buildRow(i),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('alert_add_button'),
          icon: const Icon(Icons.notifications_active_outlined),
          label: Text(l10n.alertsAdd),
          onPressed: _add,
        ),
      ],
    );
    if (widget.embedded) {
      return KeyedSubtree(key: const Key('alert_rules_editor'), child: content);
    }
    return Card(
      key: const Key('alert_rules_editor'),
      child: Padding(padding: const EdgeInsets.all(12), child: content),
    );
  }

  Widget _buildRow(int i) {
    final rule = widget.rules[i];
    final l10n = AppLocalizations.of(context);
    final targets = [
      ...widget.targets,
      if (!widget.targets.any((t) => t.id == rule.target))
        AlertTarget(id: rule.target, label: rule.target),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (targets.length > 1)
            DropdownButton<String>(
              key: Key('alert_target_$i'),
              value: rule.target,
              isExpanded: true,
              items: [
                for (final t in targets)
                  DropdownMenuItem(value: t.id, child: Text(t.label)),
              ],
              onChanged: (v) {
                if (v != null) _replace(i, rule.copyWith(target: v));
              },
            )
          else
            Text(targets.single.label),
          Row(
            children: [
              SizedBox(
                width: 110,
                child: DropdownButton<ThresholdOperator>(
                  key: Key('alert_operator_$i'),
                  value: rule.operator,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: ThresholdOperator.greaterThan,
                      child: Text(l10n.alertsAbove),
                    ),
                    DropdownMenuItem(
                      value: ThresholdOperator.lessThan,
                      child: Text(l10n.alertsBelow),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) _replace(i, rule.copyWith(operator: v));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: Key('alert_value_$i'),
                  controller: _valueControllers[i],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(labelText: l10n.alertsThreshold),
                  onChanged: (text) {
                    final v = double.tryParse(text.trim().replaceAll(',', '.'));
                    if (v != null) _replace(i, rule.copyWith(value: v));
                  },
                ),
              ),
              IconButton(
                key: Key('alert_remove_$i'),
                tooltip: l10n.alertsRemove,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _remove(i),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
