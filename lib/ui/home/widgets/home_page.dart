// import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import 'habits_list_view.dart';
import 'big_card.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // final homeViewModel = Provider.of<HomeViewModel>(context);
    return Center(
      child: Column(
        children: [
          SizedBox(height: 10),
          Padding(padding: const EdgeInsets.all(10.0), child: BigCard()),
          Expanded(flex: 3, child: HabitsListView()),
        ],
      ),
    );
  }
}
