import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/habit_model.dart';

/// Tracks completions: daily per day; weekly per week (week start date); monthly per month.
/// Keys: `d|id|yyyy-MM-dd`, `w|id|yyyy-MM-dd`, `m|id|yyyy-MM`
///
/// The in-memory Set is loaded from Supabase on [init] and kept in sync via
/// fire-and-forget inserts/deletes on [toggle]. The UI is always optimistic —
/// the in-memory state updates instantly and Supabase syncs in the background.
class HabitCompletionService {
  final _client = Supabase.instance.client;
  final Set<String> _keys = {};
  bool _initialized = false;

  String get _userId => _client.auth.currentUser!.id;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final data = await _client
        .from('completions')
        .select('completion_key')
        .eq('user_id', _userId);
    for (final row in data as List<dynamic>) {
      _keys.add(row['completion_key'] as String);
    }
  }

  static String _dateKey(DateTime date) {
    final d = habitDateOnly(date);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static String _monthPayload(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  bool isCompleted(
    Habit habit,
    DateTime date, {
    required bool weekStartsOnMonday,
  }) {
    final id = habit.id;
    if (id == null) return false;
    final d = habitDateOnly(date);
    if (habit.startDate != null && d.isBefore(habitDateOnly(habit.startDate!))) {
      return false;
    }

    // Check all three key types so that changing a habit's recurrence does not
    // erase completions recorded under the previous recurrence type.
    // toggle() still writes under the *current* recurrence, so new entries are
    // always stored correctly; old entries are simply still recognised here.
    if (_keys.contains('d|$id|${_dateKey(d)}')) return true;
    final ws = weekStartForDate(d, weekStartsOnMonday: weekStartsOnMonday);
    if (_keys.contains('w|$id|${_dateKey(ws)}')) return true;
    if (_keys.contains('m|$id|${_monthPayload(d.year, d.month)}')) return true;
    return false;
  }

  /// Toggle completion for [habit] on [date]. Weekly/monthly flip a whole week/month.
  ///
  /// Updates the in-memory Set immediately (so the UI responds instantly), then
  /// syncs the change to Supabase in the background.
  void toggle(
    Habit habit,
    DateTime date, {
    required bool weekStartsOnMonday,
  }) {
    final id = habit.id;
    if (id == null) return;
    final d = habitDateOnly(date);
    final today = habitDateOnly(DateTime.now());
    if (d.isAfter(today)) return;

    final start = habit.startDate != null ? habitDateOnly(habit.startDate!) : null;
    if (start != null && d.isBefore(start)) return;

    final ws = weekStartForDate(d, weekStartsOnMonday: weekStartsOnMonday);

    if (isCompleted(habit, date, weekStartsOnMonday: weekStartsOnMonday)) {
      final keysToRemove = [
        'd|$id|${_dateKey(d)}',
        'w|$id|${_dateKey(ws)}',
        'm|$id|${_monthPayload(d.year, d.month)}',
      ];
      for (final k in keysToRemove) {
        _keys.remove(k);
      }
      _deleteKeys(keysToRemove);
    } else {
      String key;
      switch (habit.recurrence) {
        case HabitRecurrence.daily:
        case HabitRecurrence.custom:
          key = 'd|$id|${_dateKey(d)}';
        case HabitRecurrence.weekly:
          if (!_weekHasAnyTrackableDay(ws, today, start)) return;
          key = 'w|$id|${_dateKey(ws)}';
        case HabitRecurrence.monthly:
          if (!_monthHasAnyTrackableDay(d.year, d.month, today, start)) return;
          key = 'm|$id|${_monthPayload(d.year, d.month)}';
      }
      _keys.add(key);
      _insertKey(key, id);
    }
  }

  Future<void> _insertKey(String key, int habitId) async {
    await _client.from('completions').insert({
      'user_id': _userId,
      'habit_id': habitId,
      'completion_key': key,
    });
  }

  Future<void> _deleteKeys(List<String> keys) async {
    await _client
        .from('completions')
        .delete()
        .eq('user_id', _userId)
        .inFilter('completion_key', keys);
  }

  bool _weekHasAnyTrackableDay(
    DateTime weekStart,
    DateTime today,
    DateTime? habitStart,
  ) {
    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      if (day.isAfter(today)) continue;
      if (habitStart != null && day.isBefore(habitStart)) continue;
      return true;
    }
    return false;
  }

  bool _monthHasAnyTrackableDay(
    int year,
    int month,
    DateTime today,
    DateTime? habitStart,
  ) {
    final last = DateTime(year, month + 1, 0).day;
    for (var day = 1; day <= last; day++) {
      final d = DateTime(year, month, day);
      if (d.isAfter(today)) continue;
      if (habitStart != null && d.isBefore(habitStart)) continue;
      return true;
    }
    return false;
  }

  void clearForHabit(int habitId) {
    // Only clears in-memory state — the database rows are removed automatically
    // via the ON DELETE CASCADE on the habits table.
    _keys.removeWhere((k) {
      final parts = k.split('|');
      return parts.length == 3 && parts[1] == '$habitId';
    });
  }

  int completedCountForDay(
    DateTime date,
    Iterable<Habit> habits, {
    required bool weekStartsOnMonday,
  }) {
    var n = 0;
    for (final h in habits) {
      if (h.id == null) continue;
      if (!habitAppliesOnDate(h, date)) continue;
      if (isCompleted(h, date, weekStartsOnMonday: weekStartsOnMonday)) n++;
    }
    return n;
  }

  int activeHabitsCountOnDate(DateTime date, Iterable<Habit> habits) {
    var n = 0;
    for (final h in habits) {
      if (h.id == null) continue;
      if (habitAppliesOnDate(h, date)) n++;
    }
    return n;
  }
}
