import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';

/// Aggregated stats for the metrics screen (derived from [HomeViewModel]).
class HabitMetrics {
  const HabitMetrics({
    required this.perfectDayStreak,
    required this.avgCompletionLast7DaysPercent,
    required this.avgCompletionLast30DaysPercent,
    required this.last7DayPercents,
    required this.last7DayLabels,
    required this.habitsByCategory,
    required this.habitsByRecurrence,
    required this.totalHabits,
    required this.todayCompleted,
    required this.todayTotal,
    required this.perfectDaysLast30,
    required this.daysWithHabitsLast30,
  });

  /// Consecutive past days (from today backward) where every applicable habit was done.
  final int perfectDayStreak;

  /// Null if no applicable days in range.
  final double? avgCompletionLast7DaysPercent;
  final double? avgCompletionLast30DaysPercent;

  /// Oldest → newest (left → right), 0–100 each.
  final List<int> last7DayPercents;
  final List<String> last7DayLabels;

  final Map<String, int> habitsByCategory;
  final Map<HabitRecurrence, int> habitsByRecurrence;

  final int totalHabits;
  final int todayCompleted;
  final int todayTotal;

  /// Days in the last 30 where completed == total && total > 0.
  final int perfectDaysLast30;
  final int daysWithHabitsLast30;

  static HabitMetrics compute(HomeViewModel vm) {
    final today = habitDateOnly(DateTime.now());

    var streak = 0;
    for (var i = 0; i < 400; i++) {
      final d = today.subtract(Duration(days: i));
      final s = vm.completionSummaryForDay(d);
      if (s.total == 0) continue;
      if (s.completed == s.total) {
        streak++;
      } else {
        break;
      }
    }

    double? avgN(HomeViewModel v, int n) {
      var sum = 0.0;
      var count = 0;
      for (var i = 0; i < n; i++) {
        final d = today.subtract(Duration(days: i));
        final s = v.completionSummaryForDay(d);
        if (s.total == 0) continue;
        sum += s.completed / s.total;
        count++;
      }
      if (count == 0) return null;
      return (sum / count) * 100;
    }

    final last7Percents = <int>[];
    final last7Labels = <String>[];
    const shortWd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (var i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final s = vm.completionSummaryForDay(d);
      final p = s.total == 0 ? 0 : ((100 * s.completed) / s.total).round().clamp(0, 100);
      last7Percents.add(p);
      last7Labels.add(shortWd[d.weekday - 1]);
    }

    var perfect30 = 0;
    var daysWithHabits30 = 0;
    for (var i = 0; i < 30; i++) {
      final d = today.subtract(Duration(days: i));
      final s = vm.completionSummaryForDay(d);
      if (s.total == 0) continue;
      daysWithHabits30++;
      if (s.completed == s.total) perfect30++;
    }

    final byCat = <String, int>{};
    final byRec = <HabitRecurrence, int>{};
    for (final h in vm.habits) {
      final c = h.category.trim().isEmpty ? 'Uncategorized' : h.category.trim();
      byCat[c] = (byCat[c] ?? 0) + 1;
      byRec[h.recurrence] = (byRec[h.recurrence] ?? 0) + 1;
    }

    final t = vm.completionSummaryForDay(today);

    return HabitMetrics(
      perfectDayStreak: streak,
      avgCompletionLast7DaysPercent: avgN(vm, 7),
      avgCompletionLast30DaysPercent: avgN(vm, 30),
      last7DayPercents: last7Percents,
      last7DayLabels: last7Labels,
      habitsByCategory: byCat,
      habitsByRecurrence: byRec,
      totalHabits: vm.habits.length,
      todayCompleted: t.completed,
      todayTotal: t.total,
      perfectDaysLast30: perfect30,
      daysWithHabitsLast30: daysWithHabits30,
    );
  }
}
