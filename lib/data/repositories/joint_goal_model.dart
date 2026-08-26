import 'friend_model.dart';
import 'habit_model.dart';

enum JointGoalStatus { pending, active, declined, cancelled }

class JointGoal {
  const JointGoal({
    required this.id,
    required this.initiatorId,
    required this.partnerId,
    required this.habitTitle,
    required this.habitDescription,
    required this.habitCategory,
    required this.recurrence,
    required this.startDate,
    required this.endDate,
    this.initiatorHabitId,
    this.partnerHabitId,
    required this.status,
    this.partnerProfile,
  });

  final int id;
  final String initiatorId;
  final String partnerId;
  final String habitTitle;
  final String habitDescription;
  final String habitCategory;
  final HabitRecurrence recurrence;
  final DateTime startDate;
  final DateTime endDate;
  final int? initiatorHabitId;
  final int? partnerHabitId;
  final JointGoalStatus status;
  final FriendProfile? partnerProfile;

  bool isInitiator(String uid) => initiatorId == uid;

  int? myHabitId(String uid) =>
      initiatorId == uid ? initiatorHabitId : partnerHabitId;

  int? theirHabitId(String uid) =>
      initiatorId == uid ? partnerHabitId : initiatorHabitId;

  int get totalDays => endDate.difference(startDate).inDays + 1;

  int get daysRemaining {
    final today = habitDateOnly(DateTime.now());
    if (today.isAfter(endDate)) return 0;
    if (today.isBefore(startDate)) return totalDays;
    return endDate.difference(today).inDays;
  }

  factory JointGoal.fromJson(Map<String, dynamic> json, String currentUserId) {
    final isInit = (json['initiator_id'] as String) == currentUserId;
    final otherProfileJson = isInit
        ? json['partner_profile'] as Map<String, dynamic>?
        : json['initiator_profile'] as Map<String, dynamic>?;

    return JointGoal(
      id: json['id'] as int,
      initiatorId: json['initiator_id'] as String,
      partnerId: json['partner_id'] as String,
      habitTitle: json['habit_title'] as String,
      habitDescription: (json['habit_description'] as String?) ?? '',
      habitCategory: (json['habit_category'] as String?) ?? '',
      recurrence: parseJointGoalRecurrence(json['recurrence'] as String?),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      initiatorHabitId: json['initiator_habit_id'] as int?,
      partnerHabitId: json['partner_habit_id'] as int?,
      status: parseJointGoalStatus(json['status'] as String?),
      partnerProfile: otherProfileJson != null
          ? FriendProfile.fromJson(otherProfileJson)
          : null,
    );
  }
}

JointGoalStatus parseJointGoalStatus(String? s) {
  switch (s) {
    case 'active':
      return JointGoalStatus.active;
    case 'declined':
      return JointGoalStatus.declined;
    case 'cancelled':
      return JointGoalStatus.cancelled;
    default:
      return JointGoalStatus.pending;
  }
}

HabitRecurrence parseJointGoalRecurrence(String? s) {
  switch (s) {
    case 'weekly':
      return HabitRecurrence.weekly;
    case 'monthly':
      return HabitRecurrence.monthly;
    default:
      return HabitRecurrence.daily;
  }
}
