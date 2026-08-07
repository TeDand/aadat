import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/friend_model.dart';
import '../../../data/repositories/friend_repository.dart';

class FriendsViewModel extends ChangeNotifier {
  final _repo = FriendRepository();

  List<Friendship> _all = [];
  bool _loading = false;
  String? _error;

  String get _uid => Supabase.instance.client.auth.currentUser!.id;

  List<Friendship> get friends =>
      _all.where((f) => f.status == FriendshipStatus.accepted).toList();

  List<Friendship> get incoming => _all
      .where((f) =>
          f.status == FriendshipStatus.pending && f.isAddressee(_uid))
      .toList();

  List<Friendship> get outgoing => _all
      .where((f) =>
          f.status == FriendshipStatus.pending && f.isRequester(_uid))
      .toList();

  bool get loading => _loading;
  String? get error => _error;

  FriendsViewModel() {
    fetchFriendships();
  }

  Future<void> fetchFriendships() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _all = await _repo.fetchFriendships();
    } catch (e) {
      _error = 'Could not load friends. Check your connection.';
    }
    _loading = false;
    notifyListeners();
  }

  /// Searches for a user by [email] and sends a request.
  /// Returns an error string on failure, null on success.
  Future<String?> sendRequestByEmail(String email) async {
    try {
      final profile = await _repo.findByEmail(email);
      if (profile == null) return 'No account found for $email.';
      final exists = await _repo.friendshipExists(profile.id);
      if (exists) return 'A request or friendship with this person already exists.';
      await _repo.sendRequest(profile.id);
      await fetchFriendships();
      return null;
    } catch (e) {
      return 'Could not send request. Try again.';
    }
  }

  Future<String?> acceptRequest(int friendshipId) async {
    try {
      await _repo.acceptRequest(friendshipId);
      await fetchFriendships();
      return null;
    } catch (e) {
      return 'Could not accept. Try again.';
    }
  }

  Future<String?> removeFriendship(int friendshipId) async {
    try {
      await _repo.deleteFriendship(friendshipId);
      await fetchFriendships();
      return null;
    } catch (e) {
      return 'Could not remove. Try again.';
    }
  }
}
