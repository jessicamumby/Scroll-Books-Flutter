import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../models/user_public_profile.dart';
import '../services/user_data_service.dart';
import '../utils/streak_tier.dart';

class PublicProfileScreen extends StatefulWidget {
  final String username;
  const PublicProfileScreen({super.key, required this.username});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  UserPublicProfile? _profile;
  bool _loading = true;
  bool _isFollowing = false;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await UserDataService.fetchPublicProfile(widget.username);
      if (!mounted) return;

      bool following = false;
      final myId = Supabase.instance.client.auth.currentUser?.id;
      if (profile != null && myId != null && !profile.isPrivate) {
        following = await UserDataService.isFollowing(myId, profile.userId);
      }

      setState(() {
        _profile = profile;
        _isFollowing = following;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null) return;
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) return;

    setState(() => _followLoading = true);
    try {
      if (_isFollowing) {
        await UserDataService.unfollowUser(myId, profile.userId);
        setState(() => _isFollowing = false);
      } else {
        await UserDataService.followUser(myId, profile.userId);
        setState(() => _isFollowing = true);
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.page,
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? Center(
                  child: Text(
                    'Profile not found',
                    style: GoogleFonts.lora(
                        fontSize: 16, color: AppTheme.inkMid),
                  ),
                )
              : _profile!.isPrivate
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔒',
                              style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text(
                            'This profile is private',
                            style: GoogleFonts.lora(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _ProfileContent(
                      profile: _profile!,
                      isFollowing: _isFollowing,
                      followLoading: _followLoading,
                      onToggleFollow: _toggleFollow,
                    ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final UserPublicProfile profile;
  final bool isFollowing;
  final bool followLoading;
  final VoidCallback onToggleFollow;

  const _ProfileContent({
    required this.profile,
    required this.isFollowing,
    required this.followLoading,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    final tierEmoji = streakTierEmoji(profile.streakCount);
    final myId = Supabase.instance.client.auth.currentUser?.id;
    final isSelf = myId == profile.userId;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tierEmoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${profile.username}',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  if (profile.displayName.isNotEmpty)
                    Text(
                      profile.displayName,
                      style: GoogleFonts.nunito(
                          fontSize: 14, color: AppTheme.tobacco),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatTile(label: 'STREAK', value: '${profile.streakCount} days'),
              _StatTile(label: 'FOLLOWERS', value: '${profile.followerCount}'),
              _StatTile(label: 'FOLLOWING', value: '${profile.followingCount}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatTile(label: 'PASSAGES', value: '${profile.passagesSaved}'),
            ],
          ),
          const SizedBox(height: 24),
          if (!isSelf)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: followLoading ? null : onToggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isFollowing ? AppTheme.parchment : AppTheme.brand,
                  foregroundColor:
                      isFollowing ? AppTheme.ink : Colors.white,
                ),
                child: followLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isFollowing ? 'Following' : 'Follow'),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        Text(
          label,
          style: AppTheme.monoLabel(
            fontSize: 10,
            color: AppTheme.inkLight,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
