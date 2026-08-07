class FriendProfile {
  const FriendProfile({
    required this.id,
    required this.email,
    this.displayName,
  });

  final String id;
  final String email;
  final String? displayName;

  String get label =>
      (displayName != null && displayName!.isNotEmpty) ? displayName! : email;

  factory FriendProfile.fromJson(Map<String, dynamic> json) => FriendProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['display_name'] as String?,
      );
}

enum FriendshipStatus { pending, accepted }

class Friendship {
  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    this.otherProfile,
  });

  final int id;
  final String requesterId;
  final String addresseeId;
  final FriendshipStatus status;
  final FriendProfile? otherProfile;

  bool isRequester(String userId) => requesterId == userId;
  bool isAddressee(String userId) => addresseeId == userId;

  factory Friendship.fromJson(Map<String, dynamic> json, String currentUserId) {
    final status = json['status'] == 'accepted'
        ? FriendshipStatus.accepted
        : FriendshipStatus.pending;

    final requesterId = json['requester_id'] as String;
    final addresseeId = json['addressee_id'] as String;

    // Attach the *other* person's profile.
    final isRequester = requesterId == currentUserId;
    final profileJson = isRequester
        ? json['addressee_profile'] as Map<String, dynamic>?
        : json['requester_profile'] as Map<String, dynamic>?;

    return Friendship(
      id: json['id'] as int,
      requesterId: requesterId,
      addresseeId: addresseeId,
      status: status,
      otherProfile: profileJson != null ? FriendProfile.fromJson(profileJson) : null,
    );
  }
}
