import 'package:flutter/material.dart';
import 'package:sensor_widgets/domain/chart/chart_color.dart';
import 'package:sensor_widgets/domain/models/widget_appearance.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// Editor card "Aussehen": colors (palette + hex), opacity, font scale and
/// corner radius of a widget. No color picker dependency: swatches + hex field.
class AppearanceEditor extends StatefulWidget {
  /// Swatches offered for every color field.
  static const List<String> palette = [
    '#FFFFFF',
    '#1E1E2E',
    '#89B4FA',
    '#33CC99',
    '#F9A825',
    '#F44336',
    '#9C27B0',
    '#607D8B',
  ];

  final WidgetAppearance? appearance;
  final ValueChanged<WidgetAppearance?> onChanged;

  /// Inside the editor accordion: no own card and no title (the section
  /// header shows it).
  final bool embedded;

  const AppearanceEditor({
    super.key,
    required this.appearance,
    required this.onChanged,
    this.embedded = false,
  });

  @override
  State<AppearanceEditor> createState() => _AppearanceEditorState();
}

class _AppearanceEditorState extends State<AppearanceEditor> {
  late final TextEditingController _background = TextEditingController(
    text: widget.appearance?.backgroundColor ?? '',
  );
  late final TextEditingController _text = TextEditingController(
    text: widget.appearance?.textColor ?? '',
  );
  late final TextEditingController _accent = TextEditingController(
    text: widget.appearance?.accentColor ?? '',
  );

  WidgetAppearance get _value => widget.appearance ?? const WidgetAppearance();

  @override
  void dispose() {
    _background.dispose();
    _text.dispose();
    _accent.dispose();
    super.dispose();
  }

  void _emit(WidgetAppearance value) =>
      widget.onChanged(value.isEmpty ? null : value);

  void _setColor(String field, TextEditingController controller, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _emit(switch (field) {
        'background' => _value.copyWith(clearBackgroundColor: true),
        'text' => _value.copyWith(clearTextColor: true),
        _ => _value.copyWith(clearAccentColor: true),
      });
      return;
    }
    if (parseHexColor(trimmed) == null) {
      setState(() {}); // show the validation message, keep the last valid value
      return;
    }
    final hex = formatHexColor(parseHexColor(trimmed)!);
    _emit(switch (field) {
      'background' => _value.copyWith(backgroundColor: hex),
      'text' => _value.copyWith(textColor: hex),
      _ => _value.copyWith(accentColor: hex),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded || widget.appearance != null)
          Row(
            children: [
              Expanded(
                child: widget.embedded
                    ? const SizedBox.shrink()
                    : Text(
                        l10n.appearanceTitle,
                        style: theme.textTheme.titleSmall,
                      ),
              ),
              if (widget.appearance != null)
                TextButton(
                  key: const Key('reset_appearance_button'),
                  onPressed: () {
                    _background.clear();
                    _text.clear();
                    _accent.clear();
                    widget.onChanged(null);
                  },
                  child: Text(l10n.commonReset),
                ),
            ],
          ),
        const SizedBox(height: 8),
        _colorField(
          label: l10n.appearanceBackgroundColor,
          field: 'background',
          keyName: 'appearance_background_color',
          controller: _background,
        ),
        _slider(
          keyName: 'appearance_opacity_slider',
          label: l10n.appearanceBackgroundOpacity,
          value:
              _value.backgroundOpacity ??
              WidgetAppearance.defaultBackgroundOpacity,
          min: 0,
          max: 1,
          display: (v) => '${(v * 100).round()} %',
          onChanged: (v) => _emit(_value.copyWith(backgroundOpacity: v)),
        ),
        _colorField(
          label: l10n.appearanceTextColor,
          field: 'text',
          keyName: 'appearance_text_color',
          controller: _text,
        ),
        _colorField(
          label: l10n.appearanceAccentColor,
          field: 'accent',
          keyName: 'appearance_accent_color',
          controller: _accent,
        ),
        _slider(
          keyName: 'appearance_font_scale_slider',
          label: l10n.appearanceFontScale,
          value: _value.fontScale ?? WidgetAppearance.defaultFontScale,
          min: WidgetAppearance.minFontScale,
          max: WidgetAppearance.maxFontScale,
          display: (v) => '${(v * 100).round()} %',
          onChanged: (v) => _emit(_value.copyWith(fontScale: v)),
        ),
        _slider(
          keyName: 'appearance_corner_radius_slider',
          label: l10n.appearanceCornerRadius,
          value: _value.cornerRadius ?? WidgetAppearance.defaultCornerRadius,
          min: 0,
          max: WidgetAppearance.maxCornerRadius,
          display: (v) => '${v.round()} dp',
          onChanged: (v) => _emit(_value.copyWith(cornerRadius: v)),
        ),
        Text(l10n.appearanceIosCornerHint, style: theme.textTheme.bodySmall),
      ],
    );
    if (widget.embedded) {
      return KeyedSubtree(key: const Key('appearance_editor'), child: content);
    }
    return Card(
      key: const Key('appearance_editor'),
      child: Padding(padding: const EdgeInsets.all(16), child: content),
    );
  }

  Widget _colorField({
    required String label,
    required String field,
    required String keyName,
    required TextEditingController controller,
  }) {
    final text = controller.text.trim();
    final invalid = text.isNotEmpty && parseHexColor(text) == null;
    final paletteName = field == 'accent' ? 'accent' : field;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: Key(keyName),
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              hintText: l10n.appearanceColorHint,
              isDense: true,
              errorText: invalid ? l10n.colorInvalid : null,
            ),
            onChanged: (v) => _setColor(field, controller, v),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (var i = 0; i < AppearanceEditor.palette.length; i++)
                InkWell(
                  key: Key('palette_${paletteName}_$i'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    controller.text = AppearanceEditor.palette[i];
                    _setColor(field, controller, AppearanceEditor.palette[i]);
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(parseHexColor(AppearanceEditor.palette[i])!),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slider({
    required String keyName,
    required String label,
    required double value,
    required double min,
    required double max,
    required String Function(double) display,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${display(value)}'),
        Slider(
          key: Key(keyName),
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
