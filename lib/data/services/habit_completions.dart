import '../repositories/habit_model.dart';

/// Tracks completions: daily per day; weekly per week (week start date); monthly per month.
/// Keys: `d|id|yyyy-MM-dd`, `w|id|yyyy-MM-dd`, `m|id|yyyy-MM`
class HabitCompletionService {
  final Set<String> _keys = {};

  HabitCompletionService() {
    _migrateLegacyKeys();
  }

  void _migrateLegacyKeys() {
    final toRemove = <String>[];
    final toAdd = <String>[];
    for (final k in _keys) {
      final parts = k.split('|');
      if (parts.length == 2) {
        final id = int.tryParse(parts[0]);
        if (id != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(parts[1])) {
          toRemove.add(k);
          toAdd.add('d|$id|${parts[1]}');
        }
      }
    }
    for (final k in toRemove) {
      _keys.remove(k);
    }
    for (final k in toAdd) {
      _keys.add(k);
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
  /// When the habit is currently completed (via *any* recurrence key type — this
  /// handles habits whose recurrence was changed after completions were recorded),
  /// ALL key types for that period are cleared so the habit shows as not-done.
  /// When not completed, a key is added under the *current* recurrence type only.
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
      // Remove across all types so legacy keys from a previous recurrence are
      // also cleared, preventing a "stuck completed" state after recurrence change.
      _keys.remove('d|$id|${_dateKey(d)}');
      _keys.remove('w|$id|${_dateKey(ws)}');
      _keys.remove('m|$id|${_monthPayload(d.year, d.month)}');
    } else {
      switch (habit.recurrence) {
        case HabitRecurrence.daily:
          _keys.add('d|$id|${_dateKey(d)}');
        case HabitRecurrence.weekly:
          if (!_weekHasAnyTrackableDay(ws, today, start)) return;
          _keys.add('w|$id|${_dateKey(ws)}');
        case HabitRecurrence.monthly:
          if (!_monthHasAnyTrackableDay(d.year, d.month, today, start)) return;
          _keys.add('m|$id|${_monthPayload(d.year, d.month)}');
      }
    }
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
