import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/help/formula_help_screen.dart';
import 'package:sensor_widgets/presentation/screens/connections/connections_list_screen.dart';
import 'package:sensor_widgets/presentation/screens/editor/widget_editor_screen.dart';
import 'package:sensor_widgets/presentation/widgets/widget_type_visuals.dart';

/// Dashboard overview screen showing all configured sensor widgets.
class WidgetsDashboardScreen extends ConsumerWidget {
  const WidgetsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgetsAsync = ref.watch(widgetsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Widgets'),
        actions: [
          IconButton(
            key: const Key('refresh_native_widgets_btn'),
            icon: const Icon(Icons.sync),
            tooltip: 'Native Widgets synchronisieren',
            onPressed: () async {
              await ref
                  .read(widgetsControllerProvider.notifier)
                  .triggerNativeRefresh();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Native Widgets aktualisiert.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          IconButton(
            key: const Key('open_formula_help_btn'),
            icon: const Icon(Icons.help_outline),
            tooltip: 'Formel-Hilfe',
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
            tooltip: 'InfluxDB Verbindungen',
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
        error: (err, _) => Center(child: Text('Fehler: $err')),
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
                      'Noch keine Widgets konfiguriert',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erstelle dein erstes Widget für den Homescreen!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Neues Widget anlegen'),
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
                          '${widgetDef.measurement} • alle ${widgetDef.refreshIntervalMinutes}m',
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
                child: _MiniPreview(
                  key: Key('dashboard_card_preview_${widgetDef.id}'),
                  type: widgetDef.type,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Aktionen',
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
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Bearbeiten'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, size: 20),
              SizedBox(width: 8),
              Text('Duplizieren'),
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
                'Löschen',
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
class _MiniPreview extends StatelessWidget {
  final WidgetType type;

  const _MiniPreview({super.key, required this.type});

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
