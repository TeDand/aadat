import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/friends_viewmodel.dart';
import '../../../data/repositories/friend_model.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FriendsViewModel(),
      child: const _FriendsPageBody(),
    );
  }
}

class _FriendsPageBody extends StatelessWidget {
  const _FriendsPageBody();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm = context.watch<FriendsViewModel>();

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
            onPressed: () => _showAddFriendDialog(context),
          ),
        ],
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(vm.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            context.read<FriendsViewModel>().fetchFriendships(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      context.read<FriendsViewModel>().fetchFriendships(),
                  child: _FriendsList(vm: vm),
                ),
    );
  }

  void _showAddFriendDialog(BuildContext context) async {
    final vm = context.read<FriendsViewModel>();
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

class _FriendsList extends StatelessWidget {
  const _FriendsList({required this.vm});
  final FriendsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final friends = vm.friends;
    final incoming = vm.incoming;
    final outgoing = vm.outgoing;

    if (friends.isEmpty && incoming.isEmpty && outgoing.isEmpty) {
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
          _SectionHeader(label: 'Requests', scheme: scheme, textTheme: textTheme),
          for (final f in incoming)
            _IncomingTile(friendship: f, vm: vm),
          const SizedBox(height: 20),
        ],
        if (outgoing.isNotEmpty) ...[
          _SectionHeader(label: 'Sent', scheme: scheme, textTheme: textTheme),
          for (final f in outgoing)
            _OutgoingTile(friendship: f, vm: vm),
          const SizedBox(height: 20),
        ],
        if (friends.isNotEmpty) ...[
          _SectionHeader(label: 'Friends', scheme: scheme, textTheme: textTheme),
          for (final f in friends)
            _FriendTile(friendship: f, vm: vm),
        ],
      ],
    );
  }
}

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
        style: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friendship, required this.vm});
  final Friendship friendship;
  final FriendsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = friendship.otherProfile;
    final label = profile?.label ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(label),
        subtitle: (profile?.displayName?.isNotEmpty == true)
            ? Text(profile!.email,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))
            : null,
        trailing: IconButton(
          icon: Icon(Icons.person_remove_outlined, color: scheme.onSurfaceVariant, size: 18),
          tooltip: 'Unfriend',
          onPressed: () => _confirmRemove(context),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove friend?'),
        content: Text('Remove ${friendship.otherProfile?.label ?? 'this person'} from your friends?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (go == true && context.mounted) {
      final err = await vm.removeFriendship(friendship.id);
      if (err != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
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
      decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant)),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
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
      decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant)),
      child: ListTile(
        leading: Icon(Icons.hourglass_empty_outlined, color: scheme.onSurfaceVariant),
        title: Text(label),
        subtitle: Text('Request pending',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        trailing: TextButton(
          onPressed: () async {
            final err = await vm.removeFriendship(friendship.id);
            if (err != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
            }
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

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
      Navigator.pop(context, email); // return email so parent can show snackbar
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
            Text(
              _error!,
              style: TextStyle(color: scheme.error, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
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
