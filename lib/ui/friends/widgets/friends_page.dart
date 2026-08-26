import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/friend_model.dart';
import '../../../data/repositories/habit_model.dart';
import '../../../data/repositories/joint_goal_model.dart';
import '../view_models/friends_viewmodel.dart';
import '../view_models/joint_goals_viewmodel.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FriendsViewModel()),
        ChangeNotifierProvider(create: (_) => JointGoalsViewModel()),
      ],
      child: const _FriendsPageBody(),
    );
  }
}

// ─── Page body ────────────────────────────────────────────────────────────────

class _FriendsPageBody extends StatelessWidget {
  const _FriendsPageBody();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final friendsVm = context.watch<FriendsViewModel>();
    final goalsVm = context.watch<JointGoalsViewModel>();

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Friends'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: scheme.outlineVariant),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add friend',
            onPressed: () => _showAddFriendDialog(context, friendsVm),
          ),
        ],
      ),
      body: (friendsVm.loading || goalsVm.loading)
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await context.read<FriendsViewModel>().fetchFriendships();
                await context.read<JointGoalsViewModel>().fetch();
              },
              child: _FriendsList(friendsVm: friendsVm, goalsVm: goalsVm),
            ),
    );
  }

  void _showAddFriendDialog(BuildContext context, FriendsViewModel vm) async {
    final sentTo = await showDialog<String?>(
      context: context,
      builder: (ctx) => _AddFriendDialog(vm: vm),
    );
    if (sentTo != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent to $sentTo')),
      );
    }
  }
}

// ─── Main list ────────────────────────────────────────────────────────────────

class _FriendsList extends StatelessWidget {
  const _FriendsList({required this.friendsVm, required this.goalsVm});
  final FriendsViewModel friendsVm;
  final JointGoalsViewModel goalsVm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final friends = friendsVm.friends;
    final incoming = friendsVm.incoming;
    final outgoing = friendsVm.outgoing;
    final incomingGoals = goalsVm.pendingIncoming;
    final outgoingGoals = goalsVm.pendingOutgoing;
    final activeGoals = goalsVm.active;

    final empty = friends.isEmpty &&
        incoming.isEmpty &&
        outgoing.isEmpty &&
        incomingGoals.isEmpty &&
        outgoingGoals.isEmpty &&
        activeGoals.isEmpty;

    if (empty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.people_outline, size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No friends yet.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add someone by their email.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        if (incoming.isNotEmpty) ...[
          _SectionHeader(label: 'REQUESTS', scheme: scheme, textTheme: textTheme),
          for (final f in incoming) _IncomingTile(friendship: f, vm: friendsVm),
          const SizedBox(height: 20),
        ],
        if (outgoing.isNotEmpty) ...[
          _SectionHeader(label: 'SENT', scheme: scheme, textTheme: textTheme),
          for (final f in outgoing) _OutgoingTile(friendship: f, vm: friendsVm),
          const SizedBox(height: 20),
        ],
        if (incomingGoals.isNotEmpty) ...[
          _SectionHeader(label: 'GOAL INVITES', scheme: scheme, textTheme: textTheme),
          for (final g in incomingGoals) _IncomingGoalTile(goal: g, vm: goalsVm),
          const SizedBox(height: 20),
        ],
        if (activeGoals.isNotEmpty) ...[
          _SectionHeader(label: 'JOINT GOALS', scheme: scheme, textTheme: textTheme),
          for (final g in activeGoals) _ActiveGoalTile(goal: g, vm: goalsVm),
          const SizedBox(height: 20),
        ],
        if (outgoingGoals.isNotEmpty) ...[
          _SectionHeader(label: 'SENT GOAL INVITES', scheme: scheme, textTheme: textTheme),
          for (final g in outgoingGoals) _OutgoingGoalTile(goal: g, vm: goalsVm),
          const SizedBox(height: 20),
        ],
        if (friends.isNotEmpty) ...[
          _SectionHeader(label: 'FRIENDS', scheme: scheme, textTheme: textTheme),
          for (final f in friends)
            _FriendTile(friendship: f, friendsVm: friendsVm, goalsVm: goalsVm),
        ],
      ],
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.scheme,
    required this.textTheme,
  });
  final String label;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ─── Friend request tiles ─────────────────────────────────────────────────────

enum _FriendAction { jointGoal, unfriend }

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.friendship,
    required this.friendsVm,
    required this.goalsVm,
  });
  final Friendship friendship;
  final FriendsViewModel friendsVm;
  final JointGoalsViewModel goalsVm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = friendship.otherProfile;
    final label = profile?.label ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant)),
      child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(label),
        subtitle: (profile?.displayName?.isNotEmpty == true)
            ? Text(
                profile!.email,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              )
            : null,
        trailing: PopupMenuButton<_FriendAction>(
          icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant, size: 20),
          onSelected: (action) {
            if (action == _FriendAction.jointGoal) {
              _showCreateGoalDialog(context, profile);
            } else {
              _confirmRemove(context);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: _FriendAction.jointGoal,
              child: ListTile(
                leading: Icon(Icons.flag_outlined),
                title: Text('Set joint goal'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: _FriendAction.unfriend,
              child: ListTile(
                leading: Icon(Icons.person_remove_outlined),
                title: Text('Unfriend'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGoalDialog(BuildContext context, FriendProfile? profile) {
    if (profile == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => _CreateGoalDialog(
        partnerId: profile.id,
        partnerLabel: profile.label,
        vm: goalsVm,
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove friend?'),
        content: Text(
          'Remove ${friendship.otherProfile?.label ?? 'this person'} from your friends?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (go == true && context.mounted) {
      final err = await friendsVm.removeFriendship(friendship.id);
      if (err != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }
}

class _IncomingTile extends StatelessWidget {
  const _IncomingTile({required this.friendship, required this.vm});
  final Friendship friendship;
  final FriendsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = friendship.otherProfile?.label ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration:
          BoxDecoration(border: Border.all(color: scheme.outlineVariant)),
      child: ListTile(
        leading: Icon(Icons.person_add_outlined, color: scheme.primary),
        title: Text(label),
        subtitle: Text('Wants to be friends',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () async {
                final err = await vm.removeFriendship(friendship.id);
                if (err != null && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(err)));
                }
              },
              child: const Text('Decline'),
            ),
            const SizedBox(width: 4),
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () async {
                final err = await vm.acceptRequest(friendship.id);
                if (err != null && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(err)));
                }
              },
              child: const Text('Accept'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutgoingTile extends StatelessWidget {
  const _OutgoingTile({required this.friendship, required this.vm});
  final Friendship friendship;
  final FriendsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = friendship.otherProfile?.label ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration:
          BoxDecoration(border: Border.all(color: scheme.outlineVariant)),
      child: ListTile(
        leading:
            Icon(Icons.hourglass_empty_outlined, color: scheme.onSurfaceVariant),
        title: Text(label),
        subtitle: Text('Request pending',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        trailing: TextButton(
          onPressed: () async {
            final err = await vm.removeFriendship(friendship.id);
            if (err != null && context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(err)));
            }
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

// ─── Joint goal tiles ─────────────────────────────────────────────────────────

class _IncomingGoalTile extends StatelessWidget {
  const _IncomingGoalTile({required this.goal, required this.vm});
  final JointGoal goal;
  final JointGoalsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final partnerLabel = goal.partnerProfile?.label ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration:
          BoxDecoration(border: Border.all(color: scheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$partnerLabel invited you',
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(goal.habitTitle,
                style:
                    textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (goal.habitDescription.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(goal.habitDescription,
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 4),
            Text(
              '${goal.recurrence.displayName} · ends ${_formatDate(goal.endDate)} · ${goal.totalDays} days',
              style:
                  textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    final err = await vm.declineGoal(goal);
                    if (err != null && context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                  onPressed: () async {
                    final err = await vm.acceptGoal(goal);
                    if (err != null && context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(err)));
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Joint goal accepted — habit added!')),
                      );
                    }
                  },
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OutgoingGoalTile extends StatelessWidget {
  const _OutgoingGoalTile({required this.goal, required this.vm});
  final JointGoal goal;
  final JointGoalsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration:
          BoxDecoration(border: Border.all(color: scheme.outlineVariant)),
      child: ListTile(
        leading: Icon(Icons.hourglass_empty_outlined,
            color: scheme.onSurfaceVariant),
        title: Text(goal.habitTitle),
        subtitle: Text(
          'Waiting for ${goal.partnerProfile?.label ?? '—'} to accept',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        trailing: TextButton(
          onPressed: () async {
            final err = await vm.cancelGoal(goal);
            if (err != null && context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(err)));
            }
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class _ActiveGoalTile extends StatelessWidget {
  const _ActiveGoalTile({required this.goal, required this.vm});
  final JointGoal goal;
  final JointGoalsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final partnerLabel = goal.partnerProfile?.label ?? '—';
    final myHabitId = goal.myHabitId(uid);
    final theirHabitId = goal.theirHabitId(uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration:
          BoxDecoration(border: Border.all(color: scheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    goal.habitTitle,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${goal.daysRemaining}d left',
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (myHabitId != null)
              _ProgressRow(
                label: 'You',
                habitId: myHabitId,
                goal: goal,
                vm: vm,
                scheme: scheme,
                textTheme: textTheme,
              ),
            const SizedBox(height: 8),
            if (theirHabitId != null)
              _ProgressRow(
                label: partnerLabel,
                habitId: theirHabitId,
                goal: goal,
                vm: vm,
                scheme: scheme,
                textTheme: textTheme,
              )
            else
              Text(
                'Waiting for $partnerLabel to accept.',
                style: textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.habitId,
    required this.goal,
    required this.vm,
    required this.scheme,
    required this.textTheme,
  });
  final String label;
  final int habitId;
  final JointGoal goal;
  final JointGoalsViewModel vm;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: vm.countCompletions(habitId, goal.startDate, goal.endDate),
      builder: (context, snap) {
        final count = snap.data ?? 0;
        final total = goal.totalDays;
        final progress = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label,
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const Spacer(),
                Text('$count / $total',
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: scheme.outlineVariant,
              color: scheme.primary,
              minHeight: 2,
            ),
          ],
        );
      },
    );
  }
}

// ─── Add friend dialog ────────────────────────────────────────────────────────

class _AddFriendDialog extends StatefulWidget {
  const _AddFriendDialog({required this.vm});
  final FriendsViewModel vm;

  @override
  State<_AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<_AddFriendDialog> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _controller.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final err = await widget.vm.sendRequestByEmail(email);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _error = err;
        _sending = false;
      });
    } else {
      Navigator.pop(context, email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Add a friend'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Their email address',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(color: scheme.error, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _sending ? null : _submit,
          child: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send request'),
        ),
      ],
    );
  }
}

// ─── Create joint goal dialog ─────────────────────────────────────────────────

class _CreateGoalDialog extends StatefulWidget {
  const _CreateGoalDialog({
    required this.partnerId,
    required this.partnerLabel,
    required this.vm,
  });
  final String partnerId;
  final String partnerLabel;
  final JointGoalsViewModel vm;

  @override
  State<_CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<_CreateGoalDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  HabitRecurrence _recurrence = HabitRecurrence.daily;
  DateTime? _endDate;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Habit name is required.');
      return;
    }
    if (_endDate == null) {
      setState(() => _error = 'End date is required.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final err = await widget.vm.createGoal(
      partnerId: widget.partnerId,
      habitTitle: title,
      habitDescription: _descController.text.trim(),
      habitCategory: _categoryController.text.trim(),
      recurrence: _recurrence,
      startDate: habitDateOnly(DateTime.now()),
      endDate: habitDateOnly(_endDate!),
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _error = err;
        _sending = false;
      });
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final endLabel =
        _endDate == null ? 'Pick a date' : _formatDate(_endDate!);

    return AlertDialog(
      title: Text('Joint goal with ${widget.partnerLabel}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Habit name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HabitRecurrence>(
              value: _recurrence,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: HabitRecurrence.daily, child: Text('Daily')),
                DropdownMenuItem(
                    value: HabitRecurrence.weekly, child: Text('Weekly')),
                DropdownMenuItem(
                    value: HabitRecurrence.monthly, child: Text('Monthly')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _recurrence = v);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickEndDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text('End date: $endLabel'),
            ),
            if (_endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_endDate!.difference(DateTime.now()).inDays + 1} days from today',
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: scheme.error, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _sending ? null : _submit,
          child: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send invite'),
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
