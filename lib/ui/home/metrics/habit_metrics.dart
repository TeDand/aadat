import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';

/// Stats for a single habit, shown on the Metrics screen.
class HabitStats {
  const HabitStats({
    required this.habit,
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate,
    required this.streakUnit,
    required this.ratePeriodCaption,
  });

  final Habit habit;
  final int currentStreak;
  final int bestStreak;

  /// 0.0–1.0, or null if no applicable periods yet.
  final double? completionRate;

  /// "days", "weeks", or "months".
  final String streakUnit;

  /// e.g. "last 30 days", "last 8 weeks", "last 6 months".
  final String ratePeriodCaption;

  /// Computes stats for every habit in [vm], sorted by current streak descending.
  static List<HabitStats> compute(HomeViewModel vm) {
    final stats = vm.habits
        .where((h) => h.id != null)
        .map((h) {
          final streaks = vm.streaksForHabit(h);
          return HabitStats(
            habit: h,
            currentStreak: streaks.current,
            bestStreak: streaks.best,
            completionRate: vm.completionRateForHabit(h),
            streakUnit: _unit(h.recurrence),
            ratePeriodCaption: _caption(h.recurrence),
          );
        })
        .toList();
    stats.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    return stats;
  }

  static String _unit(HabitRecurrence r) => switch (r) {
    HabitRecurrence.daily => 'days',
    HabitRecurrence.weekly => 'weeks',
    HabitRecurrence.monthly => 'months',
  };

  static String _caption(HabitRecurrence r) => switch (r) {
    HabitRecurrence.daily => 'last 30 days',
    HabitRecurrence.weekly => 'last 8 weeks',
    HabitRecurrence.monthly => 'last 6 months',
  };
}
