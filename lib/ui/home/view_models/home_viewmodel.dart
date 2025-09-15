import 'package:flutter/material.dart';
import '../../../data/repositories/habit_model.dart';
import '../../../data/services/habits.dart';

class HomeViewModel extends ChangeNotifier {
  final HabitService _habitService = HabitService();
  bool _loading = false;
  String? message;

  List<Habit> get habits => _habitService.habits;
  bool get loading => _loading;

  HomeViewModel() {
    fetchHabits();
  }

  Future<void> fetchHabits() async {
    _loading = true;
    notifyListeners();

    _habitService.habits = await _habitService.fetchHabits();

    _loading = false;
    notifyListeners();
  }

  Future<void> addHabit(Habit habit) async {
    _habitService.habits = await _habitService.fetchHabits();

    if (_habitService.habits.any(
      (h) => h.title.toLowerCase() == habit.title.toLowerCase(),
    )) {
      _setMessage("habit already exists!");
      notifyListeners();
      return;
    }

    if (habit.title.isEmpty) {
      _setMessage("cannot add an empty habit");
      notifyListeners();
      return;
    }

    await _habitService.addHabit(habit);

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
