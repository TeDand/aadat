import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/habit_model.dart';

/// Stores free-text notes keyed by habit id + date.
/// Storage key: `habit_notes_v1` — JSON-encoded map of String to String
/// where each map key is `"habitId|yyyy-MM-dd"`.
class HabitNoteService {
  final Map<String, String> _notes = {};
  bool _initialized = false;

  static const _storageKey = 'habit_notes_v1';

  static String _key(int habitId, DateTime date) {
    final d = habitDateOnly(date);
    final ds =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '$habitId|$ds';
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      for (final e in decoded.entries) {
        _notes[e.key] = e.value as String;
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(_notes));
  }

  String? getNote(int habitId, DateTime date) => _notes[_key(habitId, date)];

  Future<void> setNote(int habitId, DateTime date, String note) async {
    final k = _key(habitId, date);
    if (note.trim().isEmpty) {
      _notes.remove(k);
    } else {
      _notes[k] = note.trim();
    }
    await _save();
  }

  void clearForHabit(int habitId) {
    _notes.removeWhere((k, _) => k.startsWith('$habitId|'));
    _save();
  }
}
