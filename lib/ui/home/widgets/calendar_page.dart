import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Month grid + selected day: mark each habit done for that day.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = habitDateOnly(now);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final habits = vm.habits
        .where((h) => habitAppliesOnDate(h, _selectedDay))
        .toList();

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Habit calendar'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Week starts on Monday'),
              subtitle: Text(
                vm.weekStartsOnMonday
                    ? 'Calendar columns: Mon → Sun (ISO-style weeks)'
                    : 'Calendar columns: Sun → Sat',
              ),
              value: vm.weekStartsOnMonday,
              onChanged: (v) => vm.setWeekStartsOnMonday(v),
            ),
          ),
          const SizedBox(height: 12),
          _MonthHeader(
            month: _visibleMonth,
            onPrev: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          const SizedBox(height: 12),
          _MonthGrid(
            month: _visibleMonth,
            selectedDay: _selectedDay,
            summaryForDay: vm.completionSummaryForDay,
            onSelectDay: _selectDay,
            today: habitDateOnly(DateTime.now()),
            weekStartsOnMonday: vm.weekStartsOnMonday,
          ),
          const SizedBox(height: 24),
          Text(
            _formatSelectedHeading(_selectedDay),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (habits.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Add habits on the Home tab, or pick a day on/after each habit’s start date.',
                ),
              ),
            )
          else
            ...habits.map((h) => _HabitDayTile(
                  habit: h,
                  completed: vm.isHabitCompletedOn(h, _selectedDay),
                  canMarkComplete: !_isFutureDay(_selectedDay),
                  onToggle: () => vm.toggleHabitCompletion(h, _selectedDay),
                )),
        ],
      ),
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
            if (startLine != null) startLine,
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
