import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/habit_model.dart';
import '../view_models/home_viewmodel.dart';

class HabitTemplate {
  const HabitTemplate({
    required this.name,
    required this.description,
    required this.habits,
  });

  final String name;
  final String description;
  final List<Habit> habits;
}

final habitTemplates = [
  HabitTemplate(
    name: '75 Medium',
    description:
        '75 days of healthy habits — a sustainable, beginner-friendly challenge.',
    habits: [
      Habit(
        title: 'Workout 45 min',
        description: 'Any exercise for at least 45 minutes.',
        category: 'Fitness',
        recurrence: HabitRecurrence.daily,
        startDate: habitDateOnly(DateTime.now()),
      ),
      Habit(
        title: 'Drink 2.5L water',
        description: 'Hit your daily hydration goal.',
        category: 'Health',
        recurrence: HabitRecurrence.daily,
        startDate: habitDateOnly(DateTime.now()),
      ),
      Habit(
        title: 'Follow your diet',
        description:
            'Stick to your chosen diet plan — one treat allowed per week.',
        category: 'Health',
        recurrence: HabitRecurrence.daily,
        startDate: habitDateOnly(DateTime.now()),
      ),
      Habit(
        title: 'Read 10 pages',
        description: 'Read at least 10 pages of a non-fiction book.',
        category: 'Learning',
        recurrence: HabitRecurrence.daily,
        startDate: habitDateOnly(DateTime.now()),
      ),
      Habit(
        title: 'Progress photo',
        description: 'Take a weekly progress photo to track your transformation.',
        category: 'Fitness',
        recurrence: HabitRecurrence.weekly,
        startDate: habitDateOnly(DateTime.now()),
      ),
    ],
  ),
  HabitTemplate(
    name: 'Morning Routine',
    description: 'A simple daily routine to start each day with intention.',
    habits: [
      Habit(
        title: 'Make your bed',
        description: 'Start the day with a small win.',
        category: 'Mindset',
        recurrence: HabitRecurrence.daily,
        startDate: habitDateOnly(DateTime.now()),
      ),
      Habit(
        title: '10 min meditation',
        description: 'Quiet your mind before the day begins.',
        category: 'Mindset',
        recurrence: HabitRecurrence.daily,
        startDate: habitDateOnly(DateTime.now()),
      ),
      Habit(
        title: 'Morning walk',
        description: 'Get outside and move within the first hour of waking.',
        category: 'Fitness',
        recurrence: HabitRecurrence.daily,
        startDate: habitDateOnly(DateTime.now()),
      ),
      Habit(
        title: 'Journal',
        description: 'Write 3 things you\'re grateful for.',
        category: 'Mindset',
        recurrence: HabitRecurrence.daily,
        startDate: habitDateOnly(DateTime.now()),
      ),
    ],
  ),
  HabitTemplate(
    name: 'Deep Work',
    description: 'Build the focus and learning habits that compound over time.',
    habits: [
      Habit(
        title: '2h deep work block',
        description: 'No distractions — phone away, single task only.',
        category: 'Work',
        recurrence: HabitRecurrence.daily,
        startDate: habitDateOnly(DateTime.now()),
      ),
      Habit(
        title: 'Read 20 pages',
        description: 'Read anything that sharpens your thinking.',
        category: 'Learning',
        recurrence: HabitRecurrence.daily,
        startDate: habitDateOnly(DateTime.now()),
      ),
      Habit(
        title: 'Weekly review',
        description: 'Reflect on the week — what worked, what didn\'t.',
        category: 'Work',
        recurrence: HabitRecurrence.weekly,
        startDate: habitDateOnly(DateTime.now()),
      ),
      Habit(
        title: 'Learn something new',
        description:
            'Spend 30 min on a skill or subject outside your comfort zone.',
        category: 'Learning',
        recurrence: HabitRecurrence.daily,
        startDate: habitDateOnly(DateTime.now()),
      ),
    ],
  ),
];

/// Compact section widget for the Home page.
class TemplatesSection extends StatelessWidget {
  const TemplatesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Not sure where to start?',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Try a template based on popular habit-building techniques. '
          'See the Resources tab for further reading.',
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
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
      ],
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.template});

  final HabitTemplate template;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => _showSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                template.name,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${template.habits.length} habits',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    final homeViewModel = context.read<HomeViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => ChangeNotifierProvider.value(
        value: homeViewModel,
        child: _TemplateSheet(template: template),
      ),
    );
  }
}

class _TemplateSheet extends StatelessWidget {
  const _TemplateSheet({required this.template});

  final HabitTemplate template;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: ListView(
          controller: controller,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.name,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${template.habits.length} habits',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              template.description,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Included habits',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            for (final h in template.habits) ...[
              _HabitRow(habit: h, scheme: scheme, textTheme: textTheme),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _confirmLoad(context),
              child: const Text('Use this template'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLoad(BuildContext context) async {
    final vm = context.read<HomeViewModel>();
    Navigator.pop(context);

    var added = 0;
    for (final habit in template.habits) {
      final result = await vm.addHabit(habit);
      if (result == 'habit added!') added++;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added == 0
              ? 'All habits already exist.'
              : '$added habit${added == 1 ? '' : 's'} added from ${template.name}.',
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: const RoundedRectangleBorder(),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.habit,
    required this.scheme,
    required this.textTheme,
  });

  final Habit habit;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(Icons.circle, size: 6, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      habit.title,
                      style: textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    habit.recurrence.displayName,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (habit.description.isNotEmpty)
                Text(
                  habit.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
