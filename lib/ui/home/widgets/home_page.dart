import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:aadat/ui/settings/settings_dialog.dart';
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
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    _startDate = habitDateOnly(DateTime.now());
  }

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
      _startDate = habitDateOnly(DateTime.now());
    });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (viewModel.urgentHabits.isNotEmpty)
              _UrgencyBanner(urgent: viewModel.urgentHabits),
            if (viewModel.urgentHabits.isNotEmpty) const SizedBox(height: 16),
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
                '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _startDate = habitDateOnly(picked));
                  }
                },
                child: const Text('Change'),
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

class _UrgencyBanner extends StatelessWidget {
  const _UrgencyBanner({required this.urgent});

  final List<({Habit habit, String reason})> urgent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 6),
              Text(
                'Approaching deadlines',
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final u in urgent)
            Text(
              '• ${u.habit.title} — ${u.reason}',
              style: textTheme.bodySmall
                  ?.copyWith(color: Colors.orange.shade900),
            ),
        ],
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
