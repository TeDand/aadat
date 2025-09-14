import '../repositories/habit_model.dart';

class HabitService {
  List<Habit> habits = [
    Habit(title: 'Clean Code', description: 'Clean up code'),
    Habit(title: 'Go Running', description: 'Run 10 miles'),
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
    habits.add(inputHabit);
  }
}
