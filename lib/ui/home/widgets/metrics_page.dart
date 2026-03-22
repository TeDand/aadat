import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/metrics/habit_metrics.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MetricsPage extends StatelessWidget {
  const MetricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final habitStats = HabitStats.compute(vm);
    final today = habitDateOnly(DateTime.now());
    final todaySummary = vm.completionSummaryForDay(today);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Metrics',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: habitStats.isEmpty
          ? _EmptyMetrics(scheme: scheme, textTheme: textTheme)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _TodaySummaryCard(
                  completed: todaySummary.completed,
                  total: todaySummary.total,
                  scheme: scheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 20),
                Text(
                  'Habit streaks',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (final stats in habitStats) ...[
                  _HabitStreakCard(
                    stats: stats,
                    scheme: scheme,
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({
    required this.completed,
    required this.total,
    required this.scheme,
    required this.textTheme,
  });

  final int completed;
  final int total;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final frac = total == 0 ? 0.0 : completed / total;
    final allDone = total > 0 && completed == total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today_rounded, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Today's habits",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (allDone) ...[
                  const Spacer(),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 22,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            if (total == 0)
              Text(
                'No habits due today.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: frac,
                  minHeight: 10,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: allDone ? Colors.green : scheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$completed of $total habits completed',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HabitStreakCard extends StatelessWidget {
  const _HabitStreakCard({
    required this.stats,
    required this.scheme,
    required this.textTheme,
  });

  final HabitStats stats;
  final ColorScheme scheme;
  final TextTheme textTheme;

  static const _dailyAccent = Color(0xFFEA580C);
  static const _weeklyAccent = Color(0xFF2563EB);
  static const _monthlyAccent = Color(0xFF059669);

  Color _accentFor(HabitRecurrence r) => switch (r) {
    HabitRecurrence.daily => _dailyAccent,
    HabitRecurrence.weekly => _weeklyAccent,
    HabitRecurrence.monthly => _monthlyAccent,
  };

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(stats.habit.recurrence);
    final rateText = stats.completionRate != null
        ? '${(stats.completionRate! * 100).round()}%'
        : '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stats.habit.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _RecurrenceChip(
                  recurrence: stats.habit.recurrence,
                  accent: accent,
                ),
              ],
            ),
            if (stats.habit.category.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                stats.habit.category,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: stats.currentStreak > 0
                        ? Colors.orange
                        : Colors.grey,
                    label: 'Current streak',
                    value: '${stats.currentStreak}',
                    unit: stats.streakUnit,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.emoji_events_rounded,
                    iconColor: Colors.amber.shade700,
                    label: 'Best streak',
                    value: '${stats.bestStreak}',
                    unit: stats.streakUnit,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.percent_rounded,
                    iconColor: accent,
                    label: stats.ratePeriodCaption,
                    value: rateText,
                    unit: 'done',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurrenceChip extends StatelessWidget {
  const _RecurrenceChip({required this.recurrence, required this.accent});

  final HabitRecurrence recurrence;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        recurrence.displayName,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: t.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: 10,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: t.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        Text(
          unit,
          style: t.labelSmall?.copyWith(color: scheme.outline, fontSize: 10),
        ),
      ],
    );
  }
}

class _EmptyMetrics extends StatelessWidget {
  const _EmptyMetrics({required this.scheme, required this.textTheme});

  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined, size: 64, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              'No data yet',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Add habits on Home and log them on the calendar to see streaks here.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
