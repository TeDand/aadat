import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:aadat/ui/home/widgets/habits_list_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Your Habits'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: const HabitsListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          viewModel.addHabit(Habit(title: 'New Habit', description: ''));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
