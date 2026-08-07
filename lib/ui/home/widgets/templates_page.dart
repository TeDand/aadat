import 'package:flutter/material.dart';
import 'resources_page.dart';
import 'templates_section.dart';

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Templates'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: scheme.outlineVariant),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                for (var i = 0; i < habitTemplates.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
                  _TemplateTile(template: habitTemplates[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 20),
          Text(
            'Want to learn more about building habits?',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResourcesPage()),
            ),
            child: const Text('View reading list'),
          ),
        ],
      ),
    );
  }
}

// Reuse the tile and sheet from templates_section.dart via re-export of the
// private classes is not possible, so we replicate just the tile here using
// the public habitTemplates list and _showSheet from TemplatesSection.
class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.template});
  final HabitTemplate template;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => showTemplateSheet(context, template),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.description,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${template.habits.length} habits',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
