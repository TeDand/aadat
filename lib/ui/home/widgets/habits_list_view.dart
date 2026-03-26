import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:aadat/ui/settings/settings_dialog.dart';
import 'package:aadat/ui/settings/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Opens the same editor as habit details, for creating a habit with a suggested title.
void showAddHabitSheet(BuildContext context) {
  final homeViewModel = context.read<HomeViewModel>();
  final settings = context.read<SettingsViewModel>();
  final title = suggestNextNewHabitTitle(homeViewModel.habits);
  final draft = Habit(
    title: title,
    description: '',
    recurrence: settings.defaultHabitRecurrence,
  );
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return _HabitEditorSheet(
        habit: draft,
        isNew: true,
        onCommit: (updated) => homeViewModel.addHabit(updated),
      );
    },
  );
}

enum HabitsGroupBy {
  recurrence,
  category,
}

class HabitsListView extends StatefulWidget {
  const HabitsListView({super.key});

  @override
  State<HabitsListView> createState() => _HabitsListViewState();
}

class _HabitsListViewState extends State<HabitsListView> {
  HabitsGroupBy _groupBy = HabitsGroupBy.recurrence;

  void _showHabitEditor(BuildContext context, Habit habit) {
    final homeViewModel = context.read<HomeViewModel>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return _HabitEditorSheet(
          habit: habit,
          isNew: false,
          onCommit: (updated) => homeViewModel.updateHabit(updated),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HomeViewModel>().habits;
    final theme = Theme.of(context);
    final tiles = habits.isEmpty
        ? <Widget>[]
        : _buildTiles(context, habits, theme);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  'Group by',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<HabitsGroupBy>(
                  value: _groupBy,
                  onChanged: (v) {
                    if (v != null) setState(() => _groupBy = v);
                  },
                  items: const [
                    DropdownMenuItem(
                      value: HabitsGroupBy.recurrence,
                      child: Text('Recurrence'),
                    ),
                    DropdownMenuItem(
                      value: HabitsGroupBy.category,
                      child: Text('Category'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (habits.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No habits yet.')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate(tiles),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildTiles(
    BuildContext context,
    List<Habit> habits,
    ThemeData theme,
  ) {
    final sorted = [...habits]
      ..sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );

    switch (_groupBy) {
      case HabitsGroupBy.recurrence:
        return _sectionsByRecurrence(context, sorted, theme);
      case HabitsGroupBy.category:
        return _sectionsByCategory(context, sorted, theme);
    }
  }

  List<Widget> _sectionsByRecurrence(
    BuildContext context,
    List<Habit> habits,
    ThemeData theme,
  ) {
    const order = HabitRecurrence.values;
    final out = <Widget>[];
    var first = true;
    for (final rec in order) {
      final section = habits.where((h) => h.recurrence == rec).toList();
      if (section.isEmpty) continue;
      if (!first) {
        out.add(const SizedBox(height: 16));
      }
      first = false;
      out.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            rec.displayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
      for (final h in section) {
        out.add(_habitTile(context, h, theme));
      }
    }
    return out;
  }

  List<Widget> _sectionsByCategory(
    BuildContext context,
    List<Habit> habits,
    ThemeData theme,
  ) {
    final map = <String, List<Habit>>{};
    for (final h in habits) {
      final raw = h.category.trim();
      final key =
          raw.isEmpty ? '___uncategorized___' : raw.toLowerCase();
      map.putIfAbsent(key, () => []).add(h);
    }
    final keys = map.keys.toList()
      ..sort((a, b) {
        if (a == '___uncategorized___') return 1;
        if (b == '___uncategorized___') return -1;
        return a.compareTo(b);
      });

    final out = <Widget>[];
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) out.add(const SizedBox(height: 16));
      final key = keys[i];
      final list = map[key]!;
      final header = key == '___uncategorized___'
          ? 'Uncategorized'
          : (list.first.category.trim().isEmpty
              ? 'Uncategorized'
              : list.first.category.trim());
      out.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            header,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
      for (final h in list) {
        out.add(_habitTile(context, h, theme));
      }
    }
    return out;
  }

  Widget _habitTile(BuildContext context, Habit habit, ThemeData theme) {
    final scheme = theme.colorScheme;

    Future<void> onDelete() async {
      final settings = context.read<SettingsViewModel>();
      if (settings.confirmBeforeDelete) {
        final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete habit?'),
            content: Text('Remove "${habit.title}" and all its tracking data?'),
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
      if (context.mounted) context.read<HomeViewModel>().deleteHabit(habit);
    }

    return InkWell(
      onTap: () => _showHabitEditor(context, habit),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: scheme.outlineVariant, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              _iconForRecurrence(habit.recurrence),
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    habit.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (habit.description.isNotEmpty)
                    Text(
                      habit.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
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

  IconData _iconForRecurrence(HabitRecurrence r) {
    switch (r) {
      case HabitRecurrence.daily:
        return Icons.today;
      case HabitRecurrence.weekly:
        return Icons.date_range;
      case HabitRecurrence.monthly:
        return Icons.calendar_month;
      case HabitRecurrence.custom:
        return Icons.tune;
    }
  }
}

class _HabitEditorSheet extends StatefulWidget {
  const _HabitEditorSheet({
    required this.habit,
    required this.isNew,
    required this.onCommit,
  });

  final Habit habit;
  final bool isNew;
  final Future<String> Function(Habit updated) onCommit;

  @override
  State<_HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends State<_HabitEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final FocusNode _categoryFocus;
  late HabitRecurrence _recurrence;
  late Set<int> _customDays; // 1=Mon … 7=Sun
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit.title);
    _descriptionController = TextEditingController(
      text: widget.habit.description,
    );
    _categoryController = TextEditingController(text: widget.habit.category);
    _categoryFocus = FocusNode();
    _recurrence = widget.habit.recurrence;
    _customDays = Set<int>.from(widget.habit.customDays);
    // New habits default to starting today; existing habits keep their stored date.
    _startDate = widget.habit.startDate != null
        ? habitDateOnly(widget.habit.startDate!)
        : (widget.isNew ? habitDateOnly(DateTime.now()) : null);
    _endDate = widget.habit.endDate != null
        ? habitDateOnly(widget.habit.endDate!)
        : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _categoryFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = context.watch<HomeViewModel>().categorySuggestions;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isNew ? 'Add habit' : 'Edit habit',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            RawAutocomplete<String>(
              textEditingController: _categoryController,
              focusNode: _categoryFocus,
              optionsBuilder: (textEditingValue) {
                final q = textEditingValue.text.toLowerCase();
                if (textEditingValue.text.isEmpty) return suggestions;
                return suggestions
                    .where((s) => s.toLowerCase().contains(q))
                    .take(12);
              },
              displayStringForOption: (s) => s,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g. Health, Work',
                    border: OutlineInputBorder(),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final opt = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            title: Text(opt),
                            onTap: () => onSelected(opt),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Recurrence',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<HabitRecurrence>(
                  isExpanded: true,
                  value: _recurrence,
                  items: HabitRecurrence.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _recurrence = v);
                  },
                ),
              ),
            ),
            if (_recurrence == HabitRecurrence.custom) ...[
              const SizedBox(height: 12),
              _DayPicker(
                selectedDays: _customDays,
                onChanged: (days) => setState(() => _customDays = days),
              ),
            ],
            const SizedBox(height: 8),
            _DatePickerRow(
              label: 'Start date',
              date: _startDate,
              onClear: () => setState(() => _startDate = null),
              onSet: (d) => setState(() => _startDate = d),
            ),
            _DatePickerRow(
              label: 'End date',
              hint: 'Optional — habit stops appearing after this day',
              date: _endDate,
              onClear: () => setState(() => _endDate = null),
              onSet: (d) => setState(() => _endDate = d),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Auto-classify custom days:
                    // 7 days → daily, 1 day → weekly, 2–6 → custom, 0 → error.
                    var recurrence = _recurrence;
                    List<int> customDays = [];
                    if (_recurrence == HabitRecurrence.custom) {
                      if (_customDays.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Select at least one day.'),
                          ),
                        );
                        return;
                      }
                      if (_customDays.length == 7) {
                        recurrence = HabitRecurrence.daily;
                      } else if (_customDays.length == 1) {
                        recurrence = HabitRecurrence.weekly;
                      } else {
                        customDays = _customDays.toList()..sort();
                      }
                    }
                    final updated = widget.habit.copy(
                      title: _titleController.text,
                      description: _descriptionController.text,
                      category: _categoryController.text.trim(),
                      recurrence: recurrence,
                      customDays: customDays,
                      startDate: _startDate,
                      clearStartDate: _startDate == null,
                      endDate: _endDate,
                      clearEndDate: _endDate == null,
                    );
                    final r = await widget.onCommit(updated);
                    if (!context.mounted) return;
                    if (r == 'habit added!' || r == 'habit updated!') {
                      Navigator.of(context).pop();
                    } else if (r == 'habit already exists!') {
                      await showDuplicateHabitNameDialog(context);
                    }
                  },
                  child: Text(widget.isNew ? 'Add' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact day-of-week picker used when recurrence is set to Custom.
/// [selectedDays] uses Dart's [DateTime.weekday] values: 1=Mon … 7=Sun.
class _DayPicker extends StatelessWidget {
  const _DayPicker({required this.selectedDays, required this.onChanged});

  final Set<int> selectedDays;
  final void Function(Set<int>) onChanged;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _days   = [1,   2,   3,   4,   5,   6,   7];

  String get _hint {
    if (selectedDays.length == 7) return '→ All days selected, will save as Daily';
    if (selectedDays.length == 1) return '→ One day selected, will save as Weekly';
    if (selectedDays.isEmpty) return 'Select at least one day';
    return '${selectedDays.length} days/week';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Days',
          style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day = _days[i];
            final selected = selectedDays.contains(day);
            return GestureDetector(
              onTap: () {
                final next = Set<int>.from(selectedDays);
                if (selected) {
                  next.remove(day);
                } else {
                  next.add(day);
                }
                onChanged(next);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? scheme.primary : scheme.surfaceContainerHighest,
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[i],
                  style: t.labelMedium?.copyWith(
                    color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          _hint,
          style: t.bodySmall?.copyWith(
            color: selectedDays.isEmpty ? scheme.error : scheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.label,
    this.hint,
    required this.date,
    required this.onClear,
    required this.onSet,
  });

  final String label;
  final String? hint;
  final DateTime? date;
  final VoidCallback onClear;
  final void Function(DateTime) onSet;

  String get _subtitle {
    if (date == null) return hint ?? 'Not set';
    return '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(_subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (date != null)
            TextButton(
              onPressed: onClear,
              child: const Text('Clear'),
            ),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) onSet(habitDateOnly(picked));
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}
