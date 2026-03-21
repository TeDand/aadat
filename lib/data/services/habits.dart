import '../repositories/habit_model.dart';

class HabitService {
  List<Habit> _habits = [];
  int _nextId = 1;

  List<Habit> get habits => List.unmodifiable(_habits);

  Future<List<Habit>> fetchHabits() async {
    return _habits;
  }

  Future<String> addHabit(Habit inputHabit) async {
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
    return "habit added!";
  }

  Future<String> deleteHabit(Habit habit) async {
    _habits.removeWhere((h) => h.id == habit.id);
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
    // replace old habit with updated one
    final index = _habits.indexWhere((h) => h.id == updatedHabit.id);
    if (index != -1) {
      _habits[index] = updatedHabit;
    }

    return "habit updated!";
  }
}
