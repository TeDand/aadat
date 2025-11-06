import 'package:flutter/material.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'habits_list_view.dart';
import 'favourite_habits_view.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/habit_model.dart';

class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Your Habits"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "All Habits"),
              Tab(text: "Favourites"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // both widgets now read from the SAME viewmodel instance
            const HabitsListView(),
            const FavouriteHabitsView(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            viewModel.addHabit(Habit(title: "New Habit", description: ''));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
