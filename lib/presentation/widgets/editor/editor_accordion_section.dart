import 'package:flutter/material.dart';

/// One collapsible card of the widget editor accordion.
///
/// The header (`editor_section_<id>`) toggles the section. A closed section
/// keeps its [child] mounted but offstage, so form fields keep their state and
/// still take part in `Form.validate()`. Only opening and closing animate;
/// content changes inside an open section show at once.
class EditorAccordionSection extends StatefulWidget {
  final String id;
  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const EditorAccordionSection({
    super.key,
    required this.id,
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  State<EditorAccordionSection> createState() => _EditorAccordionSectionState();
}

class _EditorAccordionSectionState extends State<EditorAccordionSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: widget.expanded ? 1 : 0,
  );
  late final Animation<double> _heightFactor = _controller.drive(
    CurveTween(curve: Curves.easeInOut),
  );

  @override
  void didUpdateWidget(covariant EditorAccordionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != oldWidget.expanded) {
      if (widget.expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expanded = widget.expanded;
    final color = expanded
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            key: Key('editor_section_${widget.id}_semantics'),
            button: true,
            expanded: expanded,
            child: InkWell(
              key: Key('editor_section_${widget.id}'),
              onTap: widget.onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 20, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: expanded ? theme.colorScheme.primary : null,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more, color: color),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final closed = !expanded && _controller.isDismissed;
              // Clip only while animating: floating field labels reach a bit
              // above the body and must not be cut off when open. The
              // ClipRect always stays in the tree, otherwise the body would be
              // rebuilt from scratch and lose its state.
              return ClipRect(
                clipBehavior: _controller.isCompleted
                    ? Clip.none
                    : Clip.hardEdge,
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _heightFactor.value,
                  child: Offstage(
                    offstage: closed,
                    child: TickerMode(enabled: !closed, child: child!),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
