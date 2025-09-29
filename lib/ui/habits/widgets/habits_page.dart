import 'package:flutter/material.dart';

class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  // TODO: rewrite with view model to get functioning habits page
  @override
  Widget build(BuildContext context) {
    // var appState = context.watch<MyAppState>();

    // if (appState.habits.isEmpty) {
    //   return Center(child: Text('No habits yet.'));
    // }

    return Scaffold();

    // return ListView(
    //   children: [
    //     Padding(
    //       padding: const EdgeInsets.all(20),
    //       child: Text(
    //         'You have '
    //         '${appState.habits.length} habit(s):',
    //       ),
    //     ),
    //     for (var habit in appState.habits)
    //       ListTile(
    //         leading: Icon(Icons.favorite),
    //         title: Text(habit),
    //       ),
    //   ],
    // );
  }
}
