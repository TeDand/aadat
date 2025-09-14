import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'habits_list_view.dart';
import 'big_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: BigCard(viewModel: viewModel),
          ),
          Expanded(flex: 3, child: HabitsListView(viewModel: viewModel)),
        ],
      ),
    );
  }
}
