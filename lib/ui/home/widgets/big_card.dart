import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:flutter/material.dart';

class BigCard extends StatefulWidget {
  const BigCard({super.key, required this.viewModel});

  final HomeViewModel viewModel;

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
    // var appState = context.watch<HomeViewModel>();
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
              widget.viewModel.addHabit(inputText);
              _controller.clear();
              focusNode.requestFocus(); // keep focus on TextField
            },
            style: style,
            decoration: InputDecoration(
              labelText: 'Type your habit here',
              border: OutlineInputBorder(),
            ),
          ),
          if (widget.viewModel.message != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.viewModel.message!,
              style: TextStyle(
                color: widget.viewModel.message!.contains("added!")
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
