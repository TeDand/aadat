import 'package:aadat/data/repositories/habit_model.dart';
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
  final List<Habit> _displayedHabits =
      []; // local source of truth to display animated list

  @override
  void initState() {
    super.initState();

    final homeViewModel = context.read<HomeViewModel>();

    // On first build, we want to animate all existing habits
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Insert in reverse order to have the newest at the top
      final habits = homeViewModel.habits;
      for (int i = habits.length - 1; i >= 0; i--) {
        _insertItem(habits[i]);
      }
    });

    homeViewModel.addListener(() {
      // On every change, we want to add any new habits
      for (var habit in homeViewModel.habits) {
        if (!_displayedHabits.contains(habit)) {
          _insertItem(habit);
        }
      }
    });
  }

  void _insertItem(Habit habit) {
    _displayedHabits.insert(0, habit); // insert habit at the top of local list
    _key.currentState?.insertItem(0, duration: Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      // This blend mode takes the opacity of the shader (i.e. our gradient)
      // and applies it to the destination (i.e. our animated list).
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: false,
        padding: EdgeInsets.only(top: 100),
        initialItemCount: 0, // start empty, items added in initState
        itemBuilder: (context, index, animation) {
          final habit = _displayedHabits[index];
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
