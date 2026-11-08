import 'package:flutter/material.dart';
import 'package:sensor_widgets/domain/chart/chart_color.dart';
import 'package:sensor_widgets/domain/models/chart_style.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// Editor card for the history chart style: color stops (value -> color),
/// presets and display options.
class ChartStyleEditor extends StatefulWidget {
  final ChartStyle? style;
  final ValueChanged<ChartStyle?> onChanged;

  /// Inside the editor accordion: no own card (the title stays, because the
  /// section holds several blocks).
  final bool embedded;

  const ChartStyleEditor({
    super.key,
    required this.style,
    required this.onChanged,
    this.embedded = false,
  });

  @override
  State<ChartStyleEditor> createState() => _ChartStyleEditorState();
}

class _ChartStyleEditorState extends State<ChartStyleEditor> {
  final List<TextEditingController> _valueControllers = [];
  final List<TextEditingController> _colorControllers = [];
  late final TextEditingController _lineWidthController;

  ChartStyle get _style => widget.style ?? const ChartStyle();

  @override
  void initState() {
    super.initState();
    _lineWidthController = TextEditingController(
      text: _formatNumber(_style.lineWidth),
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant ChartStyleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    for (final c in [
      ..._valueControllers,
      ..._colorControllers,
      _lineWidthController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _formatNumber(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  void _sync() {
    final stops = _style.colorStops;
    while (_valueControllers.length < stops.length) {
      _valueControllers.add(TextEditingController());
      _colorControllers.add(TextEditingController());
    }
    while (_valueControllers.length > stops.length) {
      _valueControllers.removeLast().dispose();
      _colorControllers.removeLast().dispose();
    }
    for (var i = 0; i < stops.length; i++) {
      final valueText = _formatNumber(stops[i].value);
      final current = double.tryParse(
        _valueControllers[i].text.replaceAll(',', '.'),
      );
      if (current != stops[i].value) _valueControllers[i].text = valueText;
      if (_colorControllers[i].text != stops[i].color) {
        _colorControllers[i].text = stops[i].color;
      }
    }
  }

  void _emit(ChartStyle style) => widget.onChanged(style);

  void _setStops(List<ColorStop> stops) =>
      _emit(_style.copyWith(colorStops: stops));

  void _addStop() {
    final stops = _style.colorStops;
    final nextValue = stops.isEmpty ? 0.0 : stops.last.value + 10;
    _setStops([...stops, ColorStop(value: nextValue, color: '#4CAF50')]);
  }

  void _updateStop(int index, {double? value, String? color}) {
    final stops = List<ColorStop>.of(_style.colorStops);
    final old = stops[index];
    stops[index] = ColorStop(
      value: value ?? old.value,
      color: color ?? old.color,
    );
    _setStops(stops);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stops = _style.colorStops;
    final l10n = AppLocalizations.of(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.chartStyleTitle,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (widget.style != null)
              TextButton(
                key: const Key('reset_chart_style_button'),
                onPressed: () => widget.onChanged(null),
                child: Text(l10n.commonReset),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(l10n.chartStyleDescription, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              key: const Key('preset_green_to_red'),
              onPressed: () => _setStops(List.of(ChartStyle.greenToRedStops)),
              child: Text(l10n.chartStylePresetGreenToRed),
            ),
            OutlinedButton(
              key: const Key('preset_red_to_green'),
              onPressed: () => _setStops(List.of(ChartStyle.redToGreenStops)),
              child: Text(l10n.chartStylePresetRedToGreen),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < stops.length; i++) _buildStopRow(i, stops[i]),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('add_color_stop_button'),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.chartStyleAddStop),
            onPressed: _addStop,
          ),
        ),
        const Divider(),
        SwitchListTile(
          key: const Key('chart_fill_switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.chartStyleFillArea),
          value: _style.fillArea,
          onChanged: (v) => _emit(_style.copyWith(fillArea: v)),
        ),
        SwitchListTile(
          key: const Key('chart_grid_switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.chartStyleGrid),
          value: _style.showGrid,
          onChanged: (v) => _emit(_style.copyWith(showGrid: v)),
        ),
        SwitchListTile(
          key: const Key('chart_axes_switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.chartStyleAxes),
          value: _style.showAxes,
          onChanged: (v) => _emit(_style.copyWith(showAxes: v)),
        ),
        SwitchListTile(
          key: const Key('chart_minmax_switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.chartStyleMarkMinMax),
          value: _style.markMinMax,
          onChanged: (v) => _emit(_style.copyWith(markMinMax: v)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('chart_line_width_field'),
          controller: _lineWidthController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.chartStyleLineWidth,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (text) {
            final parsed = double.tryParse(text.replaceAll(',', '.'));
            if (parsed != null && parsed > 0) {
              _emit(_style.copyWith(lineWidth: parsed));
            }
          },
        ),
      ],
    );
    if (widget.embedded) {
      return KeyedSubtree(key: const Key('chart_style_editor'), child: content);
    }
    return Card(
      key: const Key('chart_style_editor'),
      child: Padding(padding: const EdgeInsets.all(16), child: content),
    );
  }

  Widget _buildStopRow(int index, ColorStop stop) {
    final argb = parseHexColor(stop.color);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 10, right: 8),
            decoration: BoxDecoration(
              color: argb == null ? Colors.transparent : Color(argb),
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(
            width: 90,
            child: TextFormField(
              key: Key('color_stop_value_$index'),
              controller: _valueControllers[index],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.chartStyleStopValue,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (text) {
                final parsed = double.tryParse(text.replaceAll(',', '.'));
                if (parsed != null) _updateStop(index, value: parsed);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: Key('color_stop_color_$index'),
              controller: _colorControllers[index],
              decoration: InputDecoration(
                labelText: l10n.chartStyleStopColor,
                hintText: '#RRGGBB',
                border: const OutlineInputBorder(),
                isDense: true,
                errorText: argb == null ? l10n.colorInvalid : null,
              ),
              onChanged: (text) => _updateStop(index, color: text.trim()),
            ),
          ),
          IconButton(
            key: Key('delete_color_stop_$index'),
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: l10n.chartStyleDeleteStop,
            onPressed: () {
              final stops = List<ColorStop>.of(_style.colorStops)
                ..removeAt(index);
              _setStops(stops);
            },
          ),
        ],
      ),
    );
  }
}
