import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  var habits = <String>[];

  GlobalKey<AnimatedListState> historyListKey = GlobalKey<AnimatedListState>();
  String? message;
  void addHabit(String inputText) {
    final habit = inputText.trim();

    if (habits.any((h) => h.toLowerCase() == habit.toLowerCase())) {
      _setMessage("habit already exists!");
      notifyListeners();
      return;
    }

    if (habit.isEmpty) {
      _setMessage("cannot add an empty habit");
      return; // do nothing
    }

    habits.insert(0, inputText); // insert at the beginning
    if (historyListKey.currentState != null) {
      historyListKey.currentState?.insertItem(0); // animate at index 0
    }

    _setMessage("habit added!");
    notifyListeners(); // optional, only if other widgets need to update
  }

  void _setMessage(String msg) {
    message = msg;
    notifyListeners();

    // Clear after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (message == msg) { // avoid overwriting a new message
        message = null;
        notifyListeners();
      }
    });
  }
}
