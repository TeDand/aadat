import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HabitsListView extends StatefulWidget {
  @override
  State<HabitsListView> createState() => _HabitsListViewState();
}

class _HabitsListViewState extends State<HabitsListView> {
  /// Used to "fade out" the history items at the bottom, to suggest continuation.
  static const Gradient _maskingGradient = LinearGradient(
    // This gradient goes from fully transparent to fully opaque black...
    colors: [Colors.black, Colors.transparent],
    // ... from the top (transparent) to half (0.5) of the way to the bottom.
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  final _key = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    // Optional: pass the key to the app state if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().historyListKey = _key;

      for (int i = 0; i < context.read<HomeViewModel>().habits.length; i++) {
        _key.currentState?.insertItem(i);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeViewModel = Provider.of<HomeViewModel>(context);

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      // This blend mode takes the opacity of the shader (i.e. our gradient)
      // and applies it to the destination (i.e. our animated list).
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: false,
        padding: EdgeInsets.only(top: 100),
        initialItemCount: homeViewModel.habits.length,
        itemBuilder: (context, index, animation) {
          final habit = homeViewModel.habits[index];
          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  print("habit clicked");
                },
                label: Text(habit.title, semanticsLabel: habit.title),
              ),
            ),
          );
        },
      ),
    );
  }
}
