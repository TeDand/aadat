import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/habit_model.dart';

class HabitService {
  List<Habit> _habits = [];
  int _nextId = 1;
  bool _initialized = false;

  List<Habit> get habits => List.unmodifiable(_habits);

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('habits_v1');
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _habits = list
          .map((e) => Habit.fromJson(Map<String, Object?>.from(e as Map)))
          .toList();
      if (_habits.isNotEmpty) {
        _nextId =
            _habits.map((h) => h.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('habits_v1', jsonEncode(_habits.map((h) => h.toJson()).toList()));
  }

  Future<List<Habit>> fetchHabits() async {
    await _init();
    return _habits;
  }

  Future<String> addHabit(Habit inputHabit) async {
    await _init();
    if (inputHabit.title.isEmpty) return "cannot add an empty habit";

    if (_habits.any(
      (h) => h.title.toLowerCase() == inputHabit.title.toLowerCase(),
    )) {
      return "habit already exists!";
    }

    var habitToInsert = inputHabit;
    if (habitToInsert.id == null) {
      habitToInsert = habitToInsert.copy(id: _nextId++);
    }
    _habits.insert(0, habitToInsert);
    await _save();
    return "habit added!";
  }

  Future<String> deleteHabit(Habit habit) async {
    _habits.removeWhere((h) => h.id == habit.id);
    await _save();
    return "habit deleted!";
  }

  Future<String> updateHabit(Habit updatedHabit) async {
    if (updatedHabit.title.isEmpty) return "habit cannot be empty";

    if (_habits.any(
      (h) =>
          h.id != updatedHabit.id &&
          h.title.toLowerCase() == updatedHabit.title.toLowerCase(),
    )) {
      return "habit already exists!";
    }
    final index = _habits.indexWhere((h) => h.id == updatedHabit.id);
    if (index != -1) {
      _habits[index] = updatedHabit;
    }
    await _save();
    return "habit updated!";
  }
}
