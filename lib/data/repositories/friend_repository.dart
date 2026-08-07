import 'package:supabase_flutter/supabase_flutter.dart';
import 'friend_model.dart';

class FriendRepository {
  SupabaseClient get _db => Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;

  /// Look up a user by email. Returns null if not found or if it's the current user.
  Future<FriendProfile?> findByEmail(String email) async {
    final rows = await _db
        .from('profiles')
        .select()
        .eq('email', email.trim().toLowerCase())
        .limit(1);
    if (rows.isEmpty) return null;
    final profile = FriendProfile.fromJson(rows.first);
    if (profile.id == _uid) return null; // can't add yourself
    return profile;
  }

  /// Fetch all friendships (pending + accepted) for the current user,
  /// with the other person's profile joined.
  Future<List<Friendship>> fetchFriendships() async {
    final rows = await _db.from('friendships').select('''
      id,
      requester_id,
      addressee_id,
      status,
      requester_profile:profiles!friendships_requester_id_fkey (id, email, display_name),
      addressee_profile:profiles!friendships_addressee_id_fkey (id, email, display_name)
    ''').or('requester_id.eq.$_uid,addressee_id.eq.$_uid');

    return (rows as List)
        .map((r) => Friendship.fromJson(r as Map<String, dynamic>, _uid))
        .toList();
  }

  /// Send a friend request to [addresseeId].
  Future<void> sendRequest(String addresseeId) async {
    await _db.from('friendships').insert({
      'requester_id': _uid,
      'addressee_id': addresseeId,
      'status': 'pending',
    });
  }

  /// Accept an incoming request (current user must be the addressee).
  Future<void> acceptRequest(int friendshipId) async {
    await _db
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('id', friendshipId)
        .eq('addressee_id', _uid);
  }

  /// Decline or cancel a request / unfriend.
  Future<void> deleteFriendship(int friendshipId) async {
    await _db.from('friendships').delete().eq('id', friendshipId);
  }

  /// Whether a friendship (in any direction/status) already exists with [otherId].
  Future<bool> friendshipExists(String otherId) async {
    final rows = await _db
        .from('friendships')
        .select('id')
        .or('and(requester_id.eq.$_uid,addressee_id.eq.$otherId),and(requester_id.eq.$otherId,addressee_id.eq.$_uid)')
        .limit(1);
    return (rows as List).isNotEmpty;
  }
}
