import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BigCard extends StatefulWidget {
  @override
  State<BigCard> createState() => _BigCardState();
}

class _BigCardState extends State<BigCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose(); // free memory
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeViewModel = Provider.of<HomeViewModel>(context);
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );
    final focusNode = FocusNode();

    return Card(
      color: theme.colorScheme.primary,
      child: Column(
        children: [
          TextField(
            controller: _controller,
            focusNode: focusNode,
            onSubmitted: (inputText) {
              homeViewModel.addHabit(
                Habit(title: inputText, description: 'tmp'),
              );
              _controller.clear();
              focusNode.requestFocus(); // keep focus on TextField
            },
            style: style,
            decoration: InputDecoration(
              labelText: 'Type your habit here',
              border: OutlineInputBorder(),
            ),
          ),
          if (homeViewModel.message != null) ...[
            const SizedBox(height: 8),
            Text(
              homeViewModel.message!,
              style: TextStyle(
                color: homeViewModel.message!.contains("added!")
                    ? Colors.green
                    : const Color.fromARGB(255, 246, 246, 245),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
