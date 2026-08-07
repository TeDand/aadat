import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/habit_model.dart';
import '../../../data/services/ai_suggestions.dart';
import '../view_models/home_viewmodel.dart';

class AiSuggestionsSection extends StatefulWidget {
  const AiSuggestionsSection({super.key});

  @override
  State<AiSuggestionsSection> createState() => _AiSuggestionsSectionState();
}

class _AiSuggestionsSectionState extends State<AiSuggestionsSection> {
  final _controller = TextEditingController();
  final _service = AiSuggestionService();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final goal = _controller.text.trim();
    if (goal.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final habits = await _service.suggestHabits(goal);
      if (!mounted) return;
      final homeViewModel = context.read<HomeViewModel>();
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(),
        builder: (ctx) => ChangeNotifierProvider.value(
          value: homeViewModel,
          child: _SuggestionsSheet(habits: habits),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not get suggestions. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_outlined, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              'Tell AI your goals!',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Describe a goal and get a personalised habit plan.',
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            hintText: 'e.g. lose 10kg by December',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimary,
                  ),
                )
              : const Icon(Icons.auto_awesome_outlined, size: 16),
          label: Text(_loading ? 'Thinking...' : 'Suggest habits'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _SuggestionsSheet extends StatefulWidget {
  const _SuggestionsSheet({required this.habits});
  final List<Habit> habits;

  @override
  State<_SuggestionsSheet> createState() => _SuggestionsSheetState();
}

class _SuggestionsSheetState extends State<_SuggestionsSheet> {
  late final Set<int> _selected;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(List.generate(widget.habits.length, (i) => i));
  }

  Future<void> _addSelected() async {
    if (_selected.isEmpty) return;
    setState(() => _adding = true);

    final vm = context.read<HomeViewModel>();
    var added = 0;
    for (final i in _selected) {
      final result = await vm.addHabit(widget.habits[i]);
      if (result == 'habit added!') added++;
    }

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added == 0
              ? 'All habits already exist.'
              : '$added habit${added == 1 ? '' : 's'} added.',
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: const RoundedRectangleBorder(),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
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
                Icon(Icons.auto_awesome_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Suggested habits',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Select the habits you want to add.',
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < widget.habits.length; i++) ...[
              _HabitCheckTile(
                habit: widget.habits[i],
                selected: _selected.contains(i),
                onChanged: (v) => setState(() {
                  if (v) {
                    _selected.add(i);
                  } else {
                    _selected.remove(i);
                  }
                }),
                scheme: scheme,
                textTheme: textTheme,
              ),
              if (i < widget.habits.length - 1)
                Divider(height: 1, color: scheme.outlineVariant),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: (_selected.isEmpty || _adding) ? null : _addSelected,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _adding
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : Text(
                      _selected.isEmpty
                          ? 'Select at least one habit'
                          : 'Add ${_selected.length} habit${_selected.length == 1 ? '' : 's'}',
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _HabitCheckTile extends StatelessWidget {
  const _HabitCheckTile({
    required this.habit,
    required this.selected,
    required this.onChanged,
    required this.scheme,
    required this.textTheme,
  });

  final Habit habit;
  final bool selected;
  final void Function(bool) onChanged;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: selected,
              onChanged: (v) => onChanged(v ?? false),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          habit.title,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                  if (habit.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      habit.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (habit.category.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      habit.category,
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
