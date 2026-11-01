import 'package:flutter/material.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/widgets/widget_type_visuals.dart';

/// Grid of selectable tiles (icon, name, short description), one per widget type.
class WidgetTypeSelector extends StatelessWidget {
  final WidgetType selected;
  final ValueChanged<WidgetType> onSelected;

  const WidgetTypeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final columns = constraints.maxWidth >= 480 ? 3 : 2;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final type in WidgetType.values)
              SizedBox(
                width: tileWidth,
                child: _TypeTile(
                  type: type,
                  isSelected: type == selected,
                  onTap: () => onSelected(type),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TypeTile extends StatelessWidget {
  final WidgetType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeTile({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = isSelected
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final foreground = isSelected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return Semantics(
      key: Key('type_tile_${type.wireName}'),
      button: true,
      selected: isSelected,
      label: '${type.label}. ${WidgetTypeVisuals.description(type)}',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(WidgetTypeVisuals.icon(type), color: foreground),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          type.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          WidgetTypeVisuals.description(type),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) Icon(Icons.check_circle, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
