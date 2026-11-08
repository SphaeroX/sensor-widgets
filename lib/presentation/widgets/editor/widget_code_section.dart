import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/presentation/help/formula_llm_prompt.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// Card with a large text area in which the whole widget is defined as code
/// (JSON). One toolbar row copies a prompt that makes an LLM write it, copies
/// the current code, and pastes code from the clipboard (replacing the text
/// and applying it right away).
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

  /// Inside the editor accordion: no own card and no title (the section
  /// header shows it).
  final bool embedded;

  const WidgetCodeSection({
    super.key,
    required this.generatedCode,
    required this.onApply,
    this.measurement,
    this.availableMeasurements = const [],
    this.availableFields = const [],
    this.embedded = false,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).widgetCodeApplied)),
      );
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
    l10n: AppLocalizations.of(context),
    measurement: widget.measurement,
    availableMeasurements: widget.availableMeasurements,
    availableFields: widget.availableFields,
    currentCode: _controller.text,
  );

  Future<void> _copyPrompt() async {
    await Clipboard.setData(ClipboardData(text: _prompt()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).widgetCodePromptCopied),
      ),
    );
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).widgetCodeCopied)),
    );
  }

  /// Replaces the code with the clipboard text and applies it, so an LLM
  /// answer goes in with one tap. Errors keep the pasted text for fixing.
  Future<void> _pasteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).widgetCodeClipboardEmpty),
        ),
      );
      return;
    }
    setState(() {
      _dirty = true;
      _controller.text = text;
    });
    _apply();
  }

  Widget _toolButton({
    required String keyName,
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: TextButton.icon(
          key: Key(keyName),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          icon: Icon(icon, size: 18),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          onPressed: onPressed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded) ...[
          Text(l10n.widgetCodeTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
        ],
        Text(l10n.widgetCodeDescription, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(
          children: [
            _toolButton(
              keyName: 'copy_widget_prompt_button',
              icon: Icons.auto_awesome_outlined,
              label: l10n.widgetCodePromptShort,
              tooltip: l10n.widgetCodeCopyPrompt,
              onPressed: _copyPrompt,
            ),
            _toolButton(
              keyName: 'copy_widget_code_button',
              icon: Icons.copy_outlined,
              label: l10n.widgetCodeCopyCode,
              tooltip: l10n.widgetCodeCopyCodeTooltip,
              onPressed: _copyCode,
            ),
            _toolButton(
              keyName: 'paste_widget_code_button',
              icon: Icons.content_paste_go_outlined,
              label: l10n.widgetCodePasteCode,
              tooltip: l10n.widgetCodePasteCodeTooltip,
              onPressed: _pasteCode,
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
            labelText: l10n.widgetCodeFieldLabel,
            helperText: _dirty
                ? l10n.widgetCodeDirty
                : l10n.widgetCodeMirrorsForm,
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
                Text('• $e', style: TextStyle(color: theme.colorScheme.error)),
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
              child: Text(l10n.widgetCodeRegenerate),
            ),
            FilledButton.icon(
              key: const Key('widget_code_apply_button'),
              icon: const Icon(Icons.check, size: 18),
              label: Text(l10n.widgetCodeApply),
              onPressed: _apply,
            ),
          ],
        ),
      ],
    );
    if (widget.embedded) {
      return KeyedSubtree(key: const Key('widget_code_card'), child: content);
    }
    return Card(
      key: const Key('widget_code_card'),
      child: Padding(padding: const EdgeInsets.all(16), child: content),
    );
  }
}
