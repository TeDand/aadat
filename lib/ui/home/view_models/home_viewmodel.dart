import 'package:flutter/material.dart';
import '../../../data/repositories/habit_model.dart';
import '../../../data/services/habits.dart';

class HomeViewModel extends ChangeNotifier {
  final HabitService _habitService = HabitService();
  bool _loading = false;
  String? _message;
  List<Habit> _habits = [];

  List<Habit> get habits => List.unmodifiable(_habits);
  bool get loading => _loading;
  String? get message => _message;

  HomeViewModel() {
    fetchHabits();
  }

  Future<void> fetchHabits() async {
    _loading = true;
    notifyListeners();

    _habits = await _habitService.fetchHabits();

    _loading = false;
    notifyListeners();
  }

  Future<void> addHabit(Habit habit) async {
    final result = await _habitService.addHabit(habit);
    _setMessage(result);

    await fetchHabits();
  }

  Future<void> deleteHabit(Habit habit) async {
    await _habitService.deleteHabit(habit);
    _setMessage("habit deleted!");

    await fetchHabits();
  }

  Future<void> updateHabit(Habit habit) async {
    final result = await _habitService.updateHabit(habit);
    _setMessage(result);

    await fetchHabits();
  }

  void _setMessage(String msg) {
    _message = msg;
    notifyListeners();

    // Clear after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (_message == msg) {
        // avoid overwriting a new message
        _message = null;
        notifyListeners();
      }
    });
  }
}
