import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/habit_model.dart';

class AiSuggestionService {
  final _client = Supabase.instance.client;

  Future<List<Habit>> suggestHabits(String goal) async {
    final response = await _client.functions.invoke(
      'suggest-habits',
      body: {'goal': goal},
    );

    if (response.status != 200) {
      final message = (response.data as Map?)?['error'] ?? 'Unknown error';
      throw Exception(message);
    }

    final raw = response.data['habits'] as List<dynamic>;
    return raw.map((h) {
      final map = h as Map<String, dynamic>;
      return Habit(
        title: (map['title'] as String? ?? '').trim(),
        description: (map['description'] as String? ?? '').trim(),
        category: (map['category'] as String? ?? '').trim(),
        recurrence: _parseRecurrence(map['recurrence'] as String?),
        startDate: habitDateOnly(DateTime.now()),
      );
    }).toList();
  }

  static HabitRecurrence _parseRecurrence(String? raw) {
    if (raw == null) return HabitRecurrence.daily;
    return HabitRecurrence.values.firstWhere(
      (e) => e.name == raw.toLowerCase(),
      orElse: () => HabitRecurrence.daily,
    );
  }
}
