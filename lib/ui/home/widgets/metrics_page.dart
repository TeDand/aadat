import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/metrics/habit_metrics.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Progress overview: streaks, averages, 7-day trend, breakdowns.
class MetricsPage extends StatelessWidget {
  const MetricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final m = HabitMetrics.compute(vm);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            pinned: true,
            expandedHeight: 120,
            backgroundColor: scheme.surfaceContainerLowest,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Metrics',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer.withValues(alpha: 0.45),
                      scheme.surfaceContainerLowest,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (m.totalHabits == 0)
                  _EmptyMetrics(scheme: scheme, textTheme: textTheme)
                else ...[
                  Text(
                    'Overview',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: const Color(0xFFEA580C),
                          label: 'Perfect-day streak',
                          value: '${m.perfectDayStreak}',
                          subtitle: 'days in a row',
                          scheme: scheme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.percent_rounded,
                          iconColor: scheme.primary,
                          label: '7-day average',
                          value: m.avgCompletionLast7DaysPercent != null
                              ? '${m.avgCompletionLast7DaysPercent!.round()}%'
                              : '—',
                          subtitle: 'completion',
                          scheme: scheme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.calendar_month_rounded,
                          iconColor: const Color(0xFF059669),
                          label: '30-day average',
                          value: m.avgCompletionLast30DaysPercent != null
                              ? '${m.avgCompletionLast30DaysPercent!.round()}%'
                              : '—',
                          subtitle: 'completion',
                          scheme: scheme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.emoji_events_rounded,
                          iconColor: const Color(0xFF7C3AED),
                          label: 'Perfect days',
                          value: m.daysWithHabitsLast30 > 0
                              ? '${m.perfectDaysLast30}/${m.daysWithHabitsLast30}'
                              : '—',
                          subtitle: 'last 30 days',
                          scheme: scheme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _TodayCard(m: m, scheme: scheme, textTheme: textTheme),
                  const SizedBox(height: 24),
                  Text(
                    'Last 7 days',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _WeekBars(
                    percents: m.last7DayPercents,
                    labels: m.last7DayLabels,
                    scheme: scheme,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Your habits',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BreakdownCard(
                    title: 'By category',
                    child: _CategoryBars(
                      data: m.habitsByCategory,
                      scheme: scheme,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BreakdownCard(
                    title: 'By recurrence',
                    child: _RecurrenceRow(
                      data: m.habitsByRecurrence,
                      scheme: scheme,
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMetrics extends StatelessWidget {
  const _EmptyMetrics({
    required this.scheme,
    required this.textTheme,
  });

  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 64,
            color: scheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No data yet',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Add habits on Home and log them on the calendar\nto see streaks and trends here.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.scheme,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 12),
            Text(
              label,
              style: t.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: t.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              subtitle,
              style: t.labelSmall?.copyWith(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.m,
    required this.scheme,
    required this.textTheme,
  });

  final HabitMetrics m;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final total = m.todayTotal;
    final done = m.todayCompleted;
    final frac = total == 0 ? 0.0 : done / total;

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
                  'Today',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (total == 0)
              Text(
                'No habits apply today (check start dates).',
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
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$done of $total habits completed',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({
    required this.percents,
    required this.labels,
    required this.scheme,
  });

  final List<int> percents;
  final List<String> labels;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        child: SizedBox(
          height: 148,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < percents.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Text(
                          '${percents[i]}%',
                          style: t.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, c) {
                              final h = c.maxHeight * (percents[i] / 100);
                              return Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                  width: double.infinity,
                                  height: h.clamp(4.0, c.maxHeight),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        scheme.primary.withValues(alpha: 0.35),
                                        scheme.primary,
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          labels[i],
                          style: t.labelSmall?.copyWith(
                            color: scheme.outline,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: t.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _CategoryBars extends StatelessWidget {
  const _CategoryBars({
    required this.data,
    required this.scheme,
  });

  final Map<String, int> data;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${e.value}',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: e.value / total,
                    minHeight: 6,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: scheme.secondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecurrenceRow extends StatelessWidget {
  const _RecurrenceRow({
    required this.data,
    required this.scheme,
  });

  final Map<HabitRecurrence, int> data;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final order = HabitRecurrence.values;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final r in order)
          if ((data[r] ?? 0) > 0)
            Chip(
              avatar: Icon(
                _iconFor(r),
                size: 18,
                color: scheme.primary,
              ),
              label: Text('${r.displayName} · ${data[r]}'),
              backgroundColor: scheme.primaryContainer.withValues(alpha: 0.4),
              side: BorderSide.none,
            ),
      ],
    );
  }

  IconData _iconFor(HabitRecurrence r) {
    switch (r) {
      case HabitRecurrence.daily:
        return Icons.today;
      case HabitRecurrence.weekly:
        return Icons.date_range;
      case HabitRecurrence.monthly:
        return Icons.calendar_month;
    }
  }
}
