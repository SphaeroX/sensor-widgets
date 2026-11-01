import 'package:flutter/material.dart';
import 'package:sensor_widgets/core/utils/number_formatter.dart';
import 'package:sensor_widgets/domain/chart/chart_color.dart';
import 'package:sensor_widgets/domain/models/widget_appearance.dart';
import 'package:sensor_widgets/domain/models/threshold_rule.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/widgets/preview/history_chart_painter.dart';

/// Live preview card rendering mock native representation for all 6 widget types.
class WidgetLivePreviewCard extends StatelessWidget {
  final WidgetDefinition widgetDef;
  final WidgetPreviewData? previewData;

  const WidgetLivePreviewCard({
    super.key,
    required this.widgetDef,
    this.previewData,
  });

  Color? _color(String? hex) {
    final argb = hex == null ? null : parseHexColor(hex);
    return argb == null ? null : Color(argb);
  }

  @override
  Widget build(BuildContext context) {
    final appearance = widgetDef.appearance;
    if (appearance == null) return _buildCard(context);

    // Same parameters as the native widgets: text and accent colors, font scale.
    final base = Theme.of(context);
    final text = _color(appearance.textColor);
    final accent = _color(appearance.accentColor);
    var scheme = base.colorScheme;
    var textTheme = base.textTheme;
    if (text != null) {
      scheme = scheme.copyWith(
        onSurface: text,
        onSurfaceVariant: text.withValues(alpha: 0.7),
        onPrimaryContainer: text,
      );
      textTheme = textTheme.apply(bodyColor: text, displayColor: text);
    }
    if (accent != null) scheme = scheme.copyWith(primary: accent);

    return Theme(
      data: base.copyWith(colorScheme: scheme, textTheme: textTheme),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            appearance.fontScale ?? WidgetAppearance.defaultFontScale,
          ),
        ),
        child: Builder(builder: _buildCard),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = widgetDef.appearance;
    final background = _color(appearance?.backgroundColor);
    final radius =
        appearance?.cornerRadius ?? WidgetAppearance.defaultCornerRadius;
    final opacity = appearance?.backgroundOpacity;

    return Card(
      elevation: 3,
      color: appearance == null
          ? null
          : (background ?? theme.colorScheme.surface).withValues(
              alpha: opacity ?? WidgetAppearance.defaultBackgroundOpacity,
            ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: appearance != null
              ? null
              : LinearGradient(
                  colors: [
                    theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.8,
                    ),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForType(widgetDef.type),
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widgetDef.title.isNotEmpty
                        ? widgetDef.title
                        : 'Widget Vorschau',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widgetDef.type.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (previewData?.hasError == true) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        previewData!.errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (previewData == null) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Noch keine Vorschau geladen.\nDrücke auf „Vorschau laden“.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ] else ...[
              _buildTypeContent(context),
              for (final note in previewData?.bucketErrors ?? const <String>[])
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          note,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeContent(BuildContext context) {
    final theme = Theme.of(context);
    final unit = widgetDef.unit ?? '';

    switch (widgetDef.type) {
      case WidgetType.singleValue:
        final val = previewData?.singleValue?.value;
        final formatted = NumberFormatter.format(
          val,
          decimalPlaces: widgetDef.decimalPlaces,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  formatted,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  unit,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ],
          ),
        );

      case WidgetType.historyChart:
        final points = previewData?.historyPoints ?? [];
        if (points.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Keine Datenpunkte im gewählten Zeitraum gefunden.'),
          );
        }
        final minVal = points
            .map((p) => p.value)
            .reduce((a, b) => a < b ? a : b);
        final maxVal = points
            .map((p) => p.value)
            .reduce((a, b) => a > b ? a : b);
        final latest = points.last.value;

        final minStr = NumberFormatter.format(
          minVal,
          decimalPlaces: widgetDef.decimalPlaces,
        );
        final maxStr = NumberFormatter.format(
          maxVal,
          decimalPlaces: widgetDef.decimalPlaces,
        );
        final latestStr = NumberFormatter.format(
          latest,
          decimalPlaces: widgetDef.decimalPlaces,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktuell: $latestStr $unit  (Min: $minStr, Max: $maxStr)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (widgetDef.chartStyle != null)
              SizedBox(
                height: 90,
                width: double.infinity,
                child: CustomPaint(
                  key: const Key('history_chart_canvas'),
                  painter: HistoryChartPainter(
                    values: points.map((p) => p.value).toList(),
                    style: widgetDef.chartStyle!,
                    lineColor: theme.colorScheme.primary,
                    labelColor: theme.colorScheme.onSurfaceVariant,
                    gridColor: theme.colorScheme.outlineVariant,
                  ),
                ),
              )
            else
              SizedBox(
                height: 60,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: points.map((p) {
                    final range = (maxVal - minVal) == 0
                        ? 1.0
                        : (maxVal - minVal);
                    final ratio = ((p.value - minVal) / range).clamp(0.1, 1.0);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Container(
                          height: 60 * ratio,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.7,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        );

      case WidgetType.indicatorLamp:
        final val = previewData?.singleValue?.value;
        final rule = widgetDef.threshold;
        bool active = false;
        if (val != null && rule != null) {
          active = rule.matches(val);
        }
        final lampColor = active ? Colors.green : Colors.grey;
        final opStr = rule?.operator == ThresholdOperator.lessThan ? '<' : '>';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lampColor,
                  boxShadow: [
                    BoxShadow(
                      color: lampColor.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    val != null
                        ? '${NumberFormatter.format(val, decimalPlaces: widgetDef.decimalPlaces)} $unit'
                        : '--',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    rule != null
                        ? 'Bedingung: $opStr ${rule.value} (${active ? "Aktiv" : "Inaktiv"})'
                        : 'Keine Schwelle konfiguriert',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        );

      case WidgetType.aggregate:
        final aggs = previewData?.aggregateValues ?? {};
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAggBox(context, 'MIN', aggs['min'], unit),
              _buildAggBox(context, 'MEAN', aggs['mean'], unit),
              _buildAggBox(context, 'MAX', aggs['max'], unit),
            ],
          ),
        );

      case WidgetType.gaugeBar:
        final val = previewData?.singleValue?.value ?? 0;
        final minVal = widgetDef.min ?? 0;
        final maxVal = widgetDef.max ?? 100;
        final progress = maxVal > minVal
            ? ((val - minVal) / (maxVal - minVal)).clamp(0.0, 1.0)
            : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${NumberFormatter.format(minVal, decimalPlaces: 0)} $unit',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '${NumberFormatter.format(val, decimalPlaces: widgetDef.decimalPlaces)} $unit',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '${NumberFormatter.format(maxVal, decimalPlaces: 0)} $unit',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        );

      case WidgetType.multiValue:
        final multi = previewData?.multiValues ?? {};
        final rowErrors = previewData?.multiErrors ?? const <String, String>{};
        if (multi.isEmpty && rowErrors.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Keine Multi-Value Datenpunkte geladen.'),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children:
                multi.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${NumberFormatter.format(e.value.value, decimalPlaces: widgetDef.decimalPlaces)} $unit',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList() +
                rowErrors.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        Text(
                          e.value,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        );
    }
  }

  Widget _buildAggBox(
    BuildContext context,
    String label,
    double? val,
    String unit,
  ) {
    final theme = Theme.of(context);
    final formatted = NumberFormatter.format(
      val,
      decimalPlaces: widgetDef.decimalPlaces,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            '$formatted $unit',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(WidgetType type) {
    switch (type) {
      case WidgetType.singleValue:
        return Icons.looks_one_outlined;
      case WidgetType.historyChart:
        return Icons.show_chart;
      case WidgetType.indicatorLamp:
        return Icons.lightbulb_outline;
      case WidgetType.multiValue:
        return Icons.grid_view;
      case WidgetType.aggregate:
        return Icons.functions;
      case WidgetType.gaugeBar:
        return Icons.speed;
    }
  }
}
