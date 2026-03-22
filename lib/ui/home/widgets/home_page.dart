import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:aadat/ui/settings/settings_dialog.dart';
import 'package:aadat/ui/settings/settings_viewmodel.dart';
import 'habits_page.dart';
import 'package:aadat/data/repositories/habit_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final _titleFocus = FocusNode();
  final _descFocus = FocusNode();
  final _categoryFocus = FocusNode();
  HabitRecurrence _recurrence = HabitRecurrence.daily;
  DateTime? _startDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _titleFocus.dispose();
    _descFocus.dispose();
    _categoryFocus.dispose();
    super.dispose();
  }

  Future<void> _addHabit(HomeViewModel viewModel) async {
    if (_titleController.text.trim().isEmpty) return;
    final newHabit = Habit(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _categoryController.text.trim(),
      recurrence: _recurrence,
      startDate: _startDate,
    );
    final r = await viewModel.addHabit(newHabit);
    if (!mounted) return;
    if (r == 'habit already exists!') {
      await showDuplicateHabitNameDialog(context);
      return;
    }
    if (r != 'habit added!') return;
    _titleController.clear();
    _descController.clear();
    _categoryController.clear();
    setState(() {
      _recurrence = HabitRecurrence.daily;
      _startDate = null;
    });
  }

  Future<void> _onDeleteHabit(Habit habit, HomeViewModel viewModel) async {
    final confirm = context.read<SettingsViewModel>().confirmBeforeDelete;
    if (confirm) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete habit?'),
          content: Text('Remove “${habit.title}” and its tracking data?'),
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
      if (go != true || !mounted) return;
    }
    if (!mounted) return;
    viewModel.deleteHabit(habit);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final categorySuggestions = viewModel.categorySuggestions;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: _AadatWordmark(foreground: scheme.onPrimary),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              focusNode: _titleFocus,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: "Habit title",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _descFocus.requestFocus(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              focusNode: _descFocus,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onSubmitted: (_) => _categoryFocus.requestFocus(),
            ),
            const SizedBox(height: 12),
            RawAutocomplete<String>(
              textEditingController: _categoryController,
              focusNode: _categoryFocus,
              optionsBuilder: (textEditingValue) {
                final q = textEditingValue.text.toLowerCase();
                if (textEditingValue.text.isEmpty) return categorySuggestions;
                return categorySuggestions
                    .where((s) => s.toLowerCase().contains(q))
                    .take(12);
              },
              displayStringForOption: (s) => s,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g. Health, Work (optional)',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) {},
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text(
                _startDate == null
                    ? 'Optional — habit applies from this day onward'
                    : '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_startDate != null)
                    TextButton(
                      onPressed: () => setState(() => _startDate = null),
                      child: const Text('Clear'),
                    ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _startDate = habitDateOnly(picked));
                      }
                    },
                    child: const Text('Set'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _addHabit(viewModel),
              child: const Text('Add Habit'),
            ),
            const SizedBox(height: 24),
            Text(
              'Your habits',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: viewModel.habits.length,
                itemBuilder: (context, index) {
                  final habit = viewModel.habits[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(habit.title),
                      subtitle: Text(
                        [
                          if (habit.description.isNotEmpty) habit.description,
                          '${habit.recurrence.displayName}'
                              '${habit.category.isNotEmpty ? ' · ${habit.category}' : ''}',
                          if (habit.startDate != null)
                            'Starts ${habit.startDate!.year}-${habit.startDate!.month.toString().padLeft(2, '0')}-${habit.startDate!.day.toString().padLeft(2, '0')}',
                        ].join('\n'),
                      ),
                      isThreeLine: habit.description.isNotEmpty ||
                          habit.startDate != null,
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                        onPressed: () => _onDeleteHabit(habit, viewModel),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<HomeViewModel>(),
                child: const HabitsPage(),
              ),
            ),
          );
        },
        icon: const Icon(Icons.list),
        label: const Text("View All Habits"),
      ),
    );
  }
}

/// Stylized logotype for the home app bar.
class _AadatWordmark extends StatelessWidget {
  const _AadatWordmark({required this.foreground});

  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final highlight = Color.lerp(foreground, const Color(0xFFFFE082), 0.4)!;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          foreground,
          highlight,
        ],
      ).createShader(bounds),
      child: Text(
        'aadat',
        style: GoogleFonts.syne(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: 4,
          height: 1,
          color: Colors.white,
        ),
      ),
    );
  }
}
