import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/habit_model.dart';
import '../../../data/services/habit_completions.dart';
import '../../../data/services/habits.dart';

bool _isFutureCalendarDay(DateTime date) {
  return habitDateOnly(date).isAfter(habitDateOnly(DateTime.now()));
}

class HomeViewModel extends ChangeNotifier {
  final HabitService _habitService = HabitService();
  final HabitCompletionService _completions = HabitCompletionService();
  bool _loading = false;
  String? _message;
  List<Habit> _habits = [];
  bool _weekStartsOnMonday = true;

  List<Habit> get habits => List.unmodifiable(_habits);
  bool get loading => _loading;
  String? get message => _message;
  bool get weekStartsOnMonday => _weekStartsOnMonday;

  /// Distinct category labels (first spelling wins), sorted A–Z (case-insensitive).
  List<String> get categorySuggestions {
    final seen = <String, String>{};
    for (final h in _habits) {
      final t = h.category.trim();
      if (t.isEmpty) continue;
      final k = t.toLowerCase();
      seen.putIfAbsent(k, () => t);
    }
    final list = seen.values.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  HomeViewModel() {
    _loadPrefs();
    fetchHabits();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _weekStartsOnMonday = p.getBool('week_starts_monday') ?? true;
    notifyListeners();
  }

  Future<void> setWeekStartsOnMonday(bool value) async {
    _weekStartsOnMonday = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool('week_starts_monday', value);
    notifyListeners();
  }

  String _canonicalCategory(String raw, {int? excludeHabitId}) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    final k = t.toLowerCase();
    for (final h in _habits) {
      if (excludeHabitId != null && h.id == excludeHabitId) continue;
      if (h.category.trim().toLowerCase() == k) return h.category.trim();
    }
    return t;
  }

  bool isHabitCompletedOn(Habit habit, DateTime date) {
    final id = habit.id;
    if (id == null) return false;
    return _completions.isCompleted(
      habit,
      date,
      weekStartsOnMonday: _weekStartsOnMonday,
    );
  }

  /// Completed habits count / habits that apply on [date].
  ({int completed, int total}) completionSummaryForDay(DateTime date) {
    if (_isFutureCalendarDay(date)) return (completed: 0, total: 0);
    final withIds = _habits.where((h) => h.id != null).cast<Habit>().toList();
    if (withIds.isEmpty) return (completed: 0, total: 0);
    final total = _completions.activeHabitsCountOnDate(date, withIds);
    final completed = _completions.completedCountForDay(
      date,
      withIds,
      weekStartsOnMonday: _weekStartsOnMonday,
    );
    return (completed: completed, total: total);
  }

  /// Like [completionSummaryForDay] but only habits with [recurrence].
  ({int completed, int total}) completionSummaryForDayForRecurrence(
    DateTime date,
    HabitRecurrence recurrence,
  ) {
    if (_isFutureCalendarDay(date)) return (completed: 0, total: 0);
    final withIds = _habits
        .where((h) => h.id != null && h.recurrence == recurrence)
        .cast<Habit>()
        .toList();
    if (withIds.isEmpty) return (completed: 0, total: 0);
    final d = habitDateOnly(date);
    final total = _completions.activeHabitsCountOnDate(d, withIds);
    final completed = _completions.completedCountForDay(
      d,
      withIds,
      weekStartsOnMonday: _weekStartsOnMonday,
    );
    return (completed: completed, total: total);
  }

  /// Weekly habits: total / completed for the week containing [date] (any day in that week).
  ({int completed, int total}) weeklySummaryForWeekContaining(DateTime date) {
    final d = habitDateOnly(date);
    if (d.isAfter(habitDateOnly(DateTime.now()))) {
      return (completed: 0, total: 0);
    }
    final ws = weekStartForDate(d, weekStartsOnMonday: _weekStartsOnMonday);
    final we = ws.add(const Duration(days: 6));
    final today = habitDateOnly(DateTime.now());
    final habits = _habits
        .where((h) => h.id != null && h.recurrence == HabitRecurrence.weekly)
        .cast<Habit>()
        .toList();
    var total = 0;
    var completed = 0;
    for (final h in habits) {
      var hasTrackable = false;
      for (var x = ws; !x.isAfter(we); x = x.add(const Duration(days: 1))) {
        if (x.isAfter(today)) break;
        if (habitAppliesOnDate(h, x)) {
          hasTrackable = true;
          break;
        }
      }
      if (!hasTrackable) continue;
      total++;
      if (isHabitCompletedOn(h, ws)) completed++;
    }
    return (completed: completed, total: total);
  }

  /// Monthly habits: total / completed for [year]-[month].
  ({int completed, int total}) monthlySummaryForMonth(int year, int month) {
    final today = habitDateOnly(DateTime.now());
    final first = DateTime(year, month);
    if (first.isAfter(today)) return (completed: 0, total: 0);
    final lastDay = DateTime(year, month + 1, 0).day;
    final habits = _habits
        .where((h) => h.id != null && h.recurrence == HabitRecurrence.monthly)
        .cast<Habit>()
        .toList();
    var total = 0;
    var completed = 0;
    final probe = DateTime(year, month, 1);
    for (final h in habits) {
      var hasTrackable = false;
      for (var day = 1; day <= lastDay; day++) {
        final x = DateTime(year, month, day);
        if (x.isAfter(today)) break;
        if (habitAppliesOnDate(h, x)) {
          hasTrackable = true;
          break;
        }
      }
      if (!hasTrackable) continue;
      total++;
      if (isHabitCompletedOn(h, probe)) completed++;
    }
    return (completed: completed, total: total);
  }

  void toggleHabitCompletion(Habit habit, DateTime date) {
    if (habit.id == null) return;
    if (_isFutureCalendarDay(date)) return;
    _completions.toggle(
      habit,
      date,
      weekStartsOnMonday: _weekStartsOnMonday,
    );
    notifyListeners();
  }

  Future<void> fetchHabits() async {
    _loading = true;
    notifyListeners();

    _habits = await _habitService.fetchHabits();

    _loading = false;
    notifyListeners();
  }

  /// Returns the service message (e.g. `habit added!`, `habit already exists!`).
  Future<String> addHabit(Habit habit) async {
    final withCat = habit.copy(category: _canonicalCategory(habit.category));
    final result = await _habitService.addHabit(withCat);
    if (result == 'habit added!') {
      _setMessage(result);
    } else if (result != 'habit already exists!') {
      _setMessage(result);
    }
    await fetchHabits();
    return result;
  }

  Future<void> deleteHabit(Habit habit) async {
    final id = habit.id;
    if (id != null) {
      _completions.clearForHabit(id);
    }
    final result = await _habitService.deleteHabit(habit);
    _setMessage(result);

    await fetchHabits();
  }

  Future<String> updateHabit(Habit habit) async {
    final withCat = habit.copy(
      category: _canonicalCategory(habit.category, excludeHabitId: habit.id),
    );
    final result = await _habitService.updateHabit(withCat);
    if (result == 'habit updated!') {
      _setMessage(result);
    } else if (result != 'habit already exists!') {
      _setMessage(result);
    }
    await fetchHabits();
    return result;
  }

  void _setMessage(String msg) {
    _message = msg;
    notifyListeners();

    Future.delayed(const Duration(seconds: 3), () {
      if (_message == msg) {
        _message = null;
        notifyListeners();
      }
    });
  }
}
