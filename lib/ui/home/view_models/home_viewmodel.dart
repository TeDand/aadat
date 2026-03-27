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

  // Per-habit recurrence history, sorted ascending by effectiveFrom.
  // Each entry means "from this date forward, recurrence = X".
  final Map<int, List<({DateTime effectiveFrom, HabitRecurrence recurrence})>>
      _recurrenceHistory = {};

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

  /// Current and best streak for a single habit (in its natural period unit).
  ({int current, int best}) streaksForHabit(Habit habit) {
    if (habit.id == null) return (current: 0, best: 0);
    final today = habitDateOnly(DateTime.now());
    switch (habit.recurrence) {
      case HabitRecurrence.daily:
        return _dailyStreaksForHabit(habit, today);
      case HabitRecurrence.weekly:
        return _weeklyStreaksForHabit(habit, today);
      case HabitRecurrence.monthly:
        return _monthlyStreaksForHabit(habit, today);
      case HabitRecurrence.custom:
        return _customStreaksForHabit(habit, today);
    }
  }

  ({int current, int best}) _dailyStreaksForHabit(Habit habit, DateTime today) {
    var current = 0;
    var best = 0;
    var run = 0;
    var inCurrent = true;
    for (var i = 0; i < 500; i++) {
      final d = today.subtract(Duration(days: i));
      if (!habitAppliesOnDate(habit, d)) break;
      if (isHabitCompletedOn(habit, d)) {
        run++;
        if (inCurrent) current++;
      } else {
        if (inCurrent) inCurrent = false;
        if (run > best) best = run;
        run = 0;
      }
    }
    if (run > best) best = run;
    return (current: current, best: best);
  }

  ({int current, int best}) _weeklyStreaksForHabit(Habit habit, DateTime today) {
    var ws = weekStartForDate(today, weekStartsOnMonday: _weekStartsOnMonday);
    var current = 0;
    var best = 0;
    var run = 0;
    var inCurrent = true;
    for (var i = 0; i < 200; i++) {
      final we = ws.add(const Duration(days: 6));
      var applies = false;
      for (
        var x = ws;
        !x.isAfter(we) && !x.isAfter(today);
        x = x.add(const Duration(days: 1))
      ) {
        if (habitAppliesOnDate(habit, x)) {
          applies = true;
          break;
        }
      }
      if (!applies) break;
      if (isHabitCompletedOn(habit, ws)) {
        run++;
        if (inCurrent) current++;
      } else {
        if (inCurrent) inCurrent = false;
        if (run > best) best = run;
        run = 0;
      }
      ws = ws.subtract(const Duration(days: 7));
    }
    if (run > best) best = run;
    return (current: current, best: best);
  }

  ({int current, int best}) _monthlyStreaksForHabit(Habit habit, DateTime today) {
    var y = today.year;
    var m = today.month;
    var current = 0;
    var best = 0;
    var run = 0;
    var inCurrent = true;
    for (var i = 0; i < 120; i++) {
      final probe = DateTime(y, m, 1);
      if (!habitAppliesOnDate(habit, probe)) break;
      if (isHabitCompletedOn(habit, probe)) {
        run++;
        if (inCurrent) current++;
      } else {
        if (inCurrent) inCurrent = false;
        if (run > best) best = run;
        run = 0;
      }
      if (m == 1) {
        m = 12;
        y--;
      } else {
        m--;
      }
    }
    if (run > best) best = run;
    return (current: current, best: best);
  }

  /// Custom recurrence: weekly streak where a week is complete only if every
  /// scheduled day in that week (up to and including today) was completed.
  ({int current, int best}) _customStreaksForHabit(Habit habit, DateTime today) {
    if (habit.customDays.isEmpty) return (current: 0, best: 0);
    var ws = weekStartForDate(today, weekStartsOnMonday: _weekStartsOnMonday);
    var current = 0;
    var best = 0;
    var run = 0;
    var inCurrent = true;
    for (var i = 0; i < 200; i++) {
      final we = ws.add(const Duration(days: 6));
      // Collect scheduled days in this week that have already occurred.
      final pastDays = <DateTime>[];
      var hasAnyScheduled = false;
      for (var x = ws; !x.isAfter(we); x = x.add(const Duration(days: 1))) {
        if (!habitAppliesOnDate(habit, x)) continue;
        hasAnyScheduled = true;
        if (!x.isAfter(today)) pastDays.add(x);
      }
      if (!hasAnyScheduled) break; // habit not started yet in this or earlier weeks
      if (pastDays.isEmpty) {
        // No scheduled days have passed this week yet — skip to previous week.
        ws = ws.subtract(const Duration(days: 7));
        continue;
      }
      final allDone = pastDays.every((d) => isHabitCompletedOn(habit, d));
      if (allDone) {
        run++;
        if (inCurrent) current++;
      } else {
        if (inCurrent) inCurrent = false;
        if (run > best) best = run;
        run = 0;
      }
      ws = ws.subtract(const Duration(days: 7));
    }
    if (run > best) best = run;
    return (current: current, best: best);
  }

  /// Completion rate 0.0–1.0 over recent periods, or null if no applicable periods.
  double? completionRateForHabit(Habit habit) {
    if (habit.id == null) return null;
    final today = habitDateOnly(DateTime.now());
    var done = 0;
    var total = 0;
    switch (habit.recurrence) {
      case HabitRecurrence.daily:
        for (var i = 0; i < 30; i++) {
          final d = today.subtract(Duration(days: i));
          if (!habitAppliesOnDate(habit, d)) continue;
          total++;
          if (isHabitCompletedOn(habit, d)) done++;
        }
      case HabitRecurrence.weekly:
        var ws = weekStartForDate(today, weekStartsOnMonday: _weekStartsOnMonday);
        for (var i = 0; i < 8; i++) {
          final we = ws.add(const Duration(days: 6));
          var applies = false;
          for (
            var x = ws;
            !x.isAfter(we) && !x.isAfter(today);
            x = x.add(const Duration(days: 1))
          ) {
            if (habitAppliesOnDate(habit, x)) {
              applies = true;
              break;
            }
          }
          if (applies) {
            total++;
            if (isHabitCompletedOn(habit, ws)) done++;
          }
          ws = ws.subtract(const Duration(days: 7));
        }
      case HabitRecurrence.monthly:
        for (var i = 0; i < 6; i++) {
          final probe = DateTime(today.year, today.month - i, 1);
          if (!habitAppliesOnDate(habit, probe)) continue;
          total++;
          if (isHabitCompletedOn(habit, probe)) done++;
        }
      case HabitRecurrence.custom:
        // Rate = weeks where all scheduled days were completed / last 8 applicable weeks.
        var ws = weekStartForDate(today, weekStartsOnMonday: _weekStartsOnMonday);
        for (var i = 0; i < 8; i++) {
          final we = ws.add(const Duration(days: 6));
          final pastDays = <DateTime>[];
          for (var x = ws; !x.isAfter(we) && !x.isAfter(today); x = x.add(const Duration(days: 1))) {
            if (habitAppliesOnDate(habit, x)) pastDays.add(x);
          }
          if (pastDays.isNotEmpty) {
            total++;
            if (pastDays.every((d) => isHabitCompletedOn(habit, d))) done++;
          }
          ws = ws.subtract(const Duration(days: 7));
        }
    }
    if (total == 0) return null;
    return done / total;
  }

  /// Habits with approaching deadlines that are not yet completed.
  List<({Habit habit, String reason})> get urgentHabits {
    final today = habitDateOnly(DateTime.now());
    final result = <({Habit habit, String reason})>[];
    for (final h in _habits) {
      if (h.id == null) continue;
      if (!habitAppliesOnDate(h, today)) continue;
      if (h.recurrence == HabitRecurrence.weekly) {
        final ws = weekStartForDate(today, weekStartsOnMonday: _weekStartsOnMonday);
        final we = ws.add(const Duration(days: 6));
        final daysLeft = we.difference(today).inDays;
        if (daysLeft <= 2 && !isHabitCompletedOn(h, today)) {
          final label = daysLeft == 0
              ? 'last day of week'
              : '$daysLeft day${daysLeft == 1 ? '' : 's'} left in week';
          result.add((habit: h, reason: 'Weekly — $label'));
        }
      } else if (h.recurrence == HabitRecurrence.monthly) {
        final lastDay = DateTime(today.year, today.month + 1, 0).day;
        final daysLeft = lastDay - today.day;
        if (daysLeft <= 2 && !isHabitCompletedOn(h, today)) {
          final label = daysLeft == 0
              ? 'last day of month'
              : '$daysLeft day${daysLeft == 1 ? '' : 's'} left in month';
          result.add((habit: h, reason: 'Monthly — $label'));
        }
      } else if (h.recurrence == HabitRecurrence.custom) {
        // Urgent if ≤2 days remain in the week and any scheduled day this week
        // is still pending.
        final ws = weekStartForDate(today, weekStartsOnMonday: _weekStartsOnMonday);
        final we = ws.add(const Duration(days: 6));
        final daysLeft = we.difference(today).inDays;
        if (daysLeft <= 2) {
          // Check for any upcoming or today-scheduled days this week not yet done.
          var hasPending = false;
          for (var x = today; !x.isAfter(we); x = x.add(const Duration(days: 1))) {
            if (habitAppliesOnDate(h, x) && !isHabitCompletedOn(h, x)) {
              hasPending = true;
              break;
            }
          }
          if (hasPending) {
            final label = daysLeft == 0
                ? 'last day of week'
                : '$daysLeft day${daysLeft == 1 ? '' : 's'} left in week';
            result.add((habit: h, reason: 'Custom — $label'));
          }
        }
      }
    }
    return result;
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

    await _completions.init();
    _habits = await _habitService.fetchHabits();

    _loading = false;
    notifyListeners();
  }

  // ── Recurrence history ───────────────────────────────────────────────────

  void _recordRecurrence(int id, HabitRecurrence recurrence, DateTime from) {
    final list = _recurrenceHistory.putIfAbsent(id, () => []);
    // Avoid duplicate entries for the same date.
    if (list.isNotEmpty && habitDateOnly(list.last.effectiveFrom) == habitDateOnly(from)) {
      list.last = (effectiveFrom: habitDateOnly(from), recurrence: recurrence);
    } else {
      list.add((effectiveFrom: habitDateOnly(from), recurrence: recurrence));
    }
  }

  /// What recurrence did [habit] have on [date]?
  HabitRecurrence recurrenceForHabitOnDate(Habit habit, DateTime date) {
    final id = habit.id;
    if (id == null) return habit.recurrence;
    final history = _recurrenceHistory[id];
    if (history == null || history.isEmpty) return habit.recurrence;
    final d = habitDateOnly(date);
    HabitRecurrence result = history.first.recurrence;
    for (final entry in history) {
      if (!entry.effectiveFrom.isAfter(d)) result = entry.recurrence;
    }
    return result;
  }

  /// Returns the first recurrence change that happened *after* [date], or null.
  ({DateTime on, HabitRecurrence to})? nextChangeAfterDate(
    Habit habit,
    DateTime date,
  ) {
    final id = habit.id;
    if (id == null) return null;
    final history = _recurrenceHistory[id];
    if (history == null || history.length <= 1) return null;
    final d = habitDateOnly(date);
    for (final entry in history) {
      if (entry.effectiveFrom.isAfter(d)) {
        return (on: entry.effectiveFrom, to: entry.recurrence);
      }
    }
    return null;
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  /// Returns the service message (e.g. `habit added!`, `habit already exists!`).
  Future<String> addHabit(Habit habit) async {
    final withCat = habit.copy(category: _canonicalCategory(habit.category));
    final result = await _habitService.addHabit(withCat);
    if (result == 'habit added!') {
      _setMessage(result);
      await fetchHabits();
      // Record initial recurrence starting from the habit's start date (or today).
      final added = _habits.firstWhere(
        (h) => h.title.toLowerCase() == withCat.title.toLowerCase() && h.id != null,
        orElse: () => withCat,
      );
      if (added.id != null) {
        final since = added.startDate ?? habitDateOnly(DateTime.now());
        _recordRecurrence(added.id!, added.recurrence, since);
      }
    } else if (result != 'habit already exists!') {
      _setMessage(result);
      await fetchHabits();
    } else {
      await fetchHabits();
    }
    return result;
  }

  Future<void> deleteHabit(Habit habit) async {
    final id = habit.id;
    if (id != null) {
      _completions.clearForHabit(id);
      _recurrenceHistory.remove(id);
    }
    final result = await _habitService.deleteHabit(habit);
    _setMessage(result);
    await fetchHabits();
  }

  Future<String> updateHabit(Habit habit) async {
    final withCat = habit.copy(
      category: _canonicalCategory(habit.category, excludeHabitId: habit.id),
    );
    // Capture old recurrence before the update.
    final oldHabit = _habits.firstWhere(
      (h) => h.id == withCat.id,
      orElse: () => withCat,
    );
    final result = await _habitService.updateHabit(withCat);
    if (result == 'habit updated!') {
      _setMessage(result);
      // If recurrence changed, record the new recurrence starting today.
      if (withCat.id != null && oldHabit.recurrence != withCat.recurrence) {
        _recordRecurrence(
          withCat.id!,
          withCat.recurrence,
          habitDateOnly(DateTime.now()),
        );
      }
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
