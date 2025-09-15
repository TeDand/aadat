import 'package:flutter/material.dart';
import 'habits_list_view.dart';
import 'big_card.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
