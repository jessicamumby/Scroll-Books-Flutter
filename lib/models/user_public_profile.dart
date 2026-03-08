class UserPublicProfile {
  final String userId;
  final String username;
  final String displayName;
  final bool isPrivate;
  final int followerCount;
  final int followingCount;
  final int streakCount;
  final int badgesEarned;
  final int passagesSaved;

  const UserPublicProfile({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.isPrivate,
    required this.followerCount,
    required this.followingCount,
    required this.streakCount,
    required this.badgesEarned,
    required this.passagesSaved,
  });
}
