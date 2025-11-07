import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'habits_page.dart';
import 'package:aadat/data/repositories/habit_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final titleController = TextEditingController();
    final descController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 157, 187, 217),
      appBar: AppBar(
        title: const Text("Aadat"),
        backgroundColor: const Color.fromARGB(255, 54, 116, 165),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Habit title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 54, 116, 165),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                if (titleController.text.isEmpty) return;
                final newHabit = Habit(
                  title: titleController.text,
                  description: descController.text,
                );
                viewModel.addHabit(newHabit);
                titleController.clear();
                descController.clear();
              },
              child: const Text("Add Habit"),
            ),
            const SizedBox(height: 24),
            const Text(
              "Your Habits:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: viewModel.habits.length,
                itemBuilder: (context, index) {
                  final habit = viewModel.habits[index];
                  return Card(
                    color: Colors.white,
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(habit.title),
                      subtitle: Text(habit.description),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => viewModel.deleteHabit(habit),
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
        backgroundColor: const Color.fromARGB(255, 54, 116, 165),
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
