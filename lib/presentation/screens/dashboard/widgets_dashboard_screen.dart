import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/help/formula_help_screen.dart';
import 'package:sensor_widgets/presentation/screens/connections/connections_list_screen.dart';
import 'package:sensor_widgets/presentation/screens/editor/widget_editor_screen.dart';

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
                    const Icon(
                      Icons.widgets_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Noch keine Widgets konfiguriert',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Erstelle dein erstes Widget für den Homescreen!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
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
            padding: const EdgeInsets.all(12),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            _getIcon(widgetDef.type),
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widgetDef.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widgetDef.type.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${widgetDef.measurement} • alle ${widgetDef.refreshIntervalMinutes}m',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WidgetEditorScreen(widgetToEdit: widgetDef),
                ),
              );
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
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Löschen', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WidgetEditorScreen(widgetToEdit: widgetDef),
            ),
          );
        },
      ),
    );
  }

  IconData _getIcon(WidgetType type) {
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
