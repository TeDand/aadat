import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';

class FavouriteHabitsView extends StatelessWidget {
  const FavouriteHabitsView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final favourites = viewModel.habits.where((h) => h.isFavorite).toList();

    if (viewModel.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favourites.isEmpty) {
      return const Center(child: Text("No favourite habits yet."));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 100),
      itemCount: favourites.length,
      itemBuilder: (context, index) {
        final habit = favourites[index];
        return ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text(habit.title),
          subtitle: Text(habit.description ?? ''),
        );
      },
    );
  }
}
