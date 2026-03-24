import 'package:aadat/ui/home/widgets/habits_list_view.dart';
import 'package:aadat/ui/settings/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Habits'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: scheme.outlineVariant),
        ),
      ),
      body: const HabitsListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final settings = context.read<SettingsViewModel>();
          if (settings.useHaptics) {
            HapticFeedback.lightImpact();
          }
          showAddHabitSheet(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
