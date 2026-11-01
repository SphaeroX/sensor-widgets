import 'package:flutter/material.dart';
import 'package:sensor_widgets/presentation/help/formula_help_content.dart';

/// In-app help for the formula language with ready-made templates.
///
/// With [applyEnabled] each template offers an apply button that closes the
/// screen and returns the chosen [FormulaTemplate].
class FormulaHelpScreen extends StatelessWidget {
  final bool applyEnabled;

  const FormulaHelpScreen({super.key, this.applyEnabled = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Formel-Hilfe')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final section in formulaHelpSections)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(section.body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Funktionen und Konstanten',
              style: theme.textTheme.titleMedium,
            ),
          ),
          for (final entry in formulaHelpEntries)
            Card(
              key: Key('help_entry_${entry.name}'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      entry.signature,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(entry.description),
                    const SizedBox(height: 4),
                    Text(
                      'Beispiel: ${entry.example}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Vorlagen', style: theme.textTheme.titleMedium),
          ),
          for (final template in formulaTemplates)
            Card(
              key: Key('help_template_${template.id}'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(template.description),
                    const SizedBox(height: 8),
                    for (final step in template.steps)
                      Text(
                        '${step.name} = ${step.expression}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    Text(
                      'Ergebnis = ${template.formula}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (applyEnabled)
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          key: Key('apply_template_${template.id}'),
                          icon: const Icon(Icons.download_done, size: 18),
                          label: const Text('Vorlage übernehmen'),
                          onPressed: () => Navigator.of(context).pop(template),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
