# Streak Badge Sharing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Allow users to share earned streak badges as a styled image card from the milestone celebration overlay and from earned badge cards in the Badges tab.

**Architecture:** Follow the established `RepaintBoundary → .toImage() → Share.shareXFiles()` pattern already used for passage and profile sharing. Create a new `StreakBadgeShareCard` widget and `shareStreakBadgeImage()` utility, then wire share buttons into the two existing entry points: `MilestoneCelebrationOverlay` (share in the moment) and `LongevityBadgesList` (reshare later).

**Tech Stack:** Flutter, Dart, `share_plus` (already in pubspec), `path_provider` (already in pubspec), `RepaintBoundary`

---

### Task 1: Create `StreakBadgeShareCard` widget and `shareStreakBadgeImage` utility

**Files:**
- Create: `lib/widgets/streak_badge_share_card.dart`
- Create: `lib/utils/share_streak_badge_image.dart`
- Create: `test/widgets/streak_badge_share_card_test.dart`

**Background:**

`ProfileShareCard` (`lib/widgets/profile_share_card.dart`) is the template for share cards. It's a plain `StatelessWidget` returning a styled `Container` (width 320, cream background, warm shadow). The share utility (`lib/utils/share_profile_image.dart`) captures a `RepaintBoundary` key as a PNG and calls `Share.shareXFiles()`.

`StreakBadgeShareCard` is badge-focused: big emoji, badge name, streak days, `@username · SCROLL BOOKS`. No stats grid needed.

---

**Step 1: Write the failing tests**

Create `test/widgets/streak_badge_share_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/widgets/streak_badge_share_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget _wrap() => MaterialApp(
        home: Scaffold(
          body: const StreakBadgeShareCard(
            username: 'jessreads',
            badgeName: 'Page Turner',
            badgeEmoji: '📖',
            streakDays: 30,
          ),
        ),
      );

  testWidgets('renders badge emoji', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('📖'), findsOneWidget);
  });

  testWidgets('renders badge name', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Page Turner'), findsOneWidget);
  });

  testWidgets('renders streak days text', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('30 day reading streak'), findsOneWidget);
  });

  testWidgets('renders username and brand', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('@jessreads · SCROLL BOOKS'), findsOneWidget);
  });
}
```

**Step 2: Run the tests to verify they fail**

```bash
flutter test test/widgets/streak_badge_share_card_test.dart
```

Expected: FAIL — `Error: 'package:scroll_books/widgets/streak_badge_share_card.dart' not found`

---

**Step 3: Implement `StreakBadgeShareCard`**

Create `lib/widgets/streak_badge_share_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class StreakBadgeShareCard extends StatelessWidget {
  final String username;
  final String badgeName;
  final String badgeEmoji;
  final int streakDays;

  const StreakBadgeShareCard({
    super.key,
    required this.username,
    required this.badgeName,
    required this.badgeEmoji,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.warmShadow(blur: 24, spread: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badgeEmoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            badgeName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$streakDays day reading streak',
            style: GoogleFonts.playfairDisplay(
              fontSize: 14,
              color: AppTheme.inkMid,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '@$username · SCROLL BOOKS',
            style: AppTheme.monoLabel(
              fontSize: 10,
              color: AppTheme.inkLight,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Implement `shareStreakBadgeImage`**

Create `lib/utils/share_streak_badge_image.dart`:

```dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareStreakBadgeImage({
  required GlobalKey repaintKey,
  required String badgeName,
  required String username,
}) async {
  final boundary = repaintKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null) return;

  final image = await boundary.toImage(pixelRatio: 3.0);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) return;

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/streak_badge_card.png');
  await file.writeAsBytes(bytes.buffer.asUint8List());

  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'I earned the $badgeName badge on Scroll Books!',
  );
}
```

**Step 5: Run the tests to verify they pass**

```bash
flutter test test/widgets/streak_badge_share_card_test.dart
```

Expected: 4 tests PASS

**Step 6: Run the full test suite**

```bash
flutter test
```

Expected: same pass count as before + 4 new passing. No new failures.

**Step 7: Commit**

```bash
git add lib/widgets/streak_badge_share_card.dart lib/utils/share_streak_badge_image.dart test/widgets/streak_badge_share_card_test.dart
git commit -m "feat: add StreakBadgeShareCard widget and shareStreakBadgeImage utility"
```

---

### Task 2: Add share button to `MilestoneCelebrationOverlay`

**Files:**
- Modify: `lib/widgets/milestone_celebration_overlay.dart`
- Modify: `test/widgets/milestone_celebration_overlay_test.dart`

**Background:**

`MilestoneCelebrationOverlay` (`lib/widgets/milestone_celebration_overlay.dart`) is a `StatefulWidget` that pops up when a streak milestone is reached. It has a `StatefulWidget` with `_MilestoneCelebrationOverlayState extends State<...> with SingleTickerProviderStateMixin`. The state holds `_controller`, `_scale`, `_opacity`, `_particles`.

The `build()` method structure:
```
GestureDetector(onTap: widget.onDismiss,
  child: Container(color: black54,
    child: Stack(children: [
      ...(confetti particles),
      Center(child: AnimatedBuilder(
        child: Container(width: 260,
          child: Column(children: [emoji, name, subtitle, 'Tap to continue'])))),
    ]),
  ))
```

Plan:
1. Add `String? username` param to `MilestoneCelebrationOverlay`
2. Add `final GlobalKey _shareCardKey = GlobalKey()` field to `_MilestoneCelebrationOverlayState`
3. Add off-screen `StreakBadgeShareCard` inside `RepaintBoundary` to the `Stack.children` (only when `username != null`)
4. Add a share `TextButton.icon` inside the card `Column`, between subtitle and "Tap to continue" (only when `username != null`)

The share button inside the card will NOT propagate taps to the parent `GestureDetector(onTap: onDismiss)` — `TextButton` handles its own tap events, so the overlay stays open after sharing.

The `data` variable (type `_MilestoneData`) is computed at the top of `build()` from `_dataFor(widget.milestone)` — it is in scope everywhere inside `build()`.

Current `MilestoneCelebrationOverlay` constructor (lines 43–47):
```dart
const MilestoneCelebrationOverlay({
  super.key,
  required this.milestone,
  required this.onDismiss,
});
```

Current `build()` Stack children (lines 111–173):
```dart
Stack(
  children: [
    ...(_particles.map((p) => _ParticleWidget(particle: p, animation: _controller))),
    Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => Opacity(
          opacity: _opacity.value,
          child: ScaleTransition(scale: _scale, child: child),
        ),
        child: Container(
          width: 260,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.warmShadow(blur: 32, spread: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(data.emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(data.name, style: GoogleFonts.playfairDisplay(...)),
              const SizedBox(height: 8),
              Text(data.subtitle, style: GoogleFonts.nunito(...)),
              const SizedBox(height: 24),
              Text('Tap to continue', style: AppTheme.monoLabel(...)),
            ],
          ),
        ),
      ),
    ),
  ],
)
```

---

**Step 1: Write the failing tests**

Add to `test/widgets/milestone_celebration_overlay_test.dart`:

First, update the `_wrap` helper to accept `username`:

```dart
Widget _wrap({required int milestone, VoidCallback? onDismiss, String? username}) =>
    MaterialApp(
      home: Scaffold(
        body: MilestoneCelebrationOverlay(
          milestone: milestone,
          onDismiss: onDismiss ?? () {},
          username: username,
        ),
      ),
    );
```

Then add these tests inside the existing `group('MilestoneCelebrationOverlay', ...)`:

```dart
testWidgets('shows share button when username is provided', (tester) async {
  await tester.pumpWidget(_wrap(milestone: 7, username: 'jessreads'));
  await tester.pump();
  expect(find.byIcon(Icons.share), findsOneWidget);
});

testWidgets('no share button when username is null', (tester) async {
  await tester.pumpWidget(_wrap(milestone: 7));
  await tester.pump();
  expect(find.byIcon(Icons.share), findsNothing);
});
```

**Step 2: Run the tests to verify they fail**

```bash
flutter test test/widgets/milestone_celebration_overlay_test.dart --name "share"
```

Expected: FAIL — `The named parameter 'username' isn't defined`

---

**Step 3: Apply the changes to `milestone_celebration_overlay.dart`**

Three changes:

**Change A** — Add `username` param to the widget class (after `onDismiss`):

```dart
// Before:
class MilestoneCelebrationOverlay extends StatefulWidget {
  final int milestone;
  final VoidCallback onDismiss;

  const MilestoneCelebrationOverlay({
    super.key,
    required this.milestone,
    required this.onDismiss,
  });

// After:
class MilestoneCelebrationOverlay extends StatefulWidget {
  final int milestone;
  final VoidCallback onDismiss;
  final String? username;

  const MilestoneCelebrationOverlay({
    super.key,
    required this.milestone,
    required this.onDismiss,
    this.username,
  });
```

**Change B** — Add `_shareCardKey` field to `_MilestoneCelebrationOverlayState`:

```dart
// Add after the existing fields (_controller, _scale, _opacity, _particles, _rng):
final GlobalKey _shareCardKey = GlobalKey();
```

**Change C** — Update `build()` to add the off-screen card and share button.

In the `Stack.children`, add the off-screen card after the confetti particles and before `Center(...)`:

```dart
if (widget.username != null)
  Positioned(
    left: -1000,
    child: RepaintBoundary(
      key: _shareCardKey,
      child: StreakBadgeShareCard(
        username: widget.username!,
        badgeName: data.name,
        badgeEmoji: data.emoji,
        streakDays: widget.milestone,
      ),
    ),
  ),
```

In the card `Column.children`, add the share button between `Text(data.subtitle, ...)` and `const SizedBox(height: 24)`:

```dart
if (widget.username != null) ...[
  const SizedBox(height: 12),
  TextButton.icon(
    onPressed: () async {
      await shareStreakBadgeImage(
        repaintKey: _shareCardKey,
        badgeName: data.name,
        username: widget.username!,
      );
    },
    icon: const Icon(Icons.share, size: 16),
    label: const Text('SHARE'),
  ),
],
```

Add these imports at the top of the file:
```dart
import '../utils/share_streak_badge_image.dart';
import '../widgets/streak_badge_share_card.dart';
```

**Step 4: Run the tests to verify they pass**

```bash
flutter test test/widgets/milestone_celebration_overlay_test.dart
```

Expected: all existing tests PASS + 2 new tests PASS. No failures.

**Step 5: Run the full test suite**

```bash
flutter test
```

Expected: same pass count + 2 new passing. No new failures.

**Step 6: Commit**

```bash
git add lib/widgets/milestone_celebration_overlay.dart test/widgets/milestone_celebration_overlay_test.dart
git commit -m "feat: add share button to MilestoneCelebrationOverlay"
```

---

### Task 3: Add share button to earned badge cards in `LongevityBadgesList`

**Files:**
- Modify: `lib/widgets/longevity_badges_list.dart`
- Modify: `test/widgets/longevity_badges_list_test.dart`

**Background:**

`LongevityBadgesList` is a `StatelessWidget` with one param: `currentStreak`. It renders a `Column` of `_LongevityCard` widgets. `_LongevityCard` is currently a `StatelessWidget`.

Plan:
1. Add `String? username` to `LongevityBadgesList` and pass it down to `_LongevityCard`
2. Convert `_LongevityCard` to `StatefulWidget` — the state holds a `GlobalKey _shareCardKey` for the `RepaintBoundary`
3. Wrap the card's existing `Opacity(child: Container(...))` in a `Stack(clipBehavior: Clip.none)`. Add an off-screen `StreakBadgeShareCard` inside `RepaintBoundary` to the Stack (only when `unlocked && username != null`)
4. Add a share `IconButton` next to the "✓ EARNED" label (only when `unlocked && username != null`)

The `Stack(clipBehavior: Clip.none)` is needed so the off-screen `Positioned(left: -1000)` renders outside the Stack bounds without being clipped. The Stack sizes itself to the non-positioned child (`Opacity`), so no layout changes occur for the visible card.

`_LongevityCard` currently has fields `badge` and `unlocked`. After the change it also has `username`.

---

**Step 1: Write the failing tests**

Add to `test/widgets/longevity_badges_list_test.dart`:

First, update the `_wrap` helper:

```dart
Widget _wrap({required int currentStreak, String? username}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: LongevityBadgesList(
          currentStreak: currentStreak,
          username: username,
        ),
      ),
    ),
  );
}
```

Then add these tests:

```dart
testWidgets('shows share icon on each unlocked badge when username provided', (tester) async {
  await tester.pumpWidget(_wrap(currentStreak: 31, username: 'jessreads'));
  // Week Worm (7) and Page Turner (30) are unlocked
  expect(find.byIcon(Icons.share), findsNWidgets(2));
});

testWidgets('no share icons when username is null', (tester) async {
  await tester.pumpWidget(_wrap(currentStreak: 400));
  expect(find.byIcon(Icons.share), findsNothing);
});

testWidgets('locked badges never show share icon', (tester) async {
  await tester.pumpWidget(_wrap(currentStreak: 31, username: 'jessreads'));
  // Only 2 of 4 unlocked — Bibliophile (90) and Literary Legend (365) are locked
  expect(find.byIcon(Icons.share), findsNWidgets(2));
});
```

**Step 2: Run the tests to verify they fail**

```bash
flutter test test/widgets/longevity_badges_list_test.dart --name "share"
```

Expected: FAIL — `The named parameter 'username' isn't defined`

---

**Step 3: Apply the changes to `longevity_badges_list.dart`**

Replace the entire contents of `lib/widgets/longevity_badges_list.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../utils/share_streak_badge_image.dart';
import '../widgets/streak_badge_share_card.dart';

class _LongevityBadge {
  final int days;
  final String name;
  final String emoji;
  const _LongevityBadge(this.days, this.name, this.emoji);
}

const _badges = [
  _LongevityBadge(7, 'Week Worm', '🐛'),
  _LongevityBadge(30, 'Page Turner', '📖'),
  _LongevityBadge(90, 'Bibliophile', '📚'),
  _LongevityBadge(365, 'Literary Legend', '🏛'),
];

class LongevityBadgesList extends StatelessWidget {
  final int currentStreak;
  final String? username;

  const LongevityBadgesList({
    super.key,
    required this.currentStreak,
    this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LONGEVITY BADGES',
          style: AppTheme.monoLabel(fontSize: 10, color: AppTheme.inkLight),
        ),
        const SizedBox(height: 12),
        ...List.generate(_badges.length, (i) {
          final badge = _badges[i];
          final unlocked = currentStreak >= badge.days;
          return Padding(
            padding: EdgeInsets.only(bottom: i < _badges.length - 1 ? 10 : 0),
            child: _LongevityCard(
              badge: badge,
              unlocked: unlocked,
              username: username,
            ),
          );
        }),
      ],
    );
  }
}

class _LongevityCard extends StatefulWidget {
  final _LongevityBadge badge;
  final bool unlocked;
  final String? username;

  const _LongevityCard({
    required this.badge,
    required this.unlocked,
    this.username,
  });

  @override
  State<_LongevityCard> createState() => _LongevityCardState();
}

class _LongevityCardState extends State<_LongevityCard> {
  final GlobalKey _shareCardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (widget.unlocked && widget.username != null)
          Positioned(
            left: -1000,
            child: RepaintBoundary(
              key: _shareCardKey,
              child: StreakBadgeShareCard(
                username: widget.username!,
                badgeName: widget.badge.name,
                badgeEmoji: widget.badge.emoji,
                streakDays: widget.badge.days,
              ),
            ),
          ),
        Opacity(
          opacity: widget.unlocked ? 1.0 : 0.55,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: widget.unlocked
                  ? const LinearGradient(
                      colors: [AppTheme.amberLight, AppTheme.cream],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.unlocked ? null : AppTheme.cream,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(
                color: widget.unlocked
                    ? AppTheme.amber.withValues(alpha: 0.25)
                    : AppTheme.inkLight.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: widget.unlocked
                        ? const LinearGradient(
                            colors: [AppTheme.amber, AppTheme.warmGold],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: widget.unlocked ? null : AppTheme.parchment,
                  ),
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: widget.unlocked
                          ? const ColorFilter.mode(
                              Colors.transparent, BlendMode.dst)
                          : const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0,      0,      0,      1, 0,
                            ]),
                      child: Text(widget.badge.emoji,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.badge.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.badge.days} day reading streak',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 12,
                          color: AppTheme.inkMid,
                        ),
                      ),
                    ],
                  ),
                ),
                // Earned label + share icon
                if (widget.unlocked) ...[
                  Text(
                    '✓ EARNED',
                    style: AppTheme.monoLabel(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.amber,
                    ),
                  ),
                  if (widget.username != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        await shareStreakBadgeImage(
                          repaintKey: _shareCardKey,
                          badgeName: widget.badge.name,
                          username: widget.username!,
                        );
                      },
                      icon: const Icon(Icons.share, size: 16),
                      color: AppTheme.amber,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Share badge',
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

**Step 4: Run the tests to verify they pass**

```bash
flutter test test/widgets/longevity_badges_list_test.dart
```

Expected: all existing tests PASS + 3 new tests PASS. No failures.

Note: the existing `'locked badges have 0.55 opacity'` test finds `Opacity` widgets via `find.byType(Opacity)`. The `Stack` wrapper does not add any `Opacity` widgets, and `StreakBadgeShareCard` does not contain `Opacity` widgets, so the test still finds exactly 4 `Opacity` widgets at 0.55.

**Step 5: Run the full test suite**

```bash
flutter test
```

Expected: same pass count + 3 new passing. No new failures.

**Step 6: Commit**

```bash
git add lib/widgets/longevity_badges_list.dart test/widgets/longevity_badges_list_test.dart
git commit -m "feat: add share button to earned longevity badge cards"
```

---

### Task 4: Wire `username` into `StreaksScreen`

**Files:**
- Modify: `lib/screens/streaks_screen.dart`

**Background:**

`StreaksScreen.build()` already wraps in `Consumer<AppProvider>` which provides `provider`. `provider.username` is `String?` and is already loaded.

Two one-line changes:

**Change A** — In `_StreaksScreenState.build()`, the overlay is rendered at lines 55–59:

```dart
// Before:
if (provider.pendingMilestone != null)
  MilestoneCelebrationOverlay(
    milestone: provider.pendingMilestone!,
    onDismiss: provider.clearMilestone,
  ),

// After:
if (provider.pendingMilestone != null)
  MilestoneCelebrationOverlay(
    milestone: provider.pendingMilestone!,
    onDismiss: provider.clearMilestone,
    username: provider.username,
  ),
```

**Change B** — In `_BadgesTab.build()`, `LongevityBadgesList` is rendered at lines 184–186:

```dart
// Before:
LongevityBadgesList(currentStreak: streak),

// After:
LongevityBadgesList(currentStreak: streak, username: provider.username),
```

No new test file is needed — this is pure wiring and the widget tests for the overlay and badges list already verify the share button appears when `username` is provided. Run the full suite to confirm no regressions.

---

**Step 1: Apply the two changes**

In `lib/screens/streaks_screen.dart`, apply Change A and Change B as described above.

**Step 2: Run the full test suite**

```bash
flutter test
```

Expected: same total as before Task 4. No new failures.

**Step 3: Commit**

```bash
git add lib/screens/streaks_screen.dart
git commit -m "feat: wire username into streak overlay and badges list for sharing"
```
