import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/habit_model.dart';

class HabitService {
  final _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Habit>> fetchHabits() async {
    final data = await _client
        .from('habits')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (data as List<dynamic>)
        .map((e) => _fromRow(Map<String, Object?>.from(e as Map)))
        .toList();
  }

  Future<String> addHabit(Habit habit) async {
    if (habit.title.isEmpty) return 'cannot add an empty habit';

    final existing = await _client
        .from('habits')
        .select('id')
        .eq('user_id', _userId)
        .ilike('title', habit.title)
        .maybeSingle();
    if (existing != null) return 'habit already exists!';

    await _client.from('habits').insert(_toRow(habit));
    return 'habit added!';
  }

  /// Inserts a habit and returns its new database ID.
  /// Used by joint goals to link the created habit back to the goal record.
  Future<int?> insertAndGetId(Habit habit) async {
    final row = await _client
        .from('habits')
        .insert(_toRow(habit))
        .select('id')
        .single();
    return row['id'] as int?;
  }

  Future<String> deleteHabit(Habit habit) async {
    if (habit.id == null) return 'habit not found';
    await _client.from('habits').delete().eq('id', habit.id!);
    return 'habit deleted!';
  }

  Future<String> updateHabit(Habit habit) async {
    if (habit.title.isEmpty) return 'habit cannot be empty';
    if (habit.id == null) return 'habit not found';

    final existing = await _client
        .from('habits')
        .select('id')
        .eq('user_id', _userId)
        .ilike('title', habit.title)
        .neq('id', habit.id!)
        .maybeSingle();
    if (existing != null) return 'habit already exists!';

    await _client.from('habits').update(_toRow(habit)).eq('id', habit.id!);
    return 'habit updated!';
  }

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, Object?> _toRow(Habit h) => {
    'user_id': _userId,
    'title': h.title,
    'description': h.description,
    'category': h.category,
    'recurrence': h.recurrence.name,
    'custom_days': h.customDays.isEmpty ? '' : h.customDays.join(','),
    'start_date': h.startDate != null ? _dateStr(h.startDate!) : null,
    'end_date': h.endDate != null ? _dateStr(h.endDate!) : null,
    'is_favorite': h.isFavorite,
  };

  Habit _fromRow(Map<String, Object?> row) => Habit(
    id: row['id'] as int?,
    title: row['title'] as String? ?? '',
    description: row['description'] as String? ?? '',
    category: row['category'] as String? ?? '',
    recurrence: _parseRecurrence(row['recurrence'] as String?),
    customDays: _parseCustomDays(row['custom_days'] as String?),
    startDate: _parseDate(row['start_date'] as String?),
    endDate: _parseDate(row['end_date'] as String?),
    isFavorite: row['is_favorite'] as bool? ?? false,
    createdTime: row['created_at'] != null
        ? DateTime.tryParse(row['created_at'] as String)
        : null,
  );

  static String _dateStr(DateTime d) {
    final x = habitDateOnly(d);
    return '${x.year.toString().padLeft(4, '0')}-'
        '${x.month.toString().padLeft(2, '0')}-'
        '${x.day.toString().padLeft(2, '0')}';
  }

  static HabitRecurrence _parseRecurrence(String? raw) {
    if (raw == null) return HabitRecurrence.daily;
    return HabitRecurrence.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => HabitRecurrence.daily,
    );
  }

  static List<int> _parseCustomDays(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .toList();
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
