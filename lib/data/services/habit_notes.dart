import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/habit_model.dart';

/// Stores free-text notes keyed by habit id + date.
/// note_key format: `{habitId}|yyyy-MM-dd`
class HabitNoteService {
  final _client = Supabase.instance.client;
  final Map<String, String> _notes = {};
  bool _initialized = false;

  String get _userId => _client.auth.currentUser!.id;

  static String _key(int habitId, DateTime date) {
    final d = habitDateOnly(date);
    final ds =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '$habitId|$ds';
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final data = await _client
        .from('notes')
        .select('note_key, content')
        .eq('user_id', _userId);
    for (final row in data as List<dynamic>) {
      _notes[row['note_key'] as String] = row['content'] as String;
    }
  }

  String? getNote(int habitId, DateTime date) => _notes[_key(habitId, date)];

  Future<void> setNote(int habitId, DateTime date, String note) async {
    final k = _key(habitId, date);
    if (note.trim().isEmpty) {
      _notes.remove(k);
      await _client
          .from('notes')
          .delete()
          .eq('user_id', _userId)
          .eq('note_key', k);
    } else {
      _notes[k] = note.trim();
      await _client.from('notes').upsert({
        'user_id': _userId,
        'habit_id': habitId,
        'note_key': k,
        'content': note.trim(),
      });
    }
  }

  void clearForHabit(int habitId) {
    // Only clears in-memory state — the database rows are removed automatically
    // via the ON DELETE CASCADE on the habits table.
    _notes.removeWhere((k, _) => k.startsWith('$habitId|'));
  }
}
