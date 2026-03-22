import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  List<Widget> _habitsForDay(
    BuildContext context,
    HomeViewModel vm,
    ColorScheme scheme,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final urgentIds =
        vm.urgentHabits.map((u) => u.habit.id).whereType<int>().toSet();
    final allHabits =
        vm.habits.where((h) => habitAppliesOnDate(h, _selectedDay)).toList();

    final daily =
        allHabits.where((h) => h.recurrence == HabitRecurrence.daily).toList();
    final weekly =
        allHabits.where((h) => h.recurrence == HabitRecurrence.weekly).toList();
    final monthly = allHabits
        .where((h) => h.recurrence == HabitRecurrence.monthly)
        .toList();

    final widgets = <Widget>[
      Text(
        _formatSelectedHeading(_selectedDay),
        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
    ];

    if (allHabits.isEmpty) {
      widgets.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No habits for this date. Add one on Home or choose a day on/after each habit\'s start date.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    } else {
      if (daily.isNotEmpty) {
        widgets.add(_sectionHeader('Daily', textTheme, scheme));
        widgets.addAll(
          daily.map(
            (h) => _HabitDayTile(
              habit: h,
              completed: vm.isHabitCompletedOn(h, _selectedDay),
              canMarkComplete: !_isFutureDay(_selectedDay),
              onToggle: () => vm.toggleHabitCompletion(h, _selectedDay),
              isUrgent: urgentIds.contains(h.id),
            ),
          ),
        );
      }
      if (weekly.isNotEmpty) {
        widgets.add(_sectionHeader('Weekly', textTheme, scheme));
        widgets.addAll(
          weekly.map(
            (h) => _HabitDayTile(
              habit: h,
              completed: vm.isHabitCompletedOn(h, _selectedDay),
              canMarkComplete: !_isFutureDay(_selectedDay),
              onToggle: () => vm.toggleHabitCompletion(h, _selectedDay),
              isUrgent: urgentIds.contains(h.id),
            ),
          ),
        );
      }
      if (monthly.isNotEmpty) {
        widgets.add(_sectionHeader('Monthly', textTheme, scheme));
        widgets.addAll(
          monthly.map(
            (h) => _HabitDayTile(
              habit: h,
              completed: vm.isHabitCompletedOn(h, _selectedDay),
              canMarkComplete: !_isFutureDay(_selectedDay),
              onToggle: () => vm.toggleHabitCompletion(h, _selectedDay),
              isUrgent: urgentIds.contains(h.id),
            ),
          ),
        );
      }
    }

    widgets.add(const SizedBox(height: 28));
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _MonthHeader(
            month: _visibleMonth,
            onPrev: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a day to see and log your habits. Future days are disabled.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _MonthGrid(
            month: _visibleMonth,
            selectedDay: _selectedDay,
            summaryForDay: vm.completionSummaryForDay,
            onSelectDay: _selectDay,
            today: habitDateOnly(DateTime.now()),
            weekStartsOnMonday: vm.weekStartsOnMonday,
          ),
          const SizedBox(height: 16),
          ..._habitsForDay(context, vm, scheme),
        ],
      ),
    );
  }
}

bool _isFutureDay(DateTime d) =>
    habitDateOnly(d).isAfter(habitDateOnly(DateTime.now()));

String _formatSelectedHeading(DateTime d) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

Widget _sectionHeader(
  String label,
  TextTheme textTheme,
  ColorScheme scheme,
) {
  return Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Text(
      label,
      style: textTheme.labelLarge?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  );
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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
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
  if (weekStartsOnMonday) return ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
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
    final leading = weekStartsOnMonday ? firstWeekday - 1 : firstWeekday % 7;
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
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
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

  static const _colorGreen = Color(0xFF43A047);   // green 600
  static const _colorAmber = Color(0xFFFB8C00);   // orange 600
  static const _colorRed = Color(0xFFE53935);     // red 600

  Color _cellColor(bool isFuture, int completed, int total) {
    if (isFuture || total == 0) return Colors.transparent;
    final frac = completed / total;
    if (frac >= 1.0) return _colorGreen;
    if (frac >= 0.5) return _colorAmber;
    return _colorRed;
  }

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
    final cellColor = _cellColor(isFuture, summary.completed, summary.total);
    final isColored = cellColor != Colors.transparent;
    final textColor = isColored ? Colors.white : (isFuture ? Colors.black26 : null);

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
                  : (isColored ? Colors.transparent : Colors.black12),
              width: isSelected ? 2 : 1,
            ),
            color: isColored ? cellColor : (isFuture ? Colors.grey.shade100 : Colors.white),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$dayNum',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
              ),
              if (summary.total > 0 && !isFuture)
                Text(
                  '${summary.completed}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
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
    this.isUrgent = false,
  });

  final Habit habit;
  final bool completed;
  final bool canMarkComplete;
  final VoidCallback onToggle;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final canTrack = habit.id != null && canMarkComplete;
    final showUrgent = isUrgent && !completed;
    final startLine = habit.startDate != null
        ? 'Starts ${_formatShort(habit.startDate!)}'
        : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: showUrgent ? Colors.orange.shade50 : null,
      shape: showUrgent
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.orange.shade300, width: 1.5),
            )
          : null,
      child: CheckboxListTile(
        value: canTrack ? completed : false,
        onChanged: canTrack ? (_) => onToggle() : null,
        title: Text(habit.title),
        subtitle: Text(
          [
            if (habit.description.isNotEmpty) habit.description,
            if (habit.category.isNotEmpty) habit.category,
            ?startLine,
          ].join('\n'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        secondary: showUrgent
            ? Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700)
            : Icon(
                completed
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
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
