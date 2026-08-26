import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/habit_model.dart';
import '../../../data/repositories/joint_goal_model.dart';
import '../../../data/repositories/joint_goal_repository.dart';
import '../../../data/services/habits.dart';

class JointGoalsViewModel extends ChangeNotifier {
  final _repo = JointGoalRepository();
  final _habitService = HabitService();

  List<JointGoal> _goals = [];
  bool _loading = false;
  String? _error;

  String get _uid => Supabase.instance.client.auth.currentUser!.id;

  List<JointGoal> get pendingIncoming =>
      _goals.where((g) => g.status == JointGoalStatus.pending && g.partnerId == _uid).toList();

  List<JointGoal> get pendingOutgoing =>
      _goals.where((g) => g.status == JointGoalStatus.pending && g.initiatorId == _uid).toList();

  List<JointGoal> get active =>
      _goals.where((g) => g.status == JointGoalStatus.active).toList();

  bool get loading => _loading;
  String? get error => _error;

  JointGoalsViewModel() {
    fetch();
  }

  Future<void> fetch() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _goals = await _repo.fetchGoals();
    } catch (e) {
      _error = 'Could not load joint goals.';
    }
    _loading = false;
    notifyListeners();
  }

  /// Creates a joint goal: inserts a habit for the initiator, then records the goal.
  Future<String?> createGoal({
    required String partnerId,
    required String habitTitle,
    required String habitDescription,
    required String habitCategory,
    required HabitRecurrence recurrence,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final habitId = await _habitService.insertAndGetId(
        Habit(
          title: habitTitle,
          description: habitDescription,
          category: habitCategory,
          recurrence: recurrence,
          startDate: startDate,
          endDate: endDate,
        ),
      );
      if (habitId == null) return 'Failed to create the habit.';

      await _repo.createGoal(
        partnerId: partnerId,
        habitTitle: habitTitle,
        habitDescription: habitDescription,
        habitCategory: habitCategory,
        recurrence: recurrence,
        startDate: startDate,
        endDate: endDate,
        initiatorHabitId: habitId,
      );
      await fetch();
      return null;
    } catch (e) {
      return 'Could not create joint goal. Try again.';
    }
  }

  /// Accepts an incoming joint goal: creates the partner's habit, then updates the record.
  Future<String?> acceptGoal(JointGoal goal) async {
    try {
      final habitId = await _habitService.insertAndGetId(
        Habit(
          title: goal.habitTitle,
          description: goal.habitDescription,
          category: goal.habitCategory,
          recurrence: goal.recurrence,
          startDate: goal.startDate,
          endDate: goal.endDate,
        ),
      );
      if (habitId == null) return 'Failed to create the habit.';

      await _repo.acceptGoal(goal.id, habitId);
      await fetch();
      return null;
    } catch (e) {
      return 'Could not accept. Try again.';
    }
  }

  Future<String?> declineGoal(JointGoal goal) async {
    try {
      await _repo.declineGoal(goal.id);
      await fetch();
      return null;
    } catch (e) {
      return 'Could not decline. Try again.';
    }
  }

  Future<String?> cancelGoal(JointGoal goal) async {
    try {
      await _repo.cancelGoal(goal.id);
      await fetch();
      return null;
    } catch (e) {
      return 'Could not cancel. Try again.';
    }
  }

  Future<int> countCompletions(int habitId, DateTime start, DateTime end) {
    return _repo.countCompletions(habitId, start, end);
  }
}
