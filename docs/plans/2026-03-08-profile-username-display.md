# Profile Username Display Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the email address on the profile screen with `@username`, and move the share profile icon from the AppBar into a row next to the username.

**Architecture:** Single-file change in `lib/screens/profile_screen.dart`. The `provider.username` field is already loaded from the `profiles` Supabase table by `AppProvider` — no data-layer changes needed. The `_currentEmail()` method and `supabase_flutter` import are removed as dead code. The AppBar share `IconButton` is removed and a compact `Icons.share` button is added inline in the user info row.

**Tech Stack:** Flutter, Dart, `flutter_test`, `provider`

---

### Task 1: Show `@username` and move share icon into the user info row

**Files:**
- Modify: `lib/screens/profile_screen.dart`
- Modify: `test/screens/profile_screen_test.dart`

**Background:**

`ProfileScreen` currently has:

- `_currentEmail()` getter (lines 32–38) — reads `supabase.auth.currentUser?.email`; used only to show email under the AppBar
- `final email = _currentEmail();` in `build()` (line 104)
- A `Text(email, ...)` sliver in the user info section (lines 133–142)
- A share `IconButton` in `AppBar` actions (lines 113–118)
- A settings gear `IconButton` in `AppBar` actions (lines 120–123)

The `import 'package:supabase_flutter/supabase_flutter.dart';` (line 5) exists only to support `_currentEmail()` — `supabase_client.dart` already imports it for the `_userId` getter.

`AppProvider.username` is a `String?` loaded from `profiles.username` in `fetchAll`. It is the user's public `@handle` (e.g. `jessreads`) without the `@` prefix. All current users have one — username is mandatory during signup.

---

**Step 1: Write the failing tests**

Open `test/screens/profile_screen_test.dart`. The `_provider()` factory at the top creates an `AppProvider` directly — you can set `provider.username` on it before passing it to `_wrap()`.

Inside the existing `group('ProfileScreen', () { ... })` block, add these three tests **before** the closing `});`:

```dart
testWidgets('shows @username in user info row when username is set',
    (tester) async {
  final provider = _provider();
  provider.username = 'jessreads';
  await tester.pumpWidget(_wrap(provider: provider));
  expect(find.text('@jessreads'), findsOneWidget);
});

testWidgets('share icon is visible when username is set',
    (tester) async {
  final provider = _provider();
  provider.username = 'jessreads';
  await tester.pumpWidget(_wrap(provider: provider));
  expect(find.byIcon(Icons.share), findsOneWidget);
});

testWidgets('no email address text is rendered on the profile screen',
    (tester) async {
  final provider = _provider();
  provider.username = 'jessreads';
  await tester.pumpWidget(_wrap(provider: provider));
  // Username shows as @handle, not as email
  expect(find.text('@jessreads'), findsOneWidget);
  // No text containing '@' followed by a domain appears
  final emailTexts = find.byWidgetPredicate((widget) =>
      widget is Text &&
      widget.data != null &&
      widget.data!.contains('@') &&
      widget.data!.contains('.'));
  expect(emailTexts, findsNothing,
      reason: 'Email address must not be rendered on the profile screen');
});
```

**Step 2: Run the failing tests**

```bash
flutter test test/screens/profile_screen_test.dart --name "shows @username|share icon is visible|no email address"
```

Expected: all three FAIL — `@jessreads` not found, `Icons.share` not found (it's in AppBar currently and the test shape will differ), email check may pass or fail depending on test environment.

---

**Step 3: Apply the fix**

Replace the entire contents of `lib/screens/profile_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/supabase_client.dart';
import '../data/catalogue.dart';
import '../models/saved_passage.dart';
import '../providers/app_provider.dart';
import '../utils/share_passage_image.dart';
import '../utils/share_profile_image.dart';
import '../utils/streak_calculator.dart';
import '../widgets/reader/passage_share_card.dart';
import '../widgets/profile_share_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  final GlobalKey _profileShareCardKey = GlobalKey();
  String _shareCardText = '';
  String _shareCardTitle = '';
  String _shareCardAuthor = '';
  String _shareCardPageLabel = '';

  String? get _userId {
    try {
      return supabase.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _sharePassage(SavedPassage passage) async {
    final book = getBookById(passage.bookId);
    final title = book?.title ?? passage.bookId;
    final author = book?.author ?? '';
    final provider = Provider.of<AppProvider>(context, listen: false);
    final totalChunks = provider.bookTotalChunks[passage.bookId];
    final page = passage.chunkIndex + 1;
    final pct = (totalChunks != null && totalChunks > 0)
        ? ((page) / totalChunks * 100).round()
        : 0;

    setState(() {
      _shareCardText = passage.passageText;
      _shareCardTitle = title;
      _shareCardAuthor = author;
      _shareCardPageLabel = 'p. $page · $pct%';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await sharePassageImage(
          repaintKey: _shareCardKey,
          bookTitle: title,
          author: author,
        );
      } catch (e, st) {
        debugPrint('Share passage error: $e\n$st');
      }
    });
  }

  Future<void> _shareProfile() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final username = provider.username ?? '';
    if (username.isEmpty) return;
    try {
      await shareProfileImage(
        repaintKey: _profileShareCardKey,
        username: username,
      );
    } catch (e, st) {
      debugPrint('Share profile error: $e\n$st');
    }
  }

  int _countBadges(AppProvider provider) {
    final streak = calculateStreak(provider.readDays, frozenDays: provider.frozenDays);
    int count = 0;
    for (final days in [7, 30, 90, 365]) {
      if (streak >= days) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.page,
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                onPressed: () => context.push('/app/profile/settings'),
                icon: const Text('⚙️', style: TextStyle(fontSize: 24)),
              ),
            ],
          ),
          body: Consumer<AppProvider>(
            builder: (context, provider, _) {
              final passages = provider.savedPassages;

              return CustomScrollView(
                slivers: [
                  // User info row: @username + share button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
                      child: Row(
                        children: [
                          if (provider.username != null)
                            Text(
                              '@${provider.username}',
                              style: TextStyle(
                                  color: AppTheme.tobacco, fontSize: 15),
                            ),
                          const Spacer(),
                          IconButton(
                            onPressed:
                                provider.username != null ? _shareProfile : null,
                            icon: const Icon(Icons.share, size: 18),
                            tooltip: 'Share profile',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Section header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                      child: Row(
                        children: [
                          Text(
                            'Saved Passages',
                            style: GoogleFonts.lora(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (passages.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.brandPale,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${passages.length}',
                                style: GoogleFonts.dmMono(
                                  fontSize: 12,
                                  color: AppTheme.brand,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Passages list or empty state
                  if (passages.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 48),
                        child: Column(
                          children: [
                            Icon(Icons.bookmark_border,
                                size: 48, color: AppTheme.fog),
                            const SizedBox(height: 12),
                            Text(
                              'No saved passages yet',
                              style: GoogleFonts.lora(
                                fontSize: 16,
                                color: AppTheme.pewter,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Long press any passage while reading to save it',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: AppTheme.tobacco,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, index) {
                          final passage = passages[index];
                          return _SavedPassageCard(
                            passage: passage,
                            totalChunks:
                                provider.bookTotalChunks[passage.bookId],
                            onDelete: () {
                              final userId = _userId;
                              if (userId != null) {
                                provider.deleteSavedPassage(
                                    userId, passage.id);
                              }
                            },
                            onShare: () => _sharePassage(passage),
                          );
                        },
                        childCount: passages.length,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        // Hidden passage share card for PNG generation
        Positioned(
          left: -1000,
          top: -1000,
          child: RepaintBoundary(
            key: _shareCardKey,
            child: PassageShareCard(
              passageText: _shareCardText,
              bookTitle: _shareCardTitle,
              author: _shareCardAuthor,
              pageLabel: _shareCardPageLabel,
            ),
          ),
        ),
        // Hidden profile share card for PNG generation
        Consumer<AppProvider>(
          builder: (context, provider, _) {
            if (provider.username == null) return const SizedBox.shrink();
            final streak = calculateStreak(
              provider.readDays,
              frozenDays: provider.frozenDays,
            );
            final badgesEarned = _countBadges(provider);
            return Positioned(
              left: -1000,
              top: -1000,
              child: RepaintBoundary(
                key: _profileShareCardKey,
                child: ProfileShareCard(
                  username: provider.username!,
                  streakCount: streak,
                  badgesEarned: badgesEarned,
                  passagesSaved: provider.savedPassages.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SavedPassageCard extends StatefulWidget {
  final SavedPassage passage;
  final int? totalChunks;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _SavedPassageCard({
    required this.passage,
    required this.totalChunks,
    required this.onDelete,
    required this.onShare,
  });

  @override
  State<_SavedPassageCard> createState() => _SavedPassageCardState();
}

class _SavedPassageCardState extends State<_SavedPassageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late Animation<double> _offsetAnimation;
  double _dragOffset = 0; // negative = left (delete), positive = right (share)
  bool _animating = false;

  static const double _actionWidth = 80.0;

  String get _percentage {
    if (widget.totalChunks == null || widget.totalChunks == 0) return '';
    return '${((widget.passage.chunkIndex + 1) / widget.totalChunks! * 100).round()}%';
  }

  String get _formattedDate {
    final d = widget.passage.savedAt;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _offsetAnimation = const AlwaysStoppedAnimation(0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_animating) return;
    setState(() {
      _dragOffset = (_dragOffset + (details.primaryDelta ?? 0))
          .clamp(-_actionWidth, _actionWidth);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_animating) return;
    final velocity = details.primaryVelocity ?? 0;

    double target;
    if (_dragOffset < 0) {
      target = (velocity < -200 || _dragOffset < -_actionWidth * 0.4)
          ? -_actionWidth
          : 0;
    } else {
      target = (velocity > 200 || _dragOffset > _actionWidth * 0.4)
          ? _actionWidth
          : 0;
    }

    _snapTo(target);
  }

  void _snapTo(double target, {Duration? duration, VoidCallback? onComplete}) {
    _animating = true;
    _animController.duration = duration ?? const Duration(milliseconds: 200);
    _offsetAnimation = Tween<double>(begin: _dragOffset, end: target)
        .animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    void listener() {
      setState(() {
        _dragOffset = _offsetAnimation.value;
      });
    }

    _animController.reset();
    _offsetAnimation.addListener(listener);
    _animController.forward().then((_) {
      _offsetAnimation.removeListener(listener);
      _animating = false;
      onComplete?.call();
    });
  }

  void _close() {
    _snapTo(0);
  }

  void _confirmDelete() {
    final screenWidth = MediaQuery.of(context).size.width;
    _snapTo(
      -screenWidth,
      onComplete: () {
        if (mounted) widget.onDelete();
      },
    );
  }

  void _triggerShare() {
    widget.onShare();
    _close();
  }

  bool get _isRevealed => _dragOffset.abs() > 1;

  @override
  Widget build(BuildContext context) {
    final book = getBookById(widget.passage.bookId);
    final title = book?.title ?? widget.passage.bookId;
    final author = book?.author ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: SizedBox(
          height: null, // intrinsic height from card content
          child: Stack(
            children: [
              // Background actions
              Positioned.fill(
                child: Row(
                  children: [
                    // Share button (left side, revealed by swiping right)
                    GestureDetector(
                      onTap: _triggerShare,
                      child: Container(
                        width: _actionWidth,
                        color: AppTheme.brand,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.ios_share,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Delete button (right side, revealed by swiping left)
                    GestureDetector(
                      onTap: _confirmDelete,
                      child: Container(
                        width: _actionWidth,
                        color: const Color(0xFFDC3545),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Slideable card
              Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: GestureDetector(
                  onHorizontalDragUpdate: _onHorizontalDragUpdate,
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  onTap: _isRevealed ? _close : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.cardRadius),
                      border:
                          Border.all(color: AppTheme.brandPale, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.passage.passageText,
                          style: GoogleFonts.lora(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.ink,
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  if (author.isNotEmpty)
                                    Text(
                                      author,
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        color: AppTheme.tobacco,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_percentage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  _percentage,
                                  style: GoogleFonts.dmMono(
                                    fontSize: 12,
                                    color: AppTheme.tobacco,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formattedDate,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: AppTheme.fog,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

What changed vs the original:
- Removed `import 'package:supabase_flutter/supabase_flutter.dart';`
- Removed `_currentEmail()` method
- Removed `final email = _currentEmail();` from `build()`
- Removed share `IconButton` from `AppBar` actions
- Replaced `Text(email, ...)` sliver with a `Row` containing `Text('@${provider.username}')` and `IconButton(Icons.share, ...)`

**Step 4: Run the new tests to verify they pass**

```bash
flutter test test/screens/profile_screen_test.dart --name "shows @username|share icon is visible|no email address"
```

Expected: all three PASS.

**Step 5: Run the full test suite**

```bash
flutter test
```

Expected: same pass count as before (315 passing, 10 pre-existing failures in library/book-detail/public-profile screen tests). The three new tests should PASS. No new failures.

Note: the existing `'shows email text widget'` test (`find.byType(Text), findsWidgets`) will continue to pass since there are still `Text` widgets in the tree.

**Step 6: Commit**

```bash
git add lib/screens/profile_screen.dart test/screens/profile_screen_test.dart
git commit -m "feat: show @username and inline share button on profile screen"
```
