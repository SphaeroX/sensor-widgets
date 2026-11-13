import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_widgets/core/utils/number_formatter.dart';
import 'package:sensor_widgets/domain/models/chart_style.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/help/formula_help_screen.dart';
import 'package:sensor_widgets/presentation/screens/connections/connections_list_screen.dart';
import 'package:sensor_widgets/presentation/screens/editor/widget_editor_screen.dart';
import 'package:sensor_widgets/presentation/widgets/preview/history_chart_painter.dart';
import 'package:sensor_widgets/presentation/widgets/widget_type_visuals.dart';

/// Dashboard overview screen showing all configured sensor widgets.
class WidgetsDashboardScreen extends ConsumerStatefulWidget {
  const WidgetsDashboardScreen({super.key});

  @override
  ConsumerState<WidgetsDashboardScreen> createState() =>
      _WidgetsDashboardScreenState();
}

class _WidgetsDashboardScreenState
    extends ConsumerState<WidgetsDashboardScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The app often stays in memory overnight: coming back must not show the
    // values of the evening, and it pokes the home-screen widgets, whose
    // background refresh the system may have postponed.
    _lifecycle = AppLifecycleListener(onResume: _reloadLiveData);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _reloadLiveData() async {
    ref.invalidate(dashboardPreviewProvider);
    try {
      await ref.read(widgetsControllerProvider.future);
      if (!mounted) return;
      await ref.read(widgetsControllerProvider.notifier).triggerNativeRefresh();
    } catch (_) {
      // Widgets not loaded or no platform channel: the next resume tries again.
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgetsAsync = ref.watch(widgetsControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            key: const Key('refresh_native_widgets_btn'),
            icon: const Icon(Icons.sync),
            tooltip: l10n.dashboardSyncTooltip,
            onPressed: () async {
              ref.invalidate(dashboardPreviewProvider);
              await ref
                  .read(widgetsControllerProvider.notifier)
                  .triggerNativeRefresh();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.dashboardSyncDone),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          IconButton(
            key: const Key('open_formula_help_btn'),
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.dashboardHelpTooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FormulaHelpScreen(),
                ),
              );
            },
          ),
          IconButton(
            key: const Key('open_connections_btn'),
            icon: const Icon(Icons.settings_ethernet),
            tooltip: l10n.dashboardConnectionsTooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ConnectionsListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: widgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.commonErrorDetails('$err'))),
        data: (widgets) {
          if (widgets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.widgets_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.dashboardEmptyTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.dashboardEmptyBody,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(l10n.dashboardCreateWidget),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const WidgetEditorScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: widgets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final widgetDef = widgets[index];
              return _WidgetCardItem(widgetDef: widgetDef);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_widget_fab'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const WidgetEditorScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _WidgetCardItem extends ConsumerWidget {
  final WidgetDefinition widgetDef;

  const _WidgetCardItem({required this.widgetDef});

  void _openEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WidgetEditorScreen(widgetToEdit: widgetDef),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openEditor(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      WidgetTypeVisuals.icon(widgetDef.type),
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widgetDef.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context).dashboardCardSubtitle(
                            widgetDef.measurement,
                            widgetDef.refreshIntervalMinutes,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widgetDef.type.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  _buildMenu(context, ref),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _LiveCardPreview(
                  key: Key('dashboard_card_preview_${widgetDef.id}'),
                  widgetDef: widgetDef,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: l10n.dashboardActionsTooltip,
      onSelected: (value) async {
        if (value == 'edit') {
          _openEditor(context);
        } else if (value == 'duplicate') {
          await ref
              .read(widgetsControllerProvider.notifier)
              .duplicateWidget(widgetDef);
        } else if (value == 'delete') {
          await ref
              .read(widgetsControllerProvider.notifier)
              .deleteWidget(widgetDef.id);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 20),
              const SizedBox(width: 8),
              Text(l10n.commonEdit),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              const Icon(Icons.copy, size: 20),
              const SizedBox(width: 8),
              Text(l10n.commonDuplicate),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.commonDelete,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Decorative placeholder that hints at what the widget type looks like.
/// Real data of the widget; the type placeholder while loading or on errors.
class _LiveCardPreview extends ConsumerWidget {
  final WidgetDefinition widgetDef;

  const _LiveCardPreview({super.key, required this.widgetDef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardPreviewProvider(widgetDef)).value;
    final live = data == null || data.hasError ? null : _live(context, data);
    return live ?? _MiniPreview(type: widgetDef.type);
  }

  String _fmt(double? v) {
    final text = NumberFormatter.format(
      v,
      decimalPlaces: widgetDef.decimalPlaces,
    );
    final unit = widgetDef.unit;
    return unit == null || unit.isEmpty ? text : '$text $unit';
  }

  Widget? _live(BuildContext context, WidgetPreviewData data) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final key = Key('dashboard_card_live_${widgetDef.id}');
    switch (widgetDef.type) {
      case WidgetType.historyChart:
        final values = (data.historyPoints ?? const [])
            .map((p) => p.value)
            .toList();
        if (values.length < 2) return null;
        return SizedBox(
          key: key,
          height: 40,
          child: Row(
            children: [
              Text(_fmt(values.last), style: valueStyle),
              const SizedBox(width: 12),
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: HistoryChartPainter(
                    values: values,
                    style: (widgetDef.chartStyle ?? const ChartStyle())
                        .copyWith(showAxes: false, showGrid: false),
                    lineColor: theme.colorScheme.primary,
                    labelColor: theme.colorScheme.onSurfaceVariant,
                    gridColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        );
      case WidgetType.singleValue:
      case WidgetType.indicatorLamp:
      case WidgetType.gaugeBar:
        final point = data.singleValue;
        if (point == null) return null;
        return Text(_fmt(point.value), key: key, style: valueStyle);
      case WidgetType.aggregate:
        final agg = data.aggregateValues;
        if (agg == null || agg.isEmpty) return null;
        return Row(
          key: key,
          children: [
            for (final k in ['min', 'mean', 'max'])
              Expanded(
                child: Text(
                  '${k == 'mean' ? 'Ø' : k.toUpperCase()} ${_fmt(agg[k])}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
          ],
        );
      case WidgetType.multiValue:
        final multi = data.multiValues;
        if (multi == null || multi.isEmpty) return null;
        final labels = {
          for (final i in widgetDef.items ?? const []) i.field: i.label,
        };
        return Wrap(
          key: key,
          spacing: 16,
          children: [
            for (final e in multi.entries.take(4))
              Text(
                '${labels[e.key] ?? e.key}: '
                '${NumberFormatter.format(e.value.value, decimalPlaces: widgetDef.decimalPlaces)}',
                style: theme.textTheme.bodyMedium,
              ),
          ],
        );
    }
  }
}

class _MiniPreview extends StatelessWidget {
  final WidgetType type;

  const _MiniPreview({required this.type});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = scheme.primary.withValues(alpha: 0.55);
    final track = scheme.surfaceContainerHighest;

    Widget bar(double height) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );

    Widget content;
    switch (type) {
      case WidgetType.singleValue:
        content = Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 96,
            height: 14,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      case WidgetType.historyChart:
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final h in <double>[8, 14, 10, 20, 16, 24, 18]) bar(h),
          ],
        );
      case WidgetType.indicatorLamp:
        content = Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          ),
        );
      case WidgetType.multiValue:
        content = Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: track,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
          ],
        );
      case WidgetType.aggregate:
        content = Row(
          children: [
            for (final label in ['MIN', 'Ø', 'MAX'])
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
          ],
        );
      case WidgetType.gaugeBar:
        content = ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: 0.6,
            minHeight: 10,
            backgroundColor: track,
          ),
        );
    }

    return ExcludeSemantics(child: SizedBox(height: 26, child: content));
  }
}
