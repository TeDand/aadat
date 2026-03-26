import 'dart:math' show max;

enum HabitRecurrence { daily, weekly, monthly, custom }

extension HabitRecurrenceLabel on HabitRecurrence {
  String get displayName {
    switch (this) {
      case HabitRecurrence.daily:
        return 'Daily';
      case HabitRecurrence.weekly:
        return 'Weekly';
      case HabitRecurrence.monthly:
        return 'Monthly';
      case HabitRecurrence.custom:
        return 'Custom';
    }
  }
}

DateTime habitDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// [weekStartsOnMonday] `true`: ISO week (Mon–Sun). `false`: week starts Sunday (Sun–Sat).
DateTime weekStartForDate(DateTime date, {required bool weekStartsOnMonday}) {
  final d = habitDateOnly(date);
  if (weekStartsOnMonday) {
    return d.subtract(Duration(days: d.weekday - 1));
  }
  final daysFromSunday = d.weekday % 7;
  return d.subtract(Duration(days: daysFromSunday));
}

/// Whether [habit] is in effect on this calendar [date] (start/end date rules).
/// For custom recurrence, also checks that [date]'s weekday is in customDays.
bool habitAppliesOnDate(Habit habit, DateTime date) {
  final d = habitDateOnly(date);
  if (habit.startDate != null && d.isBefore(habitDateOnly(habit.startDate!))) {
    return false;
  }
  if (habit.endDate != null && d.isAfter(habitDateOnly(habit.endDate!))) {
    return false;
  }
  if (habit.recurrence == HabitRecurrence.custom) {
    return habit.customDays.contains(d.weekday); // 1=Mon … 7=Sun
  }
  return true;
}

/// Next title `New Habit N` after the highest `N` (or plain `New Habit` treated as 1).
String suggestNextNewHabitTitle(Iterable<Habit> habits) {
  var maxN = 0;
  final exactNew = RegExp(r'^new habit$', caseSensitive: false);
  final numbered = RegExp(r'^new habit (\d+)$', caseSensitive: false);
  for (final h in habits) {
    final t = h.title.trim();
    if (exactNew.hasMatch(t)) {
      maxN = max(maxN, 1);
      continue;
    }
    final m = numbered.firstMatch(t);
    if (m != null) {
      final n = int.tryParse(m.group(1)!);
      if (n != null) maxN = max(maxN, n);
    }
  }
  return 'New Habit ${maxN + 1}';
}

class Habit {
  int? id;
  String title;
  String description;
  bool isFavorite;
  DateTime? createdTime;
  /// User-defined label, e.g. "Health", "Work".
  String category;
  HabitRecurrence recurrence;
  /// Weekdays on which this habit applies when [recurrence] is [HabitRecurrence.custom].
  /// Values 1–7 (Monday=1, Sunday=7), matching [DateTime.weekday].
  List<int> customDays;
  /// First day this habit applies (optional). Compared as calendar dates only.
  DateTime? startDate;
  /// Last day this habit applies (optional). Habit disappears from calendar after this date.
  DateTime? endDate;

  Habit({
    this.id,
    required this.title,
    required this.description,
    this.isFavorite = false,
    this.createdTime,
    this.category = '',
    this.recurrence = HabitRecurrence.daily,
    this.customDays = const [],
    this.startDate,
    this.endDate,
  });

  Habit copy({
    int? id,
    String? title,
    String? description,
    bool? isFavorite,
    DateTime? createdTime,
    String? category,
    HabitRecurrence? recurrence,
    List<int>? customDays,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      createdTime: createdTime ?? this.createdTime,
      category: category ?? this.category,
      recurrence: recurrence ?? this.recurrence,
      customDays: customDays ?? this.customDays,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  Map<String, Object?> toJson() => {
    HabitFields.id: id,
    HabitFields.title: title,
    HabitFields.description: description,
    HabitFields.isFavorite: isFavorite ? 1 : 0,
    HabitFields.createdTime: createdTime?.toIso8601String(),
    HabitFields.category: category,
    HabitFields.recurrence: recurrence.name,
    HabitFields.customDays: customDays.isEmpty ? '' : customDays.join(','),
    HabitFields.startDate: startDate != null ? _dateKeyForJson(startDate!) : null,
    HabitFields.endDate: endDate != null ? _dateKeyForJson(endDate!) : null,
  };

  factory Habit.fromJson(Map<String, Object?> json) => Habit(
    id: json[HabitFields.id] as int?,
    title: json[HabitFields.title] as String,
    description: json[HabitFields.description] as String,
    isFavorite: (json[HabitFields.isFavorite] as int? ?? 0) == 1,
    createdTime: DateTime.tryParse(
      json[HabitFields.createdTime] as String? ?? '',
    ),
    category: (json[HabitFields.category] as String?) ?? '',
    recurrence: _parseRecurrence(json[HabitFields.recurrence] as String?),
    customDays: _parseCustomDays(json[HabitFields.customDays] as String?),
    startDate: _parseStartDate(json[HabitFields.startDate] as String?),
    endDate: _parseStartDate(json[HabitFields.endDate] as String?),
  );
}

String _dateKeyForJson(DateTime d) {
  final x = habitDateOnly(d);
  return '${x.year.toString().padLeft(4, '0')}-'
      '${x.month.toString().padLeft(2, '0')}-'
      '${x.day.toString().padLeft(2, '0')}';
}

DateTime? _parseStartDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

HabitRecurrence _parseRecurrence(String? raw) {
  if (raw == null) return HabitRecurrence.daily;
  return HabitRecurrence.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => HabitRecurrence.daily,
  );
}

List<int> _parseCustomDays(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  return raw
      .split(',')
      .map((s) => int.tryParse(s.trim()))
      .whereType<int>()
      .where((d) => d >= 1 && d <= 7)
      .toList();
}

class HabitFields {
  static const String tableName = 'habits';
  static const String idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
  static const String textType = 'TEXT NOT NULL';
  static const String intType = 'INTEGER NOT NULL';
  static const String id = 'id';
  static const String title = 'title';
  static const String description = 'description';
  static const String isFavorite = 'is_favorite';
  static const String createdTime = 'created_time';
  static const String category = 'category';
  static const String recurrence = 'recurrence';
  static const String customDays = 'custom_days';
  static const String startDate = 'start_date';
  static const String endDate = 'end_date';

  static const List<String> values = [
    id,
    title,
    description,
    isFavorite,
    createdTime,
    category,
    recurrence,
    customDays,
    startDate,
    endDate,
  ];
}

