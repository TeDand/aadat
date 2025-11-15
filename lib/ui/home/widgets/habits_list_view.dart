import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:aadat/ui/home/widgets/habit_card.dart';

class HabitsListView extends StatelessWidget {
  const HabitsListView({super.key});

  void _showHabitEditor(BuildContext context, Habit habit) {
    final homeViewModel = context.read<HomeViewModel>();
    final titleController = TextEditingController(text: habit.title);
    final descriptionController = TextEditingController(
      text: habit.description,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Habit",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ElevatedButton(
                    child: const Text("Save"),
                    onPressed: () {
                      final updated = habit.copy(
                        title: titleController.text,
                        description: descriptionController.text,
                      );
                      homeViewModel.updateHabit(updated);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HomeViewModel>().habits;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 100),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return Center(
          child: HabitCard(
            habit: habit,
            onTap: () => _showHabitEditor(context, habit),
          ),
        );
      },
    );
  }
}
