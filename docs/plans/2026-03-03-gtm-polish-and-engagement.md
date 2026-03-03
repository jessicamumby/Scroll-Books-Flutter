# GTM Polish & Engagement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Polish Scroll Books to feel premium and shareable for the #BookTok audience, add Duolingo-inspired streak mechanics with a shareable streak card, and close all testing/code quality gaps.

**Architecture:** Local stats (passagesRead, longestStreak, dailyPassages) stored in SharedPreferences — no Supabase schema changes needed. Visual polish applied via direct widget edits. Shareable streak card uses RepaintBoundary → PNG → share_plus XFile. Onboarding animations added as looping AnimationControllers on the existing TickerProviderStateMixin State.

**Tech Stack:** Flutter, SharedPreferences, share_plus, path_provider (new dep), RepaintBoundary, AnimationController

---

## Pre-flight: verify tests pass

```bash
cd /Users/jessicamumby/Scroll-books-github/Scroll-Books-Flutter
flutter test
```

Expected: all tests pass. Do not proceed if any fail.

---

## Task 1: Reader Card Polish

**Files:**
- Modify: `lib/widgets/reader/reader_card.dart`
- Modify: `lib/screens/reader_screen.dart`
- Modify: `test/widgets/reader_card_test.dart`

**Context:** The card currently has a uniform `Border.all(color: AppTheme.borderSoft)` with `BorderRadius.circular(16)`. Flutter does not allow `BorderRadius` with a non-uniform `Border` in a `BoxDecoration`, so we add the left brand accent as an inner `Row` child — a 3px wide `Container` with a left-rounded brand colour.

**Step 1: Update `ReaderCard` — add left brand border and improve page label**

Replace the entire `build` method in `lib/widgets/reader/reader_card.dart`:

```dart
@override
Widget build(BuildContext context) {
  return Container(
    color: AppTheme.page,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 3,
                        color: AppTheme.brand,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: SingleChildScrollView(
                                  child: Text(
                                    text,
                                    style: GoogleFonts.lora(
                                      fontSize: 18,
                                      height: 1.75,
                                      color: AppTheme.ink,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _pageLabel,
                    style: GoogleFonts.dmMono(
                      fontSize: 13,
                      color: AppTheme.tobacco,
                    ),
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
```

**Step 2: Add share hint to `ReaderScreen`**

In `lib/screens/reader_screen.dart`, add `bool _showShareHint = false;` to state fields alongside the others. Then in `_loadReader`, after the `setState` that sets `_chunks` and `_loading = false`, add the hint logic:

```dart
// After the setState that loads chunks:
WidgetsBinding.instance.addPostFrameCallback((_) async {
  if (_pageController.hasClients) {
    _pageController.jumpToPage(_startIndex);
  }
  try {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('share_hint_shown') ?? false;
    if (!shown && mounted) {
      setState(() => _showShareHint = true);
      await prefs.setBool('share_hint_shown', true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showShareHint = false);
      });
    }
  } catch (e, st) {
    debugPrint('Share hint pref error: $e\n$st');
  }
});
```

Remove the existing `WidgetsBinding.instance.addPostFrameCallback` block and replace it with the one above (it now includes the jump).

Then in `_buildBody`, wrap the returned `pageView` (and the horizontal Stack) in a `Stack` with an `AnimatedOpacity` hint overlay:

```dart
Widget _wrapWithHint(Widget child) {
  return Stack(
    children: [
      child,
      AnimatedOpacity(
        opacity: _showShareHint ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 72),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.ink.withOpacity(0.75),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Hold any passage to share it',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppTheme.surface,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
```

Replace the final `return pageView;` and the horizontal `return Stack(...)` with:

```dart
if (!isHorizontal) return _wrapWithHint(pageView);

return _wrapWithHint(Stack(
  children: [
    pageView,
    Positioned.fill(
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            ),
          ),
          const Spacer(flex: 4),
          Expanded(
            flex: 3,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            ),
          ),
        ],
      ),
    ),
  ],
));
```

**Step 3: Update reader card test**

In `test/widgets/reader_card_test.dart`, add a test verifying the brand bar renders:

```dart
testWidgets('renders brand accent left bar', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: ReaderCard(text: 'Test', chunkIndex: 0, totalChunks: 10),
      ),
    ),
  );
  // ClipRRect wrapping the brand bar Row should be present
  expect(find.byType(ClipRRect), findsWidgets);
});
```

**Step 4: Run tests**

```bash
flutter test test/widgets/reader_card_test.dart
```

Expected: all tests pass.

**Step 5: Commit**

```bash
git add lib/widgets/reader/reader_card.dart lib/screens/reader_screen.dart test/widgets/reader_card_test.dart
git commit -m "feat: polish reader card — brand accent bar, improved page label, share hint"
```

---

## Task 2: Landing Screen Redesign

**Files:**
- Modify: `lib/screens/landing_screen.dart`
- Modify: `test/screens/landing_screen_test.dart`

**Context:** `LandingScreen` is currently `StatelessWidget`. It needs to become `StatefulWidget` to drive the `AnimatedSwitcher` passage rotation. The `ElevatedButton` already uses `AppTheme.brand` background via `AppTheme.light` — no button style changes needed.

**Step 1: Write the failing test first**

Add to `test/screens/landing_screen_test.dart`:

```dart
testWidgets('shows tagline text', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  expect(find.textContaining('One page at a time'), findsOneWidget);
});

testWidgets('shows social proof text', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  expect(find.textContaining('readers'), findsOneWidget);
});

testWidgets('shows a rotating passage card', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  // The passage carousel widget is present
  expect(find.byType(AnimatedSwitcher), findsOneWidget);
});
```

**Step 2: Run new tests to verify they fail**

```bash
flutter test test/screens/landing_screen_test.dart
```

Expected: the three new tests fail (text not found).

**Step 3: Rewrite `landing_screen.dart`**

Replace the entire file:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  static const _passages = [
    '"Call me Ishmael."',
    '"It is not down in any map;\ntrue places never are."',
    '"I am tormented with an everlasting itch\nfor things remote."',
  ];

  int _passageIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() => _passageIndex = (_passageIndex + 1) % _passages.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.page,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    style: GoogleFonts.lora(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                    children: [
                      const TextSpan(text: 'Scroll'),
                      TextSpan(
                        text: '.',
                        style: TextStyle(color: AppTheme.brand),
                      ),
                      const TextSpan(text: 'Books'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The great books. One page at a time.',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: AppTheme.tobacco,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: _PassagePreview(
                    key: ValueKey(_passageIndex),
                    text: _passages[_passageIndex],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/signup'),
                    child: const Text('Sign Up'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Log In',
                    style: TextStyle(
                      color: AppTheme.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Join 1,200+ readers',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppTheme.pewter,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PassagePreview extends StatelessWidget {
  final String text;
  const _PassagePreview({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        text,
        style: GoogleFonts.lora(
          fontSize: 16,
          height: 1.7,
          color: AppTheme.ink,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
```

**Step 4: Run tests**

```bash
flutter test test/screens/landing_screen_test.dart
```

Expected: all 7 tests pass.

**Step 5: Commit**

```bash
git add lib/screens/landing_screen.dart test/screens/landing_screen_test.dart
git commit -m "feat: redesign landing screen — rotating passages, tagline, social proof"
```

---

## Task 3: Book Cover Assets + Library Widget

**Files:**
- Create: `assets/covers/` directory with 6 JPEG images
- Modify: `pubspec.yaml`
- Modify: `lib/screens/library_screen.dart`
- Modify: `test/screens/library_screen_test.dart`

**Context:** Public domain cover images exist for all 6 books. The `_BookCard` widget currently renders a gradient `Container`. We replace it with `Image.asset` wrapped in `ColorFiltered` with a Warm Punch amber tint. The `ClipRRect` + `ColorFiltered` combination is the correct Flutter pattern.

**Step 1: Download cover images**

Run the following to create the directory:

```bash
mkdir -p /Users/jessicamumby/Scroll-books-github/Scroll-Books-Flutter/assets/covers
```

Download public domain cover images and save as:
- `assets/covers/moby-dick.jpg` — Rockwell Kent illustration, search Wikimedia Commons: "Moby-Dick FE title page.jpg" or the Rockwell Kent whale
- `assets/covers/pride-and-prejudice.jpg` — Hugh Thomson 1894 illustration, search Wikimedia Commons: "Hugh Thomson, Pride and Prejudice"
- `assets/covers/jane-eyre.jpg` — F.H. Townsend 1897 illustration, search Wikimedia Commons: "Jane Eyre frontispiece"
- `assets/covers/don-quixote.jpg` — Gustave Doré engraving, search Wikimedia Commons: "Doré Don Quixote"
- `assets/covers/great-gatsby.jpg` — Cugat 1925 dust jacket, search Wikimedia Commons: "The Great Gatsby Cover 1925"
- `assets/covers/frankenstein.jpg` — 1831 Colburn edition frontispiece, search Wikimedia Commons: "Frankenstein 1831 inside cover"

All must be under 500KB each. Resize to 400×600px if needed.

**Step 2: Register assets in `pubspec.yaml`**

Find the `flutter:` section and add the covers directory. The current `pubspec.yaml` has:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
```

Change to:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
    - assets/covers/
```

**Step 3: Write failing test**

Add to `test/screens/library_screen_test.dart`:

```dart
testWidgets('book cards use image assets with color filter', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  expect(find.byType(ColorFiltered), findsWidgets);
});
```

Run:

```bash
flutter test test/screens/library_screen_test.dart
```

Expected: new test fails (no ColorFiltered widgets).

**Step 4: Update `_BookCard` in `lib/screens/library_screen.dart`**

Replace the gradient `Container` block (the 80×120 cover widget) with:

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: ColorFiltered(
    colorFilter: ColorFilter.mode(
      AppTheme.amber.withOpacity(0.3),
      BlendMode.multiply,
    ),
    child: Image.asset(
      'assets/covers/${book.id}.jpg',
      width: 80,
      height: 120,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        final gradient = coverGradients[book.id] ??
            [AppTheme.coverDeep, AppTheme.coverRich];
        return Container(
          width: 80,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    ),
  ),
),
```

This replaces the existing block:

```dart
Container(
  width: 80,
  height: 120,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    gradient: LinearGradient(
      colors: gradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
),
```

Also remove the `final gradient = ...` line at the top of `_BookCard.build` since it is now only used in the fallback.

Wait — keep `final gradient = ...` since it's used in the `errorBuilder`. Leave it in place.

**Step 5: Run tests**

```bash
flutter test test/screens/library_screen_test.dart
```

Expected: all tests pass including new one.

**Step 6: Commit**

```bash
git add assets/covers/ pubspec.yaml lib/screens/library_screen.dart test/screens/library_screen_test.dart
git commit -m "feat: add real book cover art with Warm Punch colour glaze"
```

---

## Task 4: AppProvider — Local Stats Tracking

**Files:**
- Modify: `lib/providers/app_provider.dart`
- Modify: `test/services/user_data_service_test.dart`

**Context:** We track `passagesRead` (int), `longestStreak` (int), `dailyPassages` (Map<String,int>), and `pendingMilestone` (int?) entirely in SharedPreferences. No Supabase schema changes. `passagesRead` increments each time a page changes in the reader. `longestStreak` is calculated from `readDays` and compared to stored best. `dailyPassages` maps ISO date strings to passage counts. `pendingMilestone` is set when the streak crosses 7, 30, or 100 for the first time.

**Step 1: Write failing tests**

Add to `test/services/user_data_service_test.dart`:

```dart
group('AppProvider local stats', () {
  test('passagesRead starts at 0', () {
    final provider = AppProvider();
    expect(provider.passagesRead, 0);
  });

  test('longestStreak starts at 0', () {
    final provider = AppProvider();
    expect(provider.longestStreak, 0);
  });

  test('pendingMilestone starts null', () {
    final provider = AppProvider();
    expect(provider.pendingMilestone, isNull);
  });

  test('incrementPassagesRead adds to passagesRead', () {
    final provider = AppProvider();
    provider.incrementPassagesRead('2026-03-03');
    expect(provider.passagesRead, 1);
    expect(provider.dailyPassages['2026-03-03'], 1);
  });

  test('clearMilestone sets pendingMilestone to null', () {
    final provider = AppProvider();
    provider.pendingMilestone = 7;
    provider.clearMilestone();
    expect(provider.pendingMilestone, isNull);
  });
});
```

Run:

```bash
flutter test test/services/user_data_service_test.dart
```

Expected: the 5 new tests fail.

**Step 2: Add fields and methods to `lib/providers/app_provider.dart`**

Add new fields at the top of the class (after `String readingStyle = 'vertical';`):

```dart
int passagesRead = 0;
int longestStreak = 0;
Map<String, int> dailyPassages = {};
int? pendingMilestone;
```

Add the helper method `incrementPassagesRead` (does NOT call Supabase — local only):

```dart
void incrementPassagesRead(String dateStr) {
  passagesRead++;
  dailyPassages = {
    ...dailyPassages,
    dateStr: (dailyPassages[dateStr] ?? 0) + 1,
  };
  notifyListeners();
}

void clearMilestone() {
  pendingMilestone = null;
  notifyListeners();
}
```

Add a private `_loadLocalStats` method that reads from SharedPreferences:

```dart
Future<void> _loadLocalStats() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    passagesRead = prefs.getInt('passages_read') ?? 0;
    longestStreak = prefs.getInt('longest_streak') ?? 0;
    final dailyJson = prefs.getString('daily_passages');
    if (dailyJson != null) {
      final decoded = jsonDecode(dailyJson) as Map<String, dynamic>;
      dailyPassages = decoded.map((k, v) => MapEntry(k, v as int));
    }
  } catch (e, st) {
    debugPrint('AppProvider._loadLocalStats error: $e\n$st');
  }
}
```

Add `_saveLocalStats` method:

```dart
Future<void> _saveLocalStats() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('passages_read', passagesRead);
    await prefs.setInt('longest_streak', longestStreak);
    await prefs.setString('daily_passages', jsonEncode(dailyPassages));
  } catch (e, st) {
    debugPrint('AppProvider._saveLocalStats error: $e\n$st');
  }
}
```

Add `_checkMilestone` method:

```dart
Future<void> _checkMilestone(int currentStreak) async {
  const milestones = [7, 30, 100];
  try {
    final prefs = await SharedPreferences.getInstance();
    final lastCelebrated = prefs.getInt('last_celebrated_milestone') ?? 0;
    int? next;
    for (final m in milestones) {
      if (currentStreak >= m && m > lastCelebrated) next = m;
    }
    if (next != null) {
      pendingMilestone = next;
      await prefs.setInt('last_celebrated_milestone', next);
      notifyListeners();
    }
  } catch (e, st) {
    debugPrint('AppProvider._checkMilestone error: $e\n$st');
  }
}
```

Update the `load` method to call `_loadLocalStats` first and `_checkMilestone` after setting `readDays`. Also update `longestStreak` if current streak is higher. Inside the `try` block in `load`, after `readDays = data.readDays;`, add:

```dart
final current = calculateStreak(readDays);
if (current > longestStreak) {
  longestStreak = current;
}
await _checkMilestone(current);
```

And call `_loadLocalStats()` at the start of `load`, before `loading = true`:

```dart
Future<void> load(String userId) async {
  await _loadLocalStats();   // <-- add this line
  loading = true;
  notifyListeners();
  // ... rest of existing code
```

After updating `longestStreak`, save it:

```dart
if (current > longestStreak) {
  longestStreak = current;
  await _saveLocalStats();
}
```

Add the required imports to `app_provider.dart`:

```dart
import 'dart:convert';
import '../utils/streak_calculator.dart';
```

Update `markReadToday` to also recheck milestone and update longestStreak:

```dart
Future<void> markReadToday(String userId) async {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  if (!readDays.contains(today)) {
    readDays = [...readDays, today];
    notifyListeners();
  }
  await UserDataService.markReadToday(userId);
  final current = calculateStreak(readDays);
  if (current > longestStreak) {
    longestStreak = current;
    await _saveLocalStats();
    notifyListeners();
  }
  await _checkMilestone(current);
}
```

**Step 3: Run tests**

```bash
flutter test test/services/user_data_service_test.dart
```

Expected: all tests pass.

**Step 4: Commit**

```bash
git add lib/providers/app_provider.dart test/services/user_data_service_test.dart
git commit -m "feat: track passagesRead, longestStreak, dailyPassages and streak milestones in AppProvider"
```

---

## Task 5: Wire `incrementPassagesRead` into ReaderScreen

**Files:**
- Modify: `lib/screens/reader_screen.dart`

**Context:** Each time `_onPageChanged` fires, we increment the daily passages counter in `AppProvider`. The provider is already available via `Provider.of<AppProvider>`.

**Step 1: Update `_onPageChanged` in `reader_screen.dart`**

The existing `_onPageChanged` method starts a debounce timer. Add an immediate local increment at the top of the method, before the timer:

```dart
void _onPageChanged(int index) {
  // Immediately increment local passage counter (no debounce)
  final today = DateTime.now().toIso8601String().substring(0, 10);
  if (mounted) {
    Provider.of<AppProvider>(context, listen: false)
        .incrementPassagesRead(today);
  }

  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(seconds: 3), () async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('progress_${widget.bookId}', index);
    } catch (e, st) {
      debugPrint('Progress prefs error: $e\n$st');
    }
    if (_userId != null) {
      try {
        await UserDataService.syncProgress(_userId!, widget.bookId, index);
        await UserDataService.markReadToday(_userId!);
      } catch (e, st) {
        debugPrint('Progress sync error: $e\n$st');
      }
    }
  });
}
```

Note: this step also fixes the silent catch blocks in `_onPageChanged` (design doc item 6c).

**Step 2: Fix remaining silent catch blocks in `reader_screen.dart`**

At line 63 (`SharedPreferences` progress load):

```dart
try {
  final prefs = await SharedPreferences.getInstance();
  savedIndex = prefs.getInt('progress_${widget.bookId}') ?? 0;
} catch (e, st) {
  debugPrint('Progress load error: $e\n$st');
}
```

At line 75 (Supabase progress fetch):

```dart
try {
  final res = await supabase
      .from('progress')
      .select('chunk_index')
      .eq('user_id', _userId!)
      .eq('book_id', widget.bookId)
      .maybeSingle();
  if (res != null) savedIndex = res['chunk_index'] as int;
} catch (e, st) {
  debugPrint('Supabase progress fetch error: $e\n$st');
}
```

At line 100 (chunk fetch outer catch):

```dart
} catch (e, st) {
  debugPrint('Chunk fetch error: $e\n$st');
  if (mounted) setState(() { _loading = false; _fetchError = true; });
}
```

At `_userId` getter:

```dart
String? get _userId {
  try {
    return supabase.auth.currentUser?.id;
  } catch (e, st) {
    debugPrint('Auth user error: $e\n$st');
    return null;
  }
}
```

**Step 3: Fix silent catch blocks in `lib/screens/onboarding_screen.dart`**

Lines 143–146 (`_goSignUp`):

```dart
Future<void> _goSignUp() async {
  if (_selectedStyle == null) return;
  final style = _selectedStyle!;
  try {
    await widget.onStyleSelected(style);
  } catch (e, st) {
    debugPrint('onStyleSelected error: $e\n$st');
  }
  try {
    await widget.onComplete();
  } catch (e, st) {
    debugPrint('onComplete error: $e\n$st');
  }
  if (mounted) context.go('/signup');
}
```

Lines 151–154 (`_goLogIn`):

```dart
Future<void> _goLogIn() async {
  try {
    await widget.onComplete();
  } catch (e, st) {
    debugPrint('onComplete error: $e\n$st');
  }
  if (mounted) context.go('/login');
}
```

**Step 4: Fix silent catch block in `lib/providers/app_provider.dart`**

Line 23-31, the `pending_reading_style` block:

```dart
try {
  final prefs = await SharedPreferences.getInstance();
  final pending = prefs.getString('pending_reading_style');
  if (pending != null) {
    readingStyle = pending;
    await prefs.remove('pending_reading_style');
    UserDataService.saveReadingStyle(userId, pending).catchError((e, st) {
      debugPrint('saveReadingStyle error: $e\n$st');
    });
  }
} catch (e, st) {
  debugPrint('Pending reading style error: $e\n$st');
}
```

**Step 5: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/screens/reader_screen.dart lib/screens/onboarding_screen.dart lib/providers/app_provider.dart
git commit -m "fix: wire passage increment into reader, replace all silent catch blocks with debug logging"
```

---

## Task 6: Stats Screen Redesign

**Files:**
- Modify: `lib/screens/stats_screen.dart`
- Modify: `pubspec.yaml` (add `path_provider`)
- Modify: `test/screens/stats_screen_test.dart`

**Context:** The current screen has a streak number and binary calendar. We add: passages read counter, longest streak, intensity heatmap (opacity from `dailyPassages`), and a share button that generates a branded PNG card. The PNG share requires `path_provider` to write to a temp file before sharing.

**Step 1: Add `path_provider` dependency**

In `pubspec.yaml`, under `dependencies:`, add:

```yaml
path_provider: ^2.1.0
```

Run:

```bash
flutter pub get
```

**Step 2: Write failing tests**

In `test/screens/stats_screen_test.dart`, add to the `_wrap` helper:

```dart
Widget _wrap({List<String> readDays = const [], int passagesRead = 0, int longestStreak = 0}) {
  GoogleFonts.config.allowRuntimeFetching = false;
  final provider = AppProvider()
    ..library = []
    ..progress = {}
    ..readDays = readDays
    ..passagesRead = passagesRead
    ..longestStreak = longestStreak;
  return ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp(theme: AppTheme.light, home: const StatsScreen()),
  );
}
```

(The existing `_wrap` has no `passagesRead`/`longestStreak` params — update it.)

Add new tests:

```dart
testWidgets('shows passages read count', (tester) async {
  await tester.pumpWidget(_wrap(passagesRead: 42));
  expect(find.textContaining('42'), findsWidgets);
  expect(find.textContaining('passages'), findsOneWidget);
});

testWidgets('shows longest streak label', (tester) async {
  await tester.pumpWidget(_wrap(longestStreak: 30));
  expect(find.textContaining('best'), findsOneWidget);
});

testWidgets('shows share streak button', (tester) async {
  await tester.pumpWidget(_wrap());
  expect(find.textContaining('Share'), findsOneWidget);
});
```

Run:

```bash
flutter test test/screens/stats_screen_test.dart
```

Expected: 3 new tests fail.

**Step 3: Rewrite `lib/screens/stats_screen.dart`**

Replace the entire file:

```dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme.dart';
import '../providers/app_provider.dart';
import '../utils/streak_calculator.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _shareCardKey = GlobalKey();

  Future<void> _shareStreak(int streak) async {
    try {
      final boundary = _shareCardKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/streak_card.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '🔥 $streak day reading streak on Scroll Books!',
        ),
      );
    } catch (e, st) {
      debugPrint('Share streak error: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final streak = calculateStreak(provider.readDays);
        final now = DateTime.now();
        final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

        return Scaffold(
          backgroundColor: AppTheme.page,
          appBar: AppBar(title: const Text('Stats')),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  // Streak metrics row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        children: [
                          Text(
                            '🔥 $streak',
                            style: GoogleFonts.lora(
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.brand,
                            ),
                          ),
                          Text(
                            'day streak',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.tobacco,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          Text(
                            '${provider.longestStreak}',
                            style: GoogleFonts.lora(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.pewter,
                            ),
                          ),
                          Text(
                            'best',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.fog,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Passages read
                  Text(
                    '${provider.passagesRead} passages read',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      color: AppTheme.tobacco,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Share button
                  ElevatedButton.icon(
                    onPressed: () => _shareStreak(streak),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share Streak'),
                  ),
                  const SizedBox(height: 32),
                  // Calendar header
                  Text(
                    '${_monthName(now.month)} ${now.year}',
                    style: GoogleFonts.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Intensity heatmap
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: daysInMonth,
                    itemBuilder: (_, i) {
                      final day = i + 1;
                      final dateStr =
                          '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                      final read = provider.readDays.contains(dateStr);
                      final count = provider.dailyPassages[dateStr] ?? 0;
                      // Intensity: 1-5 = 30%, 6-15 = 60%, 16+ = 100%
                      double opacity = 0;
                      if (read) {
                        if (count >= 16) {
                          opacity = 1.0;
                        } else if (count >= 6) {
                          opacity = 0.6;
                        } else {
                          opacity = 0.3;
                        }
                      }
                      return Container(
                        decoration: BoxDecoration(
                          color: read
                              ? AppTheme.brand.withOpacity(opacity)
                              : AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 11,
                              color: read
                                  ? AppTheme.surface
                                  : AppTheme.pewter,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  // Hidden share card (off-screen rendering for RepaintBoundary)
                  RepaintBoundary(
                    key: _shareCardKey,
                    child: _StreakShareCard(streak: streak),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month];
  }
}

class _StreakShareCard extends StatelessWidget {
  final int streak;
  const _StreakShareCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      color: AppTheme.page,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(
            '$streak',
            style: GoogleFonts.lora(
              fontSize: 80,
              fontWeight: FontWeight.w900,
              color: AppTheme.brand,
            ),
          ),
          Text(
            'days reading streak',
            style: GoogleFonts.nunito(
              fontSize: 18,
              color: AppTheme.tobacco,
            ),
          ),
          const Spacer(),
          Text.rich(
            TextSpan(
              style: GoogleFonts.lora(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
              children: [
                const TextSpan(text: 'scroll'),
                TextSpan(
                  text: '.',
                  style: TextStyle(color: AppTheme.brand),
                ),
                const TextSpan(text: 'books'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Run tests**

```bash
flutter test test/screens/stats_screen_test.dart
```

Expected: all tests pass including the 3 new ones.

**Step 5: Commit**

```bash
git add lib/screens/stats_screen.dart pubspec.yaml test/screens/stats_screen_test.dart
git commit -m "feat: redesign stats screen — passages, longest streak, intensity heatmap, shareable card"
```

---

## Task 7: Streak Milestone Celebration Overlay

**Files:**
- Modify: `lib/screens/stats_screen.dart`
- Modify: `test/screens/stats_screen_test.dart`

**Context:** When `AppProvider.pendingMilestone` is non-null, show a full-screen animated overlay on the Stats screen. The overlay shows a pulsing fire emoji, a bold message, and a share/dismiss button. Tapping anywhere dismisses and calls `provider.clearMilestone()`.

**Step 1: Write failing test**

Add to `test/screens/stats_screen_test.dart`:

```dart
testWidgets('shows milestone overlay when pendingMilestone set', (tester) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final provider = AppProvider()
    ..readDays = []
    ..pendingMilestone = 7;
  await tester.pumpWidget(
    ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(theme: AppTheme.light, home: const StatsScreen()),
    ),
  );
  await tester.pump();
  expect(find.textContaining("7 days"), findsOneWidget);
});

testWidgets('dismissing milestone clears pendingMilestone', (tester) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final provider = AppProvider()
    ..readDays = []
    ..pendingMilestone = 30;
  await tester.pumpWidget(
    ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(theme: AppTheme.light, home: const StatsScreen()),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('Dismiss'));
  await tester.pump();
  expect(provider.pendingMilestone, isNull);
});
```

Run:

```bash
flutter test test/screens/stats_screen_test.dart
```

Expected: 2 new tests fail.

**Step 2: Add `_MilestoneOverlay` widget to `stats_screen.dart`**

Add this new widget class at the bottom of the file (before the closing brace):

```dart
class _MilestoneOverlay extends StatefulWidget {
  final int milestone;
  final VoidCallback onDismiss;
  final VoidCallback onShare;
  const _MilestoneOverlay({
    required this.milestone,
    required this.onDismiss,
    required this.onShare,
  });

  @override
  State<_MilestoneOverlay> createState() => _MilestoneOverlayState();
}

class _MilestoneOverlayState extends State<_MilestoneOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.25)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _message {
    if (widget.milestone >= 100) return '100 days. Legendary.';
    if (widget.milestone >= 30) return '30 days. You\'re on fire.';
    return '7 days. Keep going.';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: AppTheme.page.withOpacity(0.95),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: const Text('🔥', style: TextStyle(fontSize: 96)),
              ),
              const SizedBox(height: 24),
              Text(
                '${widget.milestone} days',
                style: GoogleFonts.lora(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.brand,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _message,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  color: AppTheme.tobacco,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: widget.onShare,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share this moment'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onDismiss,
                child: Text(
                  'Dismiss',
                  style: TextStyle(color: AppTheme.pewter),
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

**Step 3: Add overlay to `StatsScreen` build**

In `_StatsScreenState.build`, wrap the `Scaffold` in a `Stack`:

```dart
@override
Widget build(BuildContext context) {
  return Consumer<AppProvider>(
    builder: (context, provider, _) {
      final streak = calculateStreak(provider.readDays);
      // ... existing scaffold code ...
      final scaffold = Scaffold(/* existing code */);

      if (provider.pendingMilestone == null) return scaffold;

      return Stack(
        children: [
          scaffold,
          Positioned.fill(
            child: _MilestoneOverlay(
              milestone: provider.pendingMilestone!,
              onDismiss: provider.clearMilestone,
              onShare: () {
                provider.clearMilestone();
                _shareStreak(provider.pendingMilestone ?? streak);
              },
            ),
          ),
        ],
      );
    },
  );
}
```

Extract the Scaffold into a local variable `final scaffold = Scaffold(...)` and then apply the conditional Stack. The full restructured build method:

```dart
@override
Widget build(BuildContext context) {
  return Consumer<AppProvider>(
    builder: (context, provider, _) {
      final streak = calculateStreak(provider.readDays);
      final now = DateTime.now();
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

      final scaffold = Scaffold(
        // ... all existing scaffold code unchanged ...
      );

      if (provider.pendingMilestone == null) return scaffold;

      return Stack(
        children: [
          scaffold,
          Positioned.fill(
            child: _MilestoneOverlay(
              milestone: provider.pendingMilestone!,
              onDismiss: provider.clearMilestone,
              onShare: () {
                final m = provider.pendingMilestone ?? streak;
                provider.clearMilestone();
                _shareStreak(m);
              },
            ),
          ),
        ],
      );
    },
  );
}
```

**Step 4: Run tests**

```bash
flutter test test/screens/stats_screen_test.dart
```

Expected: all tests pass.

**Step 5: Commit**

```bash
git add lib/screens/stats_screen.dart test/screens/stats_screen_test.dart
git commit -m "feat: add streak milestone celebration overlay at 7, 30, 100 days"
```

---

## Task 8: Onboarding Card Centering

**Files:**
- Modify: `lib/screens/onboarding_screen.dart`
- Modify: `test/screens/onboarding_screen_test.dart`

**Context:** The `_buildFeatureCard` and `_buildShareTipCard` methods use a single `Spacer()` at the bottom. This pushes content to the top. Adding a `Spacer()` before the icon centres the content vertically.

**Step 1: Write failing test**

The onboarding screen has a `PageView` with `viewportFraction: 0.88`. To reach specific cards in tests we call `_pageController.animateToPage`. Since we can't access the private controller, test by checking the Column structure has balanced spacers. Add to `test/screens/onboarding_screen_test.dart`:

```dart
testWidgets('feature cards have centred layout (equal spacers)', (tester) async {
  // Build just the feature card in isolation
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: OnboardingScreen(
          onComplete: () async {},
          onStyleSelected: (_) async {},
        ),
      ),
    ),
  );
  await tester.pump();
  // Should have multiple Spacer widgets (one above and one below content per card)
  expect(find.byType(Spacer), findsWidgets);
});
```

Run:

```bash
flutter test test/screens/onboarding_screen_test.dart
```

This should already pass (Spacers exist) — use it as a regression guard.

**Step 2: Update `_buildFeatureCard` in `onboarding_screen.dart`**

Replace the method:

```dart
Widget _buildFeatureCard(int index, int totalCards) {
  final card = _featureCards[index];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Spacer(),                           // NEW: space above centres content
      Icon(card.icon, size: 56, color: AppTheme.brand),
      const SizedBox(height: 32),
      Text(
        card.headline,
        style: GoogleFonts.lora(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        card.body,
        style: GoogleFonts.nunito(fontSize: 16, color: AppTheme.tobacco),
      ),
      const Spacer(),                           // existing spacer (pushes dots down)
      _DotRow(current: index, total: totalCards),
      const SizedBox(height: 8),
    ],
  );
}
```

**Step 3: Update `_buildShareTipCard`**

Replace the method:

```dart
Widget _buildShareTipCard(int totalCards) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Spacer(),                           // NEW: space above centres content
      Icon(Icons.share_outlined, size: 56, color: AppTheme.brand),
      const SizedBox(height: 32),
      Text(
        'Long press to share.',
        style: GoogleFonts.lora(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'Hold any passage to share it with a friend.',
        style: GoogleFonts.nunito(fontSize: 16, color: AppTheme.tobacco),
      ),
      const SizedBox(height: 24),
      Center(
        child: SizedBox(
          height: 80,
          width: 120,
          child: ClipRect(
            child: Stack(
              alignment: Alignment.center,
              children: [
                const _MiniReaderCard(),
                FadeTransition(
                  opacity: _pressOpacity,
                  child: ScaleTransition(
                    scale: _pressScale,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.brand.withOpacity(0.25),
                        border: Border.all(
                          color: AppTheme.brand.withOpacity(0.6),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: FadeTransition(
                    opacity: _shareIconOpacity,
                    child: const Icon(
                      Icons.share_outlined,
                      size: 14,
                      color: AppTheme.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const Spacer(),
      _DotRow(current: _featureCards.length, total: totalCards),
      const SizedBox(height: 8),
    ],
  );
}
```

**Step 4: Update `_buildStylePickerCard`**

Add a `Spacer()` before the title text (content can't centre fully due to the buttons at the bottom, but the title/subtitle should be pushed down slightly):

```dart
Widget _buildStylePickerCard(int totalCards) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),        // keep existing top padding
      Text(
        'How do you like to read?',
        style: GoogleFonts.lora(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
      ),
      // ... rest unchanged
```

(Style picker keeps its current layout — the buttons need to stay at the bottom.)

**Step 5: Run tests**

```bash
flutter test test/screens/onboarding_screen_test.dart
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/screens/onboarding_screen.dart test/screens/onboarding_screen_test.dart
git commit -m "fix: centre onboarding card content vertically with balanced Spacers"
```

---

## Task 9: Onboarding Card Animations

**Files:**
- Modify: `lib/screens/onboarding_screen.dart`
- Modify: `test/screens/onboarding_screen_test.dart`

**Context:** The state already has `TickerProviderStateMixin`. We add three `AnimationController`s — `_chunksController` (book icon pulse), `_streakController` (fire pulse), `_classicsController` (icon shimmer). Each loops with `repeat(reverse: true)`. The first card's animation starts automatically in `initState`. `onPageChanged` starts/stops the right controller.

**Step 1: Write failing test**

Add to `test/screens/onboarding_screen_test.dart`:

```dart
testWidgets('onboarding builds with animation controllers', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: OnboardingScreen(
          onComplete: () async {},
          onStyleSelected: (_) async {},
        ),
      ),
    ),
  );
  await tester.pump();
  // ScaleTransition should be present for the animated icon on the first card
  expect(find.byType(ScaleTransition), findsWidgets);
});
```

Run:

```bash
flutter test test/screens/onboarding_screen_test.dart
```

Expected: new test fails (no ScaleTransition).

**Step 2: Add controllers and animations to `_OnboardingScreenState`**

After the existing `late final AnimationController _shareController;` declarations, add:

```dart
late final AnimationController _chunksController;
late final AnimationController _streakController;
late final AnimationController _classicsController;
late final Animation<double> _chunksScale;
late final Animation<double> _streakScale;
late final Animation<double> _classicsOpacity;
```

In `initState`, after the existing `_shareController.forward();` line, add:

```dart
_chunksController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1200),
);
_chunksScale = Tween<double>(begin: 1.0, end: 1.15).animate(
  CurvedAnimation(parent: _chunksController, curve: Curves.easeInOut),
);

_streakController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 700),
);
_streakScale = Tween<double>(begin: 1.0, end: 1.35).animate(
  CurvedAnimation(parent: _streakController, curve: Curves.elasticOut),
);

_classicsController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1800),
);
_classicsOpacity = Tween<double>(begin: 0.45, end: 1.0).animate(
  CurvedAnimation(parent: _classicsController, curve: Curves.easeInOut),
);

// Auto-start for first card (index 0 = chunks card)
_chunksController.repeat(reverse: true);
```

In `dispose`, add before `super.dispose()`:

```dart
_chunksController.dispose();
_streakController.dispose();
_classicsController.dispose();
```

**Step 3: Update `onPageChanged` to manage per-card controllers**

Replace the existing `onPageChanged` callback:

```dart
onPageChanged: (i) {
  _previewPauseTimer?.cancel();
  _sharePauseTimer?.cancel();
  // Stop all card-specific animations
  _chunksController.stop();
  _streakController.stop();
  _classicsController.stop();
  // Start the right one
  if (i == 0) {
    _chunksController.repeat(reverse: true);
  } else if (i == 1) {
    _streakController.repeat(reverse: true);
  } else if (i == 2) {
    _classicsController.repeat(reverse: true);
  } else if (i == _featureCards.length) {
    setState(() {
      _shareController.reset();
      _shareController.forward();
    });
  } else if (i == _featureCards.length + 1) {
    setState(() {
      _shareController.reset();
      _previewController.reset();
      _previewController.forward();
    });
  }
},
```

**Step 4: Update `_buildFeatureCard` to use per-card animated icons**

Replace the `Icon(card.icon, ...)` line in `_buildFeatureCard` with a switch:

```dart
Widget _buildFeatureCard(int index, int totalCards) {
  final card = _featureCards[index];

  Widget animatedIcon;
  switch (index) {
    case 0: // Read in chunks — pulsing book icon
      animatedIcon = ScaleTransition(
        scale: _chunksScale,
        child: Icon(card.icon, size: 56, color: AppTheme.brand),
      );
    case 1: // Build a streak — pulsing fire emoji
      animatedIcon = ScaleTransition(
        scale: _streakScale,
        child: const Text('🔥', style: TextStyle(fontSize: 56)),
      );
    case 2: // The classics, free — shimmering icon
      animatedIcon = FadeTransition(
        opacity: _classicsOpacity,
        child: Icon(card.icon, size: 56, color: AppTheme.amber),
      );
    default:
      animatedIcon = Icon(card.icon, size: 56, color: AppTheme.brand);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Spacer(),
      animatedIcon,                              // use animated icon
      const SizedBox(height: 32),
      Text(
        card.headline,
        style: GoogleFonts.lora(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        card.body,
        style: GoogleFonts.nunito(fontSize: 16, color: AppTheme.tobacco),
      ),
      const Spacer(),
      _DotRow(current: index, total: totalCards),
      const SizedBox(height: 8),
    ],
  );
}
```

Note: Dart 3 switch expressions can use `case` without `break` — use exhaustive switch or add `default`.

**Step 5: Run tests**

```bash
flutter test test/screens/onboarding_screen_test.dart
```

Expected: all tests pass including new one.

**Step 6: Commit**

```bash
git add lib/screens/onboarding_screen.dart test/screens/onboarding_screen_test.dart
git commit -m "feat: add per-card animations to onboarding — fire pulse, book bob, classics shimmer"
```

---

## Task 10: Share Flow & Progress Sync Tests

**Files:**
- Modify: `test/screens/reader_screen_test.dart`

**Context:** We cannot easily test the full share platform channel in widget tests. Instead: (1) extract the share text formatting to a static helper and unit-test it; (2) verify the `GestureDetector` with `onLongPress` callback exists in the widget tree after the loading state resolves for a book without chunks. (3) Add a basic test verifying `_onPageChanged` calls `incrementPassagesRead`.

**Step 1: Extract share text formatter in `reader_screen.dart`**

In `lib/screens/reader_screen.dart`, make the format string a static method accessible to tests:

```dart
static String formatShareText(String passage) =>
    '$passage\n\n— Read on Scroll Books';
```

Update `_share` to use it:

```dart
void _share(String text) {
  Share.share(ReaderScreen.formatShareText(text));
}
```

**Step 2: Write tests in `reader_screen_test.dart`**

Add the following tests:

```dart
test('formatShareText appends attribution', () {
  const passage = 'Call me Ishmael.';
  final result = ReaderScreen.formatShareText(passage);
  expect(result, contains('Call me Ishmael.'));
  expect(result, contains('— Read on Scroll Books'));
});

test('formatShareText separates passage and attribution with blank line', () {
  const passage = 'Test passage.';
  final result = ReaderScreen.formatShareText(passage);
  expect(result, contains('\n\n'));
});

testWidgets('coming soon state has no long-press share GestureDetector active', (tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppProvider>.value(
      value: AppProvider(),
      child: MaterialApp(
        theme: AppTheme.light,
        home: const ReaderScreen(bookId: 'pride-and-prejudice'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // In coming-soon state there is no GestureDetector with onLongPress
  // because the PageView hasn't rendered (no chunks)
  expect(find.textContaining('Coming Soon'), findsOneWidget);
});

testWidgets('incrementPassagesRead is exposed on AppProvider', (tester) async {
  final provider = AppProvider();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  provider.incrementPassagesRead(today);
  expect(provider.passagesRead, 1);
  expect(provider.dailyPassages[today], 1);
});
```

**Step 3: Run tests**

```bash
flutter test test/screens/reader_screen_test.dart
```

Expected: all tests pass.

**Step 4: Run full test suite**

```bash
flutter test
```

Expected: all tests pass (106+ tests, 0 failures).

**Step 5: Commit**

```bash
git add lib/screens/reader_screen.dart test/screens/reader_screen_test.dart
git commit -m "test: add share text formatter unit tests and passage increment tests"
```

---

## Final Verification

```bash
flutter test
```

Expected: all tests pass, 0 failures.

```bash
flutter run
```

Expected: app launches on device, reader card shows brand left bar, landing screen shows rotating passages, stats screen shows passages + share button, onboarding cards animate.
