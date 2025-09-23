import '../repositories/habit_model.dart';

class HabitService {
  List<Habit> habits = [
    Habit(id: 1, title: 'Clean Code', description: 'Clean up code'),
    Habit(id: 2, title: 'Go Running', description: 'Run 10 miles'),
  ];

  Future<List<Habit>> fetchHabits() async {
    // Simulating network request
    await Future.delayed(Duration(milliseconds: 10));
    return habits;
  }

  Future<void> addHabit(Habit inputHabit) async {
    // Simulating network request
    await Future.delayed(Duration(milliseconds: 10));
    // In a real app, you would send a POST request to your backend here
    habits.insert(0, inputHabit); // Add to the top of the list
  }

  Future<void> deleteHabit(Habit habit) async {
    // Simulating network request
    await Future.delayed(Duration(milliseconds: 10));
    // In a real app, you would send a DELETE request to your backend here
    habits.remove(habit);
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    // Simulating network request
    await Future.delayed(Duration(milliseconds: 10));
    // In a real app, you would send a PUT/PATCH request to your backend here
    final index = habits.indexWhere((habit) => habit.id == updatedHabit.id);
    if (index != -1) {
      habits[index] = updatedHabit;
    }
  }
}
