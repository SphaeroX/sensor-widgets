import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/presentation/help/formula_llm_prompt.dart';
import 'package:share_plus/share_plus.dart';

/// Card with a large text area in which the whole widget is defined as code
/// (JSON), plus buttons to copy or share a prompt that makes an LLM write it.
///
/// [generatedCode] is the code of the current editor state. The text area
/// follows it until the user edits the text; [onApply] then parses the text
/// and returns error messages (empty list = applied).
class WidgetCodeSection extends StatefulWidget {
  final String generatedCode;
  final List<String> Function(String code) onApply;
  final String? measurement;
  final List<String> availableMeasurements;
  final List<InfluxFieldInfo> availableFields;

  /// Shares the LLM prompt; defaults to the system share sheet.
  final Future<void> Function(String text)? onSharePrompt;

  const WidgetCodeSection({
    super.key,
    required this.generatedCode,
    required this.onApply,
    this.measurement,
    this.availableMeasurements = const [],
    this.availableFields = const [],
    this.onSharePrompt,
  });

  @override
  State<WidgetCodeSection> createState() => _WidgetCodeSectionState();
}

class _WidgetCodeSectionState extends State<WidgetCodeSection> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.generatedCode,
  );
  bool _dirty = false;
  List<String> _errors = const [];

  @override
  void didUpdateWidget(covariant WidgetCodeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dirty && widget.generatedCode != _controller.text) {
      // The text field listens to the controller, so it must not change while
      // the framework is building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_dirty && widget.generatedCode != _controller.text) {
          _controller.text = widget.generatedCode;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final errors = widget.onApply(_controller.text);
    setState(() {
      _errors = errors;
      if (errors.isEmpty) _dirty = false;
    });
    if (errors.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Code übernommen.')));
    }
  }

  void _reset() {
    setState(() {
      _dirty = false;
      _errors = const [];
      _controller.text = widget.generatedCode;
    });
  }

  String _prompt() => buildWidgetCodePrompt(
    measurement: widget.measurement,
    availableMeasurements: widget.availableMeasurements,
    availableFields: widget.availableFields,
    currentCode: _controller.text,
  );

  Future<void> _copyPrompt() async {
    await Clipboard.setData(ClipboardData(text: _prompt()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Prompt kopiert. In eine KI einfügen, dann die Aufgabe beschreiben.',
        ),
      ),
    );
  }

  Future<void> _sharePrompt() async {
    final share = widget.onSharePrompt ?? _shareViaSystem;
    await share(_prompt());
  }

  static Future<void> _shareViaSystem(String text) async {
    await SharePlus.instance.share(
      ShareParams(text: text, subject: 'Widget-Prompt für KI'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const Key('widget_code_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Widget als Code', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Das ganze Widget (Typ, Formel, Zwischenschritte, Variablen, '
              'Darstellung) als JSON. Lass es von einer KI schreiben, füge es '
              'hier ein und tippe auf "Code übernehmen".',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              children: [
                TextButton.icon(
                  key: const Key('copy_widget_prompt_button'),
                  icon: const Icon(Icons.copy_all_outlined, size: 18),
                  label: const Text('Prompt für KI kopieren'),
                  onPressed: _copyPrompt,
                ),
                TextButton.icon(
                  key: const Key('share_widget_prompt_button'),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Teilen'),
                  onPressed: _sharePrompt,
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              key: const Key('widget_code_field'),
              controller: _controller,
              minLines: 10,
              maxLines: 24,
              keyboardType: TextInputType.multiline,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                labelText: 'Widget-Code (JSON)',
                helperText: _dirty
                    ? 'Nicht übernommene Änderungen'
                    : 'Spiegelt das Formular',
              ),
              onChanged: (_) {
                if (!_dirty) setState(() => _dirty = true);
              },
            ),
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Column(
                key: const Key('widget_code_errors'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in _errors)
                    Text(
                      '• $e',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(
                  key: const Key('widget_code_reset_button'),
                  onPressed: _reset,
                  child: const Text('Aus Formular neu erzeugen'),
                ),
                FilledButton.icon(
                  key: const Key('widget_code_apply_button'),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Code übernehmen'),
                  onPressed: _apply,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
