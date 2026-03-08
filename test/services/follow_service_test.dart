import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_books/models/user_public_profile.dart';

void main() {
  group('UserPublicProfile', () {
    test('holds all fields', () {
      const profile = UserPublicProfile(
        userId: 'abc',
        username: 'jessreads',
        displayName: 'Jessica',
        isPrivate: false,
        followerCount: 10,
        followingCount: 5,
        streakCount: 7,
        badgesEarned: 3,
        passagesSaved: 12,
      );
      expect(profile.username, 'jessreads');
      expect(profile.followerCount, 10);
      expect(profile.isPrivate, isFalse);
    });
  });
}
