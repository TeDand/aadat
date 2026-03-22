import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/metrics/habit_metrics.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Progress overview with separate metrics for daily, weekly, and monthly habits.
class MetricsPage extends StatelessWidget {
  const MetricsPage({super.key});

  static const _dailyAccent = Color(0xFFEA580C);
  static const _weeklyAccent = Color(0xFF2563EB);
  static const _monthlyAccent = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final m = HabitMetrics.compute(vm);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
          bottom: TabBar(
            indicatorColor: scheme.primary,
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.onSurfaceVariant,
            tabs: const [
              Tab(icon: Icon(Icons.wb_sunny_rounded, size: 20), text: 'Daily'),
              Tab(
                icon: Icon(Icons.date_range_rounded, size: 20),
                text: 'Weekly',
              ),
              Tab(
                icon: Icon(Icons.calendar_month_rounded, size: 20),
                text: 'Monthly',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MetricsTabBody(
              metrics: m.daily,
              accent: _dailyAccent,
              scheme: scheme,
              textTheme: textTheme,
              empty: m.totalHabits == 0,
              tabHint:
                  'Counts only daily habits. Averages and the chart use the same scope.',
            ),
            _MetricsTabBody(
              metrics: m.weekly,
              accent: _weeklyAccent,
              scheme: scheme,
              textTheme: textTheme,
              empty: m.totalHabits == 0,
              tabHint:
                  'Counts only weekly habits. Averages and the chart use the same scope.',
            ),
            _MetricsTabBody(
              metrics: m.monthly,
              accent: _monthlyAccent,
              scheme: scheme,
              textTheme: textTheme,
              empty: m.totalHabits == 0,
              tabHint:
                  'Counts only monthly habits. Averages and the chart use the same scope.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsTabBody extends StatelessWidget {
  const _MetricsTabBody({
    required this.metrics,
    required this.accent,
    required this.scheme,
    required this.textTheme,
    required this.empty,
    required this.tabHint,
  });

  final RecurrenceMetrics metrics;
  final Color accent;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final bool empty;
  final String tabHint;

  @override
  Widget build(BuildContext context) {
    if (empty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _EmptyMetrics(scheme: scheme, textTheme: textTheme),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          tabHint,
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        _RecurrenceSection(
          metrics: metrics,
          accent: accent,
          scheme: scheme,
          textTheme: textTheme,
        ),
      ],
    );
  }
}

class _RecurrenceSection extends StatelessWidget {
  const _RecurrenceSection({
    required this.metrics,
    required this.accent,
    required this.scheme,
    required this.textTheme,
  });

  final RecurrenceMetrics metrics;
  final Color accent;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final r = metrics.recurrence;
    final title = '${r.displayName} habits';
    final empty = metrics.habitCount == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(r), color: accent, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Chip(
                label: Text('${metrics.habitCount}'),
                visualDensity: VisualDensity.compact,
                backgroundColor: accent.withValues(alpha: 0.12),
                side: BorderSide.none,
                labelStyle: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (empty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'No ${r.displayName.toLowerCase()} habits yet. Add one on the Home tab to see stats here.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: accent,
                    label: 'Streak',
                    value: '${metrics.streak}',
                    subtitle: _streakUnit(r),
                    scheme: scheme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.percent_rounded,
                    iconColor: accent,
                    label: metrics.avgShortCaption,
                    value: metrics.avgShortPercent != null
                        ? '${metrics.avgShortPercent!.round()}%'
                        : '—',
                    subtitle: 'completion',
                    scheme: scheme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.insights_rounded,
                    iconColor: accent,
                    label: metrics.avgLongCaption,
                    value: metrics.avgLongPercent != null
                        ? '${metrics.avgLongPercent!.round()}%'
                        : '—',
                    subtitle: 'completion',
                    scheme: scheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _StatCard(
              icon: Icons.emoji_events_rounded,
              iconColor: accent,
              label: metrics.perfectWindowCaption,
              value: metrics.applicableCount > 0
                  ? '${metrics.perfectCount}/${metrics.applicableCount}'
                  : '—',
              subtitle: 'perfect / had habits',
              scheme: scheme,
            ),
            const SizedBox(height: 14),
            _PeriodProgressCard(
              metrics: metrics,
              accent: accent,
              scheme: scheme,
              textTheme: textTheme,
            ),
            const SizedBox(height: 16),
            Text(
              metrics.trendTitle,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            _TrendBars(
              percents: metrics.trendPercents,
              labels: metrics.trendLabels,
              scheme: scheme,
              accent: accent,
            ),
            const SizedBox(height: 16),
            _BreakdownCard(
              title: 'Categories (${r.displayName.toLowerCase()} only)',
              child: _CategoryBars(
                data: metrics.habitsByCategory,
                scheme: scheme,
                accent: accent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(HabitRecurrence r) {
    switch (r) {
      case HabitRecurrence.daily:
        return Icons.wb_sunny_rounded;
      case HabitRecurrence.weekly:
        return Icons.date_range_rounded;
      case HabitRecurrence.monthly:
        return Icons.calendar_month_rounded;
    }
  }
}

String _streakUnit(HabitRecurrence r) {
  switch (r) {
    case HabitRecurrence.daily:
      return 'days';
    case HabitRecurrence.weekly:
      return 'weeks';
    case HabitRecurrence.monthly:
      return 'months';
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
            'Add habits on Home and log them on the calendar\nto see per-recurrence metrics here.',
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: t.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: t.titleLarge?.copyWith(
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

class _PeriodProgressCard extends StatelessWidget {
  const _PeriodProgressCard({
    required this.metrics,
    required this.accent,
    required this.scheme,
    required this.textTheme,
  });

  final RecurrenceMetrics metrics;
  final Color accent;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final total = metrics.periodTotal;
    final done = metrics.periodCompleted;
    final frac = total == 0 ? 0.0 : done / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, color: accent),
                const SizedBox(width: 8),
                Text(
                  metrics.periodTitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              metrics.periodSubtitle,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (total == 0)
              Text(
                'No habits in this period (check start dates).',
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
                  color: accent,
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

class _TrendBars extends StatelessWidget {
  const _TrendBars({
    required this.percents,
    required this.labels,
    required this.scheme,
    required this.accent,
  });

  final List<int> percents;
  final List<String> labels;
  final ColorScheme scheme;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 16),
        child: SizedBox(
          height: 148,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < percents.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Text(
                          '${percents[i]}%',
                          style: t.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                            fontSize: 10,
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
                                        accent.withValues(alpha: 0.35),
                                        accent,
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
                            fontSize: 9,
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
    required this.accent,
  });

  final Map<String, int> data;
  final ColorScheme scheme;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return Text(
        'No categories',
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
                        color: accent,
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
                    color: accent.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
