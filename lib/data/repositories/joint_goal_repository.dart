import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/friend_model.dart';
import '../repositories/habit_model.dart';
import 'joint_goal_model.dart';

class JointGoalRepository {
  SupabaseClient get _db => Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;

  Future<List<JointGoal>> fetchGoals() async {
    final goalRows = (await _db
        .from('joint_goals')
        .select(
          'id, initiator_id, partner_id, habit_title, habit_description, '
          'habit_category, recurrence, start_date, end_date, '
          'initiator_habit_id, partner_habit_id, status',
        )
        .or('initiator_id.eq.$_uid,partner_id.eq.$_uid')
        .not('status', 'eq', 'declined')
        .not('status', 'eq', 'cancelled')) as List;

    if (goalRows.isEmpty) return [];

    final partnerIds = <String>{};
    for (final row in goalRows) {
      final r = row as Map<String, dynamic>;
      final initiatorId = r['initiator_id'] as String;
      final partnerId = r['partner_id'] as String;
      partnerIds.add(initiatorId == _uid ? partnerId : initiatorId);
    }

    final profileRows = (await _db
        .from('profiles')
        .select('id, email, display_name')
        .inFilter('id', partnerIds.toList())) as List;

    final profiles = <String, FriendProfile>{
      for (final p in profileRows)
        (p as Map<String, dynamic>)['id'] as String:
            FriendProfile.fromJson(p as Map<String, dynamic>),
    };

    return goalRows.map((row) {
      final r = row as Map<String, dynamic>;
      final initiatorId = r['initiator_id'] as String;
      final partnerId = r['partner_id'] as String;
      final otherId = initiatorId == _uid ? partnerId : initiatorId;
      return JointGoal(
        id: r['id'] as int,
        initiatorId: initiatorId,
        partnerId: partnerId,
        habitTitle: r['habit_title'] as String,
        habitDescription: (r['habit_description'] as String?) ?? '',
        habitCategory: (r['habit_category'] as String?) ?? '',
        recurrence: parseJointGoalRecurrence(r['recurrence'] as String?),
        startDate: DateTime.parse(r['start_date'] as String),
        endDate: DateTime.parse(r['end_date'] as String),
        initiatorHabitId: r['initiator_habit_id'] as int?,
        partnerHabitId: r['partner_habit_id'] as int?,
        status: parseJointGoalStatus(r['status'] as String?),
        partnerProfile: profiles[otherId],
      );
    }).toList();
  }

  Future<void> createGoal({
    required String partnerId,
    required String habitTitle,
    required String habitDescription,
    required String habitCategory,
    required HabitRecurrence recurrence,
    required DateTime startDate,
    required DateTime endDate,
    required int initiatorHabitId,
  }) async {
    await _db.from('joint_goals').insert({
      'initiator_id': _uid,
      'partner_id': partnerId,
      'habit_title': habitTitle,
      'habit_description': habitDescription,
      'habit_category': habitCategory,
      'recurrence': recurrence.name,
      'start_date': _dateStr(startDate),
      'end_date': _dateStr(endDate),
      'initiator_habit_id': initiatorHabitId,
      'status': 'pending',
    });
  }

  Future<void> acceptGoal(int goalId, int partnerHabitId) async {
    await _db.from('joint_goals').update({
      'partner_habit_id': partnerHabitId,
      'status': 'active',
    }).eq('id', goalId);
  }

  Future<void> declineGoal(int goalId) async {
    await _db
        .from('joint_goals')
        .update({'status': 'declined'}).eq('id', goalId);
  }

  Future<void> cancelGoal(int goalId) async {
    await _db
        .from('joint_goals')
        .update({'status': 'cancelled'}).eq('id', goalId);
  }

  /// Count how many times [habitId] was completed between [startDate] and [endDate].
  /// Works for the current user's own habits and for a joint-goal partner's linked
  /// habit (after the RLS policy allows it).
  Future<int> countCompletions(
    int habitId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final rows = (await _db
        .from('completions')
        .select('completion_key')
        .eq('habit_id', habitId)) as List;

    var count = 0;
    for (final row in rows) {
      final key = (row as Map<String, dynamic>)['completion_key'] as String;
      final date = _dateFromKey(key);
      if (date != null &&
          !date.isBefore(habitDateOnly(startDate)) &&
          !date.isAfter(habitDateOnly(endDate))) {
        count++;
      }
    }
    return count;
  }

  // completion_key formats: 'd|habitId|yyyy-MM-dd', 'w|habitId|yyyy-MM-dd', 'm|habitId|yyyy-MM'
  DateTime? _dateFromKey(String key) {
    final parts = key.split('|');
    if (parts.length < 3) return null;
    final raw = parts[2];
    // Monthly key is yyyy-MM — treat as first of month
    return DateTime.tryParse(raw.length == 7 ? '$raw-01' : raw);
  }

  static String _dateStr(DateTime d) {
    final x = habitDateOnly(d);
    return '${x.year.toString().padLeft(4, '0')}-'
        '${x.month.toString().padLeft(2, '0')}-'
        '${x.day.toString().padLeft(2, '0')}';
  }
}
