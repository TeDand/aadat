import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Tabs for daily (day grid), weekly (week list), monthly (year of months).
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;
  /// Year shown in the Monthly tab’s twelve-month grid (independent of month nav).
  late int _yearForMonthlyTab;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = habitDateOnly(now);
    _yearForMonthlyTab = now.year;
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _shiftYearForMonthlyTab(int delta) {
    setState(() {
      var y = _yearForMonthlyTab + delta;
      if (y < 1970) y = 1970;
      if (y > 2100) y = 2100;
      _yearForMonthlyTab = y;
    });
  }

  void _selectDay(DateTime day) {
    final d = habitDateOnly(day);
    if (d.isAfter(habitDateOnly(DateTime.now()))) return;
    setState(() {
      _selectedDay = d;
      if (day.year != _visibleMonth.year || day.month != _visibleMonth.month) {
        _visibleMonth = DateTime(day.year, day.month);
      }
    });
  }

  void _selectWeek(DateTime weekStart) {
    final today = habitDateOnly(DateTime.now());
    final ws = habitDateOnly(weekStart);
    if (ws.isAfter(today)) return;
    final we = ws.add(const Duration(days: 6));
    final pick = we.isAfter(today) ? today : ws;
    setState(() {
      _selectedDay = pick;
      _visibleMonth = DateTime(pick.year, pick.month);
    });
  }

  void _selectMonthInYear(int year, int month) {
    final today = habitDateOnly(DateTime.now());
    final first = DateTime(year, month);
    if (first.isAfter(today)) return;
    final pick =
        (year == today.year && month == today.month) ? today : first;
    setState(() {
      _selectedDay = pick;
      _visibleMonth = DateTime(year, month);
      _yearForMonthlyTab = year;
    });
  }

  List<Widget> _habitBlock(
    BuildContext context,
    HomeViewModel vm,
    ColorScheme scheme, {
    required HabitRecurrence recurrence,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final habits = vm.habits
        .where(
          (h) => h.recurrence == recurrence && habitAppliesOnDate(h, _selectedDay),
        )
        .toList();

    return [
      Text(
        _formatSelectedHeading(_selectedDay),
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      if (habits.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No ${recurrence.displayName.toLowerCase()} habits for this date. Add one on Home or choose a day on/after each habit’s start date.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        )
      else
        ...habits.map(
          (h) => _HabitDayTile(
            habit: h,
            completed: vm.isHabitCompletedOn(h, _selectedDay),
            canMarkComplete: !_isFutureDay(_selectedDay),
            onToggle: () => vm.toggleHabitCompletion(h, _selectedDay),
          ),
        ),
      const SizedBox(height: 28),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('Habit calendar'),
          backgroundColor: scheme.primary,
          foregroundColor: onPrimary,
          bottom: TabBar(
            indicatorColor: onPrimary,
            labelColor: onPrimary,
            unselectedLabelColor: onPrimary.withValues(alpha: 0.65),
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
            _calendarDailyTab(context, vm, scheme),
            _calendarWeeklyTab(context, vm, scheme),
            _calendarMonthlyTab(context, vm, scheme),
          ],
        ),
      ),
    );
  }

  Widget _calendarDailyTab(
    BuildContext context,
    HomeViewModel vm,
    ColorScheme scheme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _MonthHeader(
          month: _visibleMonth,
          onPrev: () => _shiftMonth(-1),
          onNext: () => _shiftMonth(1),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap a day to select it. Future days are disabled. Week layout is in Settings.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        _MonthGrid(
          month: _visibleMonth,
          selectedDay: _selectedDay,
          summaryForDay: (d) => vm.completionSummaryForDayForRecurrence(
            d,
            HabitRecurrence.daily,
          ),
          onSelectDay: _selectDay,
          today: habitDateOnly(DateTime.now()),
          weekStartsOnMonday: vm.weekStartsOnMonday,
        ),
        const SizedBox(height: 16),
        ..._habitBlock(context, vm, scheme, recurrence: HabitRecurrence.daily),
      ],
    );
  }

  Widget _calendarWeeklyTab(
    BuildContext context,
    HomeViewModel vm,
    ColorScheme scheme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _MonthHeader(
          month: _visibleMonth,
          onPrev: () => _shiftMonth(-1),
          onNext: () => _shiftMonth(1),
        ),
        const SizedBox(height: 8),
        Text(
          'Weeks that overlap this month. Tap a row to select that week. Week boundaries are in Settings.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        _WeeksOfMonthPanel(
          month: _visibleMonth,
          selectedDay: _selectedDay,
          today: habitDateOnly(DateTime.now()),
          weekStartsOnMonday: vm.weekStartsOnMonday,
          summaryForWeek: vm.weeklySummaryForWeekContaining,
          onSelectWeek: _selectWeek,
        ),
        const SizedBox(height: 16),
        ..._habitBlock(context, vm, scheme, recurrence: HabitRecurrence.weekly),
      ],
    );
  }

  Widget _calendarMonthlyTab(
    BuildContext context,
    HomeViewModel vm,
    ColorScheme scheme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _YearHeader(
          year: _yearForMonthlyTab,
          onPrev: _yearForMonthlyTab > 1970
              ? () => _shiftYearForMonthlyTab(-1)
              : null,
          onNext: _yearForMonthlyTab < 2100
              ? () => _shiftYearForMonthlyTab(1)
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          'All twelve months of $_yearForMonthlyTab. Use the arrows to change year. Tap a month to select.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        _MonthsOfYearGrid(
          year: _yearForMonthlyTab,
          selectedDay: _selectedDay,
          today: habitDateOnly(DateTime.now()),
          summaryForMonth: vm.monthlySummaryForMonth,
          onSelectMonth: _selectMonthInYear,
        ),
        const SizedBox(height: 16),
        ..._habitBlock(
          context,
          vm,
          scheme,
          recurrence: HabitRecurrence.monthly,
        ),
      ],
    );
  }
}

bool _isFutureDay(DateTime d) =>
    habitDateOnly(d).isAfter(habitDateOnly(DateTime.now()));

String _formatSelectedHeading(DateTime d) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

/// Week starts from the week of the 1st through the week of the last day of [month].
List<DateTime> _weekStartsOverlappingMonth(
  DateTime month, {
  required bool weekStartsOnMonday,
}) {
  final y = month.year;
  final m = month.month;
  final lastDayNum = DateTime(y, m + 1, 0).day;
  final first = DateTime(y, m, 1);
  final last = DateTime(y, m, lastDayNum);
  final startWs = weekStartForDate(
    first,
    weekStartsOnMonday: weekStartsOnMonday,
  );
  final endWs = weekStartForDate(
    last,
    weekStartsOnMonday: weekStartsOnMonday,
  );
  final out = <DateTime>[];
  for (
    var w = startWs;
    !w.isAfter(endWs);
    w = w.add(const Duration(days: 7))
  ) {
    out.add(w);
  }
  return out;
}

String _formatWeekRange(DateTime weekStart, DateTime weekEnd) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final ws = habitDateOnly(weekStart);
  final we = habitDateOnly(weekEnd);
  if (ws.year == we.year && ws.month == we.month) {
    return '${months[ws.month - 1]} ${ws.day}–${we.day}';
  }
  if (ws.year == we.year) {
    return '${months[ws.month - 1]} ${ws.day} – ${months[we.month - 1]} ${we.day}';
  }
  return '${months[ws.month - 1]} ${ws.day}, ${ws.year} – '
      '${months[we.month - 1]} ${we.day}, ${we.year}';
}

class _WeeksOfMonthPanel extends StatelessWidget {
  const _WeeksOfMonthPanel({
    required this.month,
    required this.selectedDay,
    required this.today,
    required this.weekStartsOnMonday,
    required this.summaryForWeek,
    required this.onSelectWeek,
  });

  final DateTime month;
  final DateTime selectedDay;
  final DateTime today;
  final bool weekStartsOnMonday;
  final ({int completed, int total}) Function(DateTime date) summaryForWeek;
  final void Function(DateTime weekStart) onSelectWeek;

  @override
  Widget build(BuildContext context) {
    final weeks = _weekStartsOverlappingMonth(
      month,
      weekStartsOnMonday: weekStartsOnMonday,
    );
    final selectedWs = weekStartForDate(
      selectedDay,
      weekStartsOnMonday: weekStartsOnMonday,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (var i = 0; i < weeks.length; i++) ...[
              _WeekOfMonthRow(
                weekStart: weeks[i],
                weekEnd: weeks[i].add(const Duration(days: 6)),
                today: today,
                summary: summaryForWeek(weeks[i]),
                isSelected:
                    habitDateOnly(weeks[i]) == habitDateOnly(selectedWs),
                onTap: () => onSelectWeek(weeks[i]),
              ),
              if (i < weeks.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeekOfMonthRow extends StatelessWidget {
  const _WeekOfMonthRow({
    required this.weekStart,
    required this.weekEnd,
    required this.today,
    required this.summary,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final DateTime today;
  final ({int completed, int total}) summary;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final ws = habitDateOnly(weekStart);
    final entirelyFuture = ws.isAfter(today);
    final hasHabits = summary.total > 0;
    final allDone = hasHabits && summary.completed == summary.total;
    final someDone = hasHabits && summary.completed > 0 && !allDone;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: entirelyFuture ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? scheme.primary : Colors.black12,
              width: isSelected ? 2 : 1,
            ),
            color: entirelyFuture
                ? Colors.grey.shade200
                : allDone
                    ? Colors.green.shade100
                    : someDone
                        ? Colors.amber.shade100
                        : scheme.surfaceContainerLow,
          ),
          child: Row(
            children: [
              Icon(
                Icons.view_week_rounded,
                size: 22,
                color: entirelyFuture ? Colors.black38 : scheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Week',
                      style: t.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatWeekRange(weekStart, weekEnd),
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: entirelyFuture ? Colors.black38 : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasHabits && !entirelyFuture)
                Text(
                  '${summary.completed}/${summary.total}',
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthsOfYearGrid extends StatelessWidget {
  const _MonthsOfYearGrid({
    required this.year,
    required this.selectedDay,
    required this.today,
    required this.summaryForMonth,
    required this.onSelectMonth,
  });

  final int year;
  final DateTime selectedDay;
  final DateTime today;
  final ({int completed, int total}) Function(int year, int month) summaryForMonth;
  final void Function(int year, int month) onSelectMonth;

  static const _abbr = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.45,
          children: [
            for (var month = 1; month <= 12; month++)
              _MonthOfYearCell(
                label: _abbr[month - 1],
                year: year,
                month: month,
                today: today,
                selectedDay: selectedDay,
                summary: summaryForMonth(year, month),
                scheme: scheme,
                textTheme: t,
                onTap: () => onSelectMonth(year, month),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthOfYearCell extends StatelessWidget {
  const _MonthOfYearCell({
    required this.label,
    required this.year,
    required this.month,
    required this.today,
    required this.selectedDay,
    required this.summary,
    required this.scheme,
    required this.textTheme,
    required this.onTap,
  });

  final String label;
  final int year;
  final int month;
  final DateTime today;
  final DateTime selectedDay;
  final ({int completed, int total}) summary;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(year, month);
    final notYetStarted = first.isAfter(today);
    final isSelected =
        selectedDay.year == year && selectedDay.month == month;
    final hasHabits = summary.total > 0;
    final allDone = hasHabits && summary.completed == summary.total;
    final someDone = hasHabits && summary.completed > 0 && !allDone;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: notYetStarted ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? scheme.primary : Colors.black12,
              width: isSelected ? 2 : 1,
            ),
            color: notYetStarted
                ? Colors.grey.shade200
                : allDone
                    ? Colors.green.shade100
                    : someDone
                        ? Colors.amber.shade100
                        : scheme.surfaceContainerLow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: notYetStarted ? Colors.black38 : null,
                ),
              ),
              if (hasHabits && !notYetStarted)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${summary.completed}/${summary.total}',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
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

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final label = '${names[month.month - 1]} ${month.year}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _YearHeader extends StatelessWidget {
  const _YearHeader({
    required this.year,
    required this.onPrev,
    required this.onNext,
  });

  final int year;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        const SizedBox(width: 8),
        Text(
          '$year',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

List<String> _weekdayLabels(bool weekStartsOnMonday) {
  if (weekStartsOnMonday) {
    return ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  }
  return ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDay,
    required this.summaryForDay,
    required this.onSelectDay,
    required this.today,
    required this.weekStartsOnMonday,
  });

  final DateTime month;
  final DateTime selectedDay;
  final ({int completed, int total}) Function(DateTime date) summaryForDay;
  final void Function(DateTime day) onSelectDay;
  final DateTime today;
  final bool weekStartsOnMonday;

  @override
  Widget build(BuildContext context) {
    final year = month.year;
    final m = month.month;
    final daysInMonth = DateTime(year, m + 1, 0).day;
    final firstWeekday = DateTime(year, m, 1).weekday;
    final leading = weekStartsOnMonday
        ? firstWeekday - 1
        : firstWeekday % 7;
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final labels = _weekdayLabels(weekStartsOnMonday);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: labels
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            for (var row = 0; row < totalCells / 7; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: _DayCell(
                          index: row * 7 + col,
                          leading: leading,
                          daysInMonth: daysInMonth,
                          year: year,
                          month: m,
                          selectedDay: selectedDay,
                          summaryForDay: summaryForDay,
                          onSelectDay: onSelectDay,
                          today: today,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.index,
    required this.leading,
    required this.daysInMonth,
    required this.year,
    required this.month,
    required this.selectedDay,
    required this.summaryForDay,
    required this.onSelectDay,
    required this.today,
  });

  final int index;
  final int leading;
  final int daysInMonth;
  final int year;
  final int month;
  final DateTime selectedDay;
  final ({int completed, int total}) Function(DateTime date) summaryForDay;
  final void Function(DateTime day) onSelectDay;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final dayNum = index - leading + 1;
    if (dayNum < 1 || dayNum > daysInMonth) {
      return const SizedBox(height: 52);
    }
    final day = DateTime(year, month, dayNum);
    final dayOnly = habitDateOnly(day);
    final isFuture = dayOnly.isAfter(today);
    final isSelected =
        day.year == selectedDay.year &&
        day.month == selectedDay.month &&
        day.day == selectedDay.day;
    final summary = summaryForDay(day);
    final hasHabits = summary.total > 0;
    final allDone = hasHabits && summary.completed == summary.total;
    final someDone = hasHabits && summary.completed > 0 && !allDone;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isFuture ? null : () => onSelectDay(day),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black12,
              width: isSelected ? 2 : 1,
            ),
            color: isFuture
                ? Colors.grey.shade200
                : allDone
                    ? Colors.green.shade100
                    : someDone
                        ? Colors.amber.shade100
                        : Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$dayNum',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isFuture ? Colors.black38 : null,
                    ),
              ),
              if (hasHabits && !isFuture)
                Text(
                  '${summary.completed}/${summary.total}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.black87,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitDayTile extends StatelessWidget {
  const _HabitDayTile({
    required this.habit,
    required this.completed,
    required this.canMarkComplete,
    required this.onToggle,
  });

  final Habit habit;
  final bool completed;
  final bool canMarkComplete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final canTrack = habit.id != null && canMarkComplete;
    final startLine = habit.startDate != null
        ? 'Starts ${_formatShort(habit.startDate!)}'
        : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: canTrack ? completed : false,
        onChanged: canTrack ? (_) => onToggle() : null,
        title: Text(habit.title),
        subtitle: Text(
          [
            if (habit.description.isNotEmpty) habit.description,
            '${habit.recurrence.displayName}'
                '${habit.category.isNotEmpty ? ' · ${habit.category}' : ''}',
            ?startLine,
          ].join('\n'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        secondary: Icon(
          completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: completed ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}

String _formatShort(DateTime d) {
  final x = habitDateOnly(d);
  return '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
}
