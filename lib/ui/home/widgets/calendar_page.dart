import 'dart:math';

import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:aadat/ui/settings/settings_viewmodel.dart';
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
    final urgentIds = vm.urgentHabits
        .map((u) => u.habit.id)
        .whereType<int>()
        .toSet();
    final allHabits = vm.habits
        .where((h) => habitAppliesOnDate(h, _selectedDay))
        .toList();

    final daily = allHabits
        .where((h) => h.recurrence == HabitRecurrence.daily)
        .toList();
    final weekly = allHabits
        .where((h) => h.recurrence == HabitRecurrence.weekly)
        .toList();
    final monthly = allHabits
        .where((h) => h.recurrence == HabitRecurrence.monthly)
        .toList();
    final custom = allHabits
        .where((h) => h.recurrence == HabitRecurrence.custom)
        .toList();

    final widgets = <Widget>[
      Text(
        _formatSelectedHeading(_selectedDay).toUpperCase(),
        style: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: scheme.onSurface,
        ),
      ),
      const SizedBox(height: 12),
    ];

    if (allHabits.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            '// no habits for this date',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    } else {
      Future<void> deleteHabit(Habit h) async {
        final confirmFirst =
            context.read<SettingsViewModel>().confirmBeforeDelete;
        if (confirmFirst) {
          final go = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete habit?'),
              content: Text('Remove "${h.title}" and all its tracking data?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (go != true) return;
        }
        vm.deleteHabit(h);
      }

      void addGroup(String label, List<Habit> group) {
        if (group.isEmpty) return;
        widgets.add(_sectionHeader(label, textTheme, scheme));
        final isPastDay = habitDateOnly(_selectedDay).isBefore(habitDateOnly(DateTime.now()));
        for (final h in group) {
          final completed = vm.isHabitCompletedOn(h, _selectedDay);
          widgets.add(
            _HabitDayTile(
              habit: h,
              completed: completed,
              isMissed: isPastDay && !completed,
              canMarkComplete: !_isFutureDay(_selectedDay),
              onToggle: () => vm.toggleHabitCompletion(h, _selectedDay),
              onDelete: () => deleteHabit(h),
              isUrgent: urgentIds.contains(h.id),
              displayRecurrence: vm.recurrenceForHabitOnDate(h, _selectedDay),
              nextChange: vm.nextChangeAfterDate(h, _selectedDay),
              note: vm.noteForHabit(h, _selectedDay),
              onNoteChanged: (text) => vm.setNoteForHabit(h, _selectedDay, text),
            ),
          );
        }
      }

      addGroup('Daily', daily);
      addGroup('Weekly', weekly);
      addGroup('Monthly', monthly);
      addGroup('Custom', custom);
    }

    widgets.add(const SizedBox(height: 28));
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Calendar'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: scheme.outlineVariant),
        ),
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
            '// select a day to view and log habits',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.3,
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
          const SizedBox(height: 20),
          Divider(height: 1, color: scheme.outlineVariant),
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

Widget _sectionHeader(String label, TextTheme textTheme, ColorScheme scheme) {
  return Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 2),
    child: Row(
      children: [
        Text(
          label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
        ),
      ],
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left, size: 20),
          visualDensity: VisualDensity.compact,
        ),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, size: 20),
          visualDensity: VisualDensity.compact,
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
    final scheme = Theme.of(context).colorScheme;
    final year = month.year;
    final m = month.month;
    final daysInMonth = DateTime(year, m + 1, 0).day;
    final firstWeekday = DateTime(year, m, 1).weekday;
    final leading = weekStartsOnMonday ? firstWeekday - 1 : firstWeekday % 7;
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final labels = _weekdayLabels(weekStartsOnMonday);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
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
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: scheme.onSurfaceVariant,
                              ),
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

  // Darker shades so white text is legible in both light and dark mode.
  static const _colorGreen = Color(0xFF2E7D32); // green 800
  static const _colorAmber = Color(0xFFE65100); // deepOrange 900
  static const _colorRed = Color(0xFFB71C1C);   // red 900

  Color? _cellColor(bool isFuture, int completed, int total) {
    if (isFuture || total == 0) return null;
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
    final scheme = Theme.of(context).colorScheme;

    final cellColor = _cellColor(isFuture, summary.completed, summary.total);
    final isColored = cellColor != null;

    // Text color: white on colored cells; theme-aware on plain cells.
    final textColor = isColored
        ? Colors.white
        : (isFuture
            ? scheme.onSurface.withValues(alpha: 0.3)
            : scheme.onSurface);

    // Background: saturated color when there's data, else theme surface.
    final bgColor = isColored
        ? cellColor
        : (isFuture
            ? scheme.surfaceContainerHighest
            : scheme.surfaceContainer);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isFuture ? null : () => onSelectDay(day),
        borderRadius: BorderRadius.circular(2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: isSelected
                  ? scheme.primary
                  : (isColored ? Colors.transparent : scheme.outlineVariant),
              width: isSelected ? 2 : 1,
            ),
            color: bgColor,
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
    required this.isMissed,
    required this.canMarkComplete,
    required this.onToggle,
    required this.onDelete,
    this.isUrgent = false,
    required this.displayRecurrence,
    this.nextChange,
    this.note,
    required this.onNoteChanged,
  });

  final Habit habit;
  final bool completed;
  final bool isMissed;
  final bool canMarkComplete;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final bool isUrgent;
  final HabitRecurrence displayRecurrence;
  final ({DateTime on, HabitRecurrence to})? nextChange;
  final String? note;
  final Future<void> Function(String) onNoteChanged;

  void _showNoteDialog(BuildContext context) {
    final ctrl = TextEditingController(text: note);
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(habit.title),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Add a note for this day…',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          autofocus: true,
          textInputAction: TextInputAction.newline,
        ),
        actions: [
          if (note != null && note!.isNotEmpty)
            TextButton(
              onPressed: () {
                onNoteChanged('');
                Navigator.of(ctx).pop();
              },
              child: Text(
                'Clear',
                style: TextStyle(color: scheme.error),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onNoteChanged(ctrl.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canTrack = habit.id != null && canMarkComplete;
    final showUrgent = isUrgent && !completed;
    final wasChanged = nextChange != null;
    final hasNote = note != null && note!.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final subtitleParts = [
      if (habit.description.isNotEmpty) habit.description,
      if (habit.category.isNotEmpty) habit.category,
      if (habit.endDate != null) 'until ${_formatShort(habit.endDate!)}',
      if (wasChanged)
        '→ ${nextChange!.to.displayName} on ${_formatShort(nextChange!.on)}',
    ];

    IconData iconData;
    Color iconColor;
    if (showUrgent) {
      iconData = Icons.warning_amber_rounded;
      iconColor = Colors.orange.shade700;
    } else if (wasChanged) {
      iconData = Icons.edit_calendar_rounded;
      iconColor = scheme.onSurfaceVariant;
    } else {
      iconData = completed ? Icons.check_circle_rounded : Icons.circle_outlined;
      iconColor = completed ? const Color(0xFF2E7D32) : scheme.outlineVariant;
    }

    return InkWell(
      onTap: canTrack ? onToggle : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: scheme.outlineVariant, width: 1),
            left: BorderSide(
              color: showUrgent
                  ? Colors.orange.shade700
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        padding: EdgeInsets.only(
          left: showUrgent ? 10 : 0,
          right: 0,
          top: 12,
          bottom: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomPaint(
                    foregroundPainter: isMissed
                        ? _WavyUnderlinePainter(const Color(0xFFB71C1C))
                        : null,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isMissed ? 5 : 0),
                      child: Text(
                        habit.title,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: completed ? TextDecoration.lineThrough : null,
                          decorationColor: scheme.onSurface.withValues(alpha: 0.4),
                          color: completed
                              ? scheme.onSurface.withValues(alpha: 0.4)
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  if (subtitleParts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        subtitleParts.join(' · '),
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (hasNote)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            size: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              note!,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (canMarkComplete)
              IconButton(
                icon: Icon(
                  hasNote ? Icons.edit_note_rounded : Icons.note_add_outlined,
                  color: hasNote ? scheme.primary : scheme.onSurfaceVariant,
                  size: 18,
                ),
                onPressed: () => _showNoteDialog(context),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                tooltip: hasNote ? 'Edit note' : 'Add note',
              ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: scheme.error,
                size: 18,
              ),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _WavyUnderlinePainter extends CustomPainter {
  const _WavyUnderlinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const amplitude = 2.2;
    const wavelength = 6.0;
    final y = size.height - 1.5;

    final path = Path()..moveTo(0, y);
    for (var x = 0.0; x <= size.width; x += 0.5) {
      path.lineTo(x, y + sin((x / wavelength) * 2 * pi) * amplitude);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavyUnderlinePainter old) => old.color != color;
}

String _formatShort(DateTime d) {
  final x = habitDateOnly(d);
  return '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
}
