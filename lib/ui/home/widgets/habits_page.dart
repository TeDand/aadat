import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:aadat/ui/home/widgets/habits_list_view.dart';
import 'package:aadat/ui/settings/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'templates_page.dart';

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
      body: Column(
        children: [
          const Expanded(child: HabitsListView()),
          _HabitsFooter(),
        ],
      ),
    );
  }
}

class _HabitsFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = context.read<SettingsViewModel>();

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
        color: scheme.surfaceContainerLowest,
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                if (settings.useHaptics) HapticFeedback.lightImpact();
                showAddHabitSheet(context);
              },
              child: const Text('Add habit'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              onPressed: () {
                final vm = context.read<HomeViewModel>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: vm,
                      child: const TemplatesPage(),
                    ),
                  ),
                );
              },
              child: const Text('Templates'),
            ),
          ),
        ],
      ),
    );
  }
}
