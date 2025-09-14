import 'package:flutter/material.dart';
import '../../../data/repositories/habit_model.dart';
import '../../../data/services/habits.dart';

class HomeViewModel extends ChangeNotifier {
  final HabitService _habitService = HabitService();
  GlobalKey<AnimatedListState> historyListKey = GlobalKey<AnimatedListState>();
  List<Habit> _habits = [];
  bool _loading = false;
  String? message;

  List<Habit> get habits => _habits;
  bool get loading => _loading;

  Future<void> fetchHabits() async {
    _loading = true;
    notifyListeners();

    _habits = await _habitService.fetchHabits();

    _loading = false;
    notifyListeners();
  }

  Future<void> addHabit(Habit habit) async {
    _habits = await _habitService.fetchHabits();

    if (_habits.any(
      (h) => h.title.toLowerCase() == habit.title.toLowerCase(),
    )) {
      _setMessage("habit already exists!");
      notifyListeners();
      return;
    }

    if (habit.title.isEmpty) {
      _setMessage("cannot add an empty habit");
      return; // do nothing
    }

    await _habitService.addHabit(habit);
    _habits.insert(0, habit); // Add to the top of the list

    if (historyListKey.currentState != null) {
      historyListKey.currentState?.insertItem(0); // animate at index 0
    }

    _setMessage("habit added!");

    notifyListeners();
  }

  void _setMessage(String msg) {
    message = msg;
    notifyListeners();

    // Clear after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (message == msg) {
        // avoid overwriting a new message
        message = null;
        notifyListeners();
      }
    });
  }
}

// class HomeViewModel extends ChangeNotifier {
//   var habits = <String>[];

//   GlobalKey<AnimatedListState> historyListKey = GlobalKey<AnimatedListState>();
//   String? message;
//   void addHabit(String inputText) {
//     final habit = inputText.trim();

//     if (habits.any((h) => h.toLowerCase() == habit.toLowerCase())) {
//       _setMessage("habit already exists!");
//       notifyListeners();
//       return;
//     }

//     if (habit.isEmpty) {
//       _setMessage("cannot add an empty habit");
//       return; // do nothing
//     }

//     habits.insert(0, inputText); // insert at the beginning
//     if (historyListKey.currentState != null) {
//       historyListKey.currentState?.insertItem(0); // animate at index 0
//     }

//     _setMessage("habit added!");
//     notifyListeners(); // optional, only if other widgets need to update
//   }

//   void _setMessage(String msg) {
//     message = msg;
//     notifyListeners();

//     // Clear after 3 seconds
//     Future.delayed(const Duration(seconds: 3), () {
//       if (message == msg) {
//         // avoid overwriting a new message
//         message = null;
//         notifyListeners();
//       }
//     });
//   }
// }
