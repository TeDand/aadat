import 'package:flutter/material.dart';
import 'resources_page.dart';

class HabitGuidesPage extends StatelessWidget {
  const HabitGuidesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Where to start'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: scheme.outlineVariant),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          Text(
            'Building better habits',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'Habits are the small decisions you make and actions you perform every day. '
            'Research shows that the secret to habits that stick is starting small, '
            'being consistent, and linking new behaviours to existing ones.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          _TipCard(
            scheme: scheme,
            textTheme: textTheme,
            title: 'Start small',
            body: 'Make your habit so easy you can\'t say no. '
                'Two minutes is a good starting point.',
          ),
          const SizedBox(height: 10),
          _TipCard(
            scheme: scheme,
            textTheme: textTheme,
            title: 'Never miss twice',
            body: 'Missing once is an accident. '
                'Missing twice is the start of a new (bad) habit.',
          ),
          const SizedBox(height: 10),
          _TipCard(
            scheme: scheme,
            textTheme: textTheme,
            title: 'Stack your habits',
            body: 'After I [current habit], I will [new habit]. '
                'Attach new behaviours to existing ones.',
          ),
          const SizedBox(height: 36),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 20),
          Text(
            'If you\'re interested, here are some resources we like.',
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

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.scheme,
    required this.textTheme,
    required this.title,
    required this.body,
  });

  final ColorScheme scheme;
  final TextTheme textTheme;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
