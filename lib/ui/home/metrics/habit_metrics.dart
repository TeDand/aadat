import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';

/// Stats for one recurrence kind, for the metrics screen.
class RecurrenceMetrics {
  const RecurrenceMetrics({
    required this.recurrence,
    required this.habitCount,
    required this.streak,
    required this.periodCompleted,
    required this.periodTotal,
    required this.avgShortPercent,
    required this.avgLongPercent,
    required this.avgShortCaption,
    required this.avgLongCaption,
    required this.perfectCount,
    required this.applicableCount,
    required this.perfectWindowCaption,
    required this.trendPercents,
    required this.trendLabels,
    required this.trendTitle,
    required this.habitsByCategory,
    required this.periodTitle,
    required this.periodSubtitle,
  });

  final HabitRecurrence recurrence;
  final int habitCount;

  /// Streak in days / weeks / months (same meaning as before).
  final int streak;

  /// Completed / total for the **current** period (today, this week, this month).
  final int periodCompleted;
  final int periodTotal;

  final double? avgShortPercent;
  final double? avgLongPercent;
  final String avgShortCaption;
  final String avgLongCaption;

  /// e.g. perfect days in last 30, perfect weeks in last 8, perfect months in last 6.
  final int perfectCount;
  final int applicableCount;
  final String perfectWindowCaption;

  /// Oldest → newest, 0–100 each.
  final List<int> trendPercents;
  final List<String> trendLabels;
  final String trendTitle;

  final Map<String, int> habitsByCategory;

  final String periodTitle;
  final String periodSubtitle;
}

/// All metrics derived from [HomeViewModel], split by recurrence.
class HabitMetrics {
  const HabitMetrics({
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.totalHabits,
  });

  final RecurrenceMetrics daily;
  final RecurrenceMetrics weekly;
  final RecurrenceMetrics monthly;
  final int totalHabits;

  static Map<String, int> _categoriesFor(
    List<Habit> habits,
    HabitRecurrence r,
  ) {
    final m = <String, int>{};
    for (final h in habits.where((h) => h.recurrence == r)) {
      final c = h.category.trim().isEmpty ? 'Uncategorized' : h.category.trim();
      m[c] = (m[c] ?? 0) + 1;
    }
    return m;
  }

  static int _dailyHabitStreak(HomeViewModel vm) {
    final today = habitDateOnly(DateTime.now());
    var streak = 0;
    for (var i = 0; i < 500; i++) {
      final d = today.subtract(Duration(days: i));
      final s = vm.completionSummaryForDayForRecurrence(d, HabitRecurrence.daily);
      if (s.total == 0) continue;
      if (s.completed == s.total) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static int _weeklyHabitStreak(HomeViewModel vm) {
    final today = habitDateOnly(DateTime.now());
    var ws = weekStartForDate(today, weekStartsOnMonday: vm.weekStartsOnMonday);
    var streak = 0;
    for (var i = 0; i < 200; i++) {
      final s = vm.weeklySummaryForWeekContaining(ws);
      if (s.total == 0) {
        ws = ws.subtract(const Duration(days: 7));
        continue;
      }
      if (s.completed == s.total) {
        streak++;
      } else {
        break;
      }
      ws = ws.subtract(const Duration(days: 7));
    }
    return streak;
  }

  static int _monthlyHabitStreak(HomeViewModel vm) {
    final today = habitDateOnly(DateTime.now());
    var y = today.year;
    var m = today.month;
    var streak = 0;
    for (var i = 0; i < 120; i++) {
      final firstOfMonth = DateTime(y, m);
      if (firstOfMonth.isAfter(today)) break;
      final s = vm.monthlySummaryForMonth(y, m);
      if (s.total == 0) {
        if (m == 1) {
          m = 12;
          y--;
        } else {
          m--;
        }
        continue;
      }
      if (s.completed == s.total) {
        streak++;
      } else {
        break;
      }
      if (m == 1) {
        m = 12;
        y--;
      } else {
        m--;
      }
    }
    return streak;
  }

  static double? _avgDailyOverDays(HomeViewModel vm, int n) {
    final today = habitDateOnly(DateTime.now());
    var sum = 0.0;
    var count = 0;
    for (var i = 0; i < n; i++) {
      final d = today.subtract(Duration(days: i));
      final s = vm.completionSummaryForDayForRecurrence(d, HabitRecurrence.daily);
      if (s.total == 0) continue;
      sum += s.completed / s.total;
      count++;
    }
    if (count == 0) return null;
    return (sum / count) * 100;
  }

  static ({int perfect, int applicable}) _perfectDailyDays(
    HomeViewModel vm,
    int n,
  ) {
    final today = habitDateOnly(DateTime.now());
    var perfect = 0;
    var applicable = 0;
    for (var i = 0; i < n; i++) {
      final d = today.subtract(Duration(days: i));
      final s = vm.completionSummaryForDayForRecurrence(d, HabitRecurrence.daily);
      if (s.total == 0) continue;
      applicable++;
      if (s.completed == s.total) perfect++;
    }
    return (perfect: perfect, applicable: applicable);
  }

  static (List<int>, List<String>) _dailyTrend7(HomeViewModel vm) {
    final today = habitDateOnly(DateTime.now());
    const shortWd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final percents = <int>[];
    final labels = <String>[];
    for (var i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final s = vm.completionSummaryForDayForRecurrence(d, HabitRecurrence.daily);
      final p = s.total == 0
          ? 0
          : ((100 * s.completed) / s.total).round().clamp(0, 100);
      percents.add(p);
      labels.add(shortWd[d.weekday - 1]);
    }
    return (percents, labels);
  }

  static double? _avgWeeklyOverWeeks(HomeViewModel vm, int numWeeks) {
    final today = habitDateOnly(DateTime.now());
    var ws = weekStartForDate(today, weekStartsOnMonday: vm.weekStartsOnMonday);
    var sum = 0.0;
    var count = 0;
    for (var i = 0; i < numWeeks; i++) {
      final s = vm.weeklySummaryForWeekContaining(ws);
      if (s.total == 0) {
        ws = ws.subtract(const Duration(days: 7));
        continue;
      }
      sum += s.completed / s.total;
      count++;
      ws = ws.subtract(const Duration(days: 7));
    }
    if (count == 0) return null;
    return (sum / count) * 100;
  }

  static ({int perfect, int applicable}) _perfectWeeks(
    HomeViewModel vm,
    int numWeeks,
  ) {
    final today = habitDateOnly(DateTime.now());
    var ws = weekStartForDate(today, weekStartsOnMonday: vm.weekStartsOnMonday);
    var perfect = 0;
    var applicable = 0;
    for (var i = 0; i < numWeeks; i++) {
      final s = vm.weeklySummaryForWeekContaining(ws);
      if (s.total == 0) {
        ws = ws.subtract(const Duration(days: 7));
        continue;
      }
      applicable++;
      if (s.completed == s.total) perfect++;
      ws = ws.subtract(const Duration(days: 7));
    }
    return (perfect: perfect, applicable: applicable);
  }

  static String _shortWeekStartLabel(DateTime weekStart) {
    final d = habitDateOnly(weekStart);
    return '${d.month}/${d.day}';
  }

  static (List<int>, List<String>) _weeklyTrend8(HomeViewModel vm) {
    final today = habitDateOnly(DateTime.now());
    var oldest = weekStartForDate(today, weekStartsOnMonday: vm.weekStartsOnMonday);
    oldest = oldest.subtract(const Duration(days: 7 * 7));
    final percents = <int>[];
    final labels = <String>[];
    var w = oldest;
    for (var i = 0; i < 8; i++) {
      final s = vm.weeklySummaryForWeekContaining(w);
      final p = s.total == 0
          ? 0
          : ((100 * s.completed) / s.total).round().clamp(0, 100);
      percents.add(p);
      labels.add(_shortWeekStartLabel(w));
      w = w.add(const Duration(days: 7));
    }
    return (percents, labels);
  }

  static double? _avgMonthlyOverMonths(HomeViewModel vm, int numMonths) {
    final today = habitDateOnly(DateTime.now());
    var sum = 0.0;
    var count = 0;
    for (var k = 0; k < numMonths; k++) {
      final dt = DateTime(today.year, today.month - k, 1);
      final s = vm.monthlySummaryForMonth(dt.year, dt.month);
      if (s.total == 0) continue;
      sum += s.completed / s.total;
      count++;
    }
    if (count == 0) return null;
    return (sum / count) * 100;
  }

  static ({int perfect, int applicable}) _perfectMonths(
    HomeViewModel vm,
    int numMonths,
  ) {
    final today = habitDateOnly(DateTime.now());
    var perfect = 0;
    var applicable = 0;
    for (var k = 0; k < numMonths; k++) {
      final dt = DateTime(today.year, today.month - k, 1);
      final s = vm.monthlySummaryForMonth(dt.year, dt.month);
      if (s.total == 0) continue;
      applicable++;
      if (s.completed == s.total) perfect++;
    }
    return (perfect: perfect, applicable: applicable);
  }

  static const _mo = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static (List<int>, List<String>) _monthlyTrend6(HomeViewModel vm) {
    final today = habitDateOnly(DateTime.now());
    final percents = <int>[];
    final labels = <String>[];
    for (var i = 5; i >= 0; i--) {
      final dt = DateTime(today.year, today.month - i, 1);
      final s = vm.monthlySummaryForMonth(dt.year, dt.month);
      final p = s.total == 0
          ? 0
          : ((100 * s.completed) / s.total).round().clamp(0, 100);
      percents.add(p);
      labels.add(_mo[dt.month - 1]);
    }
    return (percents, labels);
  }

  static RecurrenceMetrics _buildDaily(HomeViewModel vm, List<Habit> habits) {
    final today = habitDateOnly(DateTime.now());
    final t = vm.completionSummaryForDayForRecurrence(today, HabitRecurrence.daily);
    final p30 = _perfectDailyDays(vm, 30);
    final trend = _dailyTrend7(vm);
    final n = habits.where((h) => h.recurrence == HabitRecurrence.daily).length;

    return RecurrenceMetrics(
      recurrence: HabitRecurrence.daily,
      habitCount: n,
      streak: _dailyHabitStreak(vm),
      periodCompleted: t.completed,
      periodTotal: t.total,
      avgShortPercent: _avgDailyOverDays(vm, 7),
      avgLongPercent: _avgDailyOverDays(vm, 30),
      avgShortCaption: 'Avg · last 7 days',
      avgLongCaption: 'Avg · last 30 days',
      perfectCount: p30.perfect,
      applicableCount: p30.applicable,
      perfectWindowCaption: 'Perfect days · last 30 days',
      trendPercents: trend.$1,
      trendLabels: trend.$2,
      trendTitle: 'Last 7 days (daily habits)',
      habitsByCategory: _categoriesFor(habits, HabitRecurrence.daily),
      periodTitle: 'Today',
      periodSubtitle: 'Daily habits due today',
    );
  }

  static RecurrenceMetrics _buildWeekly(HomeViewModel vm, List<Habit> habits) {
    final today = habitDateOnly(DateTime.now());
    final t = vm.weeklySummaryForWeekContaining(today);
    final pw = _perfectWeeks(vm, 8);
    final trend = _weeklyTrend8(vm);
    final n = habits.where((h) => h.recurrence == HabitRecurrence.weekly).length;

    return RecurrenceMetrics(
      recurrence: HabitRecurrence.weekly,
      habitCount: n,
      streak: _weeklyHabitStreak(vm),
      periodCompleted: t.completed,
      periodTotal: t.total,
      avgShortPercent: _avgWeeklyOverWeeks(vm, 8),
      avgLongPercent: _avgWeeklyOverWeeks(vm, 12),
      avgShortCaption: 'Avg · last 8 weeks',
      avgLongCaption: 'Avg · last 12 weeks',
      perfectCount: pw.perfect,
      applicableCount: pw.applicable,
      perfectWindowCaption: 'Perfect weeks · last 8 weeks',
      trendPercents: trend.$1,
      trendLabels: trend.$2,
      trendTitle: 'Last 8 weeks (weekly habits)',
      habitsByCategory: _categoriesFor(habits, HabitRecurrence.weekly),
      periodTitle: 'This week',
      periodSubtitle: 'Weekly habits for the current week',
    );
  }

  static RecurrenceMetrics _buildMonthly(HomeViewModel vm, List<Habit> habits) {
    final today = habitDateOnly(DateTime.now());
    final t = vm.monthlySummaryForMonth(today.year, today.month);
    final pm = _perfectMonths(vm, 6);
    final trend = _monthlyTrend6(vm);
    final n =
        habits.where((h) => h.recurrence == HabitRecurrence.monthly).length;

    return RecurrenceMetrics(
      recurrence: HabitRecurrence.monthly,
      habitCount: n,
      streak: _monthlyHabitStreak(vm),
      periodCompleted: t.completed,
      periodTotal: t.total,
      avgShortPercent: _avgMonthlyOverMonths(vm, 6),
      avgLongPercent: _avgMonthlyOverMonths(vm, 12),
      avgShortCaption: 'Avg · last 6 months',
      avgLongCaption: 'Avg · last 12 months',
      perfectCount: pm.perfect,
      applicableCount: pm.applicable,
      perfectWindowCaption: 'Perfect months · last 6 months',
      trendPercents: trend.$1,
      trendLabels: trend.$2,
      trendTitle: 'Last 6 months (monthly habits)',
      habitsByCategory: _categoriesFor(habits, HabitRecurrence.monthly),
      periodTitle: 'This month',
      periodSubtitle: 'Monthly habits for the current month',
    );
  }

  static HabitMetrics compute(HomeViewModel vm) {
    final habits = vm.habits;
    return HabitMetrics(
      daily: _buildDaily(vm, habits),
      weekly: _buildWeekly(vm, habits),
      monthly: _buildMonthly(vm, habits),
      totalHabits: habits.length,
    );
  }
}
