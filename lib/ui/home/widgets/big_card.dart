import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BigCard extends StatefulWidget {
  const BigCard({super.key});

  @override
  State<BigCard> createState() => _BigCardState();
}

class _BigCardState extends State<BigCard> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.watch<HomeViewModel>();
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primary,
      child: Column(
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            onSubmitted: (inputText) {
              homeViewModel.addHabit(Habit(title: inputText, description: ''));
              _controller.clear();
              _focusNode.requestFocus();
            },
            style: theme.textTheme.displayMedium!.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
            decoration: const InputDecoration(
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
                    : Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
