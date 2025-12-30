class FriendProfile {
  const FriendProfile({
    required this.id,
    required this.displayName,
    required this.handle,
  });

  final String id;
  final String displayName;
  final String handle;

  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    return FriendProfile(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Friend',
      handle: json['handle'] as String? ?? '',
    );
  }
}
