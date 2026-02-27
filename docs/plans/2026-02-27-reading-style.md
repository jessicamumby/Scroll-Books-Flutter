# Reading Style Feature — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Add Scroll Style (vertical swipe) and Stories Style (horizontal tap) reading modes. Users pick a style on onboarding card 4. They can change it in Profile Settings. Preference is persisted to Supabase.

**Architecture:** `AppProvider` (existing `ChangeNotifier`) owns `readingStyle`. `UserDataService` syncs to a new `user_preferences` Supabase table. `ReaderScreen` reads from `AppProvider`. `OnboardingScreen` gains a 4th card with animated mini-reader previews. `ProfileScreen` gains a "Reading style" tile linking to a new `ReadingStyleScreen`.

**Tech Stack:** Flutter, `provider` package (already used), Supabase (`user_preferences` table), `go_router`.

**Before starting Task 1:** Create this table in Supabase dashboard (SQL editor):
```sql
CREATE TABLE user_preferences (
  user_id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  reading_style text NOT NULL DEFAULT 'vertical'
);
```

---

### Task 1: Data layer — `UserData`, `UserDataService`, `AppProvider`

**Files:**
- Modify: `lib/services/user_data_service.dart`
- Modify: `lib/providers/app_provider.dart`
- Modify: `test/services/user_data_service_test.dart`

---

**Step 1: Write failing tests**

In `test/services/user_data_service_test.dart`, add two tests to the existing `UserData` group and two to the existing `AppProvider` group:

```dart
// in group('UserData'):
test('readingStyle defaults to vertical', () {
  final data = UserData(library: [], progress: {}, readDays: []);
  expect(data.readingStyle, 'vertical');
});

test('readingStyle can be set to horizontal', () {
  final data = UserData(
    library: [], progress: {}, readDays: [], readingStyle: 'horizontal',
  );
  expect(data.readingStyle, 'horizontal');
});

// in group('AppProvider'):
test('readingStyle defaults to vertical', () {
  final provider = AppProvider();
  expect(provider.readingStyle, 'vertical');
});

test('readingStyle field can be updated', () {
  final provider = AppProvider();
  provider.readingStyle = 'horizontal';
  expect(provider.readingStyle, 'horizontal');
});
```

**Step 2: Run to verify failure**

```bash
flutter test test/services/user_data_service_test.dart
```

Expected: FAIL — `UserData` has no `readingStyle`, `AppProvider` has no `readingStyle`.

---

**Step 3: Add `readingStyle` to `UserData`**

In `lib/services/user_data_service.dart`, add the field to `UserData`:

```dart
class UserData {
  final List<String> library;
  final Map<String, int> progress;
  final List<String> readDays;
  final String readingStyle;

  const UserData({
    required this.library,
    required this.progress,
    required this.readDays,
    this.readingStyle = 'vertical',
  });
}
```

**Step 4: Update `fetchAll()` to fetch reading style**

Replace the `fetchAll` body — add a 4th parallel fetch and wire the result:

```dart
static Future<UserData> fetchAll(String userId) async {
  final results = await Future.wait([
    supabase.from('library').select('book_id').eq('user_id', userId),
    supabase.from('progress').select('book_id, chunk_index').eq('user_id', userId),
    supabase.from('read_days').select('date').eq('user_id', userId),
    supabase
        .from('user_preferences')
        .select('reading_style')
        .eq('user_id', userId)
        .maybeSingle(),
  ]);

  final library = (results[0] as List)
      .map((r) => r['book_id'] as String)
      .toList();

  final progress = Map<String, int>.fromEntries(
    (results[1] as List).map((r) =>
        MapEntry(r['book_id'] as String, r['chunk_index'] as int)),
  );

  final readDays = (results[2] as List)
      .map((r) => r['date'] as String)
      .toList();

  final prefs = results[3] as Map<String, dynamic>?;
  final readingStyle = prefs?['reading_style'] as String? ?? 'vertical';

  return UserData(
    library: library,
    progress: progress,
    readDays: readDays,
    readingStyle: readingStyle,
  );
}
```

**Step 5: Add `saveReadingStyle()` to `UserDataService`**

```dart
static Future<void> saveReadingStyle(String userId, String style) async {
  await supabase.from('user_preferences').upsert(
    {'user_id': userId, 'reading_style': style},
    onConflict: 'user_id',
  );
}
```

**Step 6: Update `AppProvider`**

In `lib/providers/app_provider.dart`:

1. Add field after `loading`:

```dart
String readingStyle = 'vertical';
```

2. In `load()`, after populating `readDays`, add:

```dart
readingStyle = data.readingStyle;
```

3. Add new method at the end of the class:

```dart
Future<void> setReadingStyle(String userId, String style) async {
  readingStyle = style;
  notifyListeners();
  await UserDataService.saveReadingStyle(userId, style);
}
```

---

**Step 7: Run tests**

```bash
flutter test test/services/user_data_service_test.dart
```

Expected: all 7 tests in file pass.

**Step 8: Run full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 9: Commit**

```bash
git add lib/services/user_data_service.dart lib/providers/app_provider.dart test/services/user_data_service_test.dart
git commit -m "Add readingStyle to data layer: UserData, UserDataService, AppProvider"
```

---

### Task 2: Onboarding — dot indicator refactor + 4th style picker card

**Files:**
- Modify: `lib/screens/onboarding_screen.dart`
- Modify: `lib/core/router.dart`
- Modify: `test/screens/onboarding_screen_test.dart`

**Context:**
- Current `OnboardingScreen` has 3 cards and dots on the right in a `Row` layout
- New design: dots move inside each card (horizontal row at bottom), 4th card added with mini-reader animation + style selection, "Start reading →" moves to card 4
- `OnboardingScreen` gains an `onStyleSelected: Future<void> Function(String)` constructor param (same callback pattern as `onComplete`)
- `_OnboardingScreenState` needs `with TickerProviderStateMixin` for the `AnimationController`
- The router passes `onStyleSelected` as a closure that calls `appProvider.setReadingStyle()`

---

**Step 1: Write failing tests**

Replace the contents of `test/screens/onboarding_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/screens/onboarding_screen.dart';

Widget _wrap() => MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, __) => OnboardingScreen(
              onComplete: () async {},
              onStyleSelected: (style) async {},
            ),
          ),
          GoRoute(
            path: '/app/library',
            builder: (_, __) => const Scaffold(body: Text('library')),
          ),
        ],
      ),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('OnboardingScreen', () {
    testWidgets('shows first card headline', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Read in chunks.'), findsOneWidget);
    });

    testWidgets('shows first card body text', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Skip doomscrolling, read great books one passage at a time. '
          'No pressure to finish, just read.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('4th card shows style picker headline', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final pageView = find.byType(PageView);
      final size = tester.getSize(pageView);
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      expect(find.text('How do you like to read?'), findsOneWidget);
    });

    testWidgets('Start reading is disabled before style selected', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final pageView = find.byType(PageView);
      final size = tester.getSize(pageView);
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Start reading →'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('tapping style tile enables Start reading', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final pageView = find.byType(PageView);
      final size = tester.getSize(pageView);
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Swipe down'));
      await tester.pumpAndSettle();
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Start reading →'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping Start reading after selection navigates to library',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final pageView = find.byType(PageView);
      final size = tester.getSize(pageView);
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.drag(pageView, Offset(0, -size.height));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Swipe down'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start reading →'));
      await tester.pumpAndSettle();
      expect(find.text('library'), findsOneWidget);
    });
  });
}
```

**Step 2: Run to verify failure**

```bash
flutter test test/screens/onboarding_screen_test.dart
```

Expected: compile error — `OnboardingScreen` doesn't have `onStyleSelected` param.

---

**Step 3: Replace `lib/screens/onboarding_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onComplete;
  final Future<void> Function(String style) onStyleSelected;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
    required this.onStyleSelected,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController(viewportFraction: 0.88);
  late final AnimationController _previewController;
  late final Animation<Offset> _verticalOut;
  late final Animation<Offset> _verticalIn;
  late final Animation<Offset> _horizontalOut;
  late final Animation<Offset> _horizontalIn;
  int _page = 0;
  String? _selectedStyle;

  static const _featureCards = [
    _CardData(
      icon: Icons.menu_book_outlined,
      headline: 'Read in chunks.',
      body: 'Skip doomscrolling, read great books one passage at a time. '
          'No pressure to finish, just read.',
    ),
    _CardData(
      icon: Icons.local_fire_department_outlined,
      headline: 'Build a streak.',
      body: 'Open the App instead of doomscrolling, watch your streak grow.',
    ),
    _CardData(
      icon: Icons.account_balance_outlined,
      headline: 'The classics, free.',
      body: 'Six of the greatest books ever written. Yours, at no cost.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _previewController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _verticalOut = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1))
        .animate(CurvedAnimation(
            parent: _previewController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));
    _verticalIn = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _previewController,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOut)));
    _horizontalOut =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-1, 0))
            .animate(CurvedAnimation(
                parent: _previewController,
                curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));
    _horizontalIn = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _previewController,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOut)));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await widget.onStyleSelected(_selectedStyle!);
    await widget.onComplete();
    if (mounted) context.go('/app/library');
  }

  @override
  Widget build(BuildContext context) {
    final totalCards = _featureCards.length + 1;
    return Scaffold(
      backgroundColor: AppTheme.page,
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: totalCards,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, index) {
            final isStylePicker = index == _featureCards.length;
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: isStylePicker
                    ? _buildStylePickerCard(totalCards)
                    : _buildFeatureCard(index, totalCards),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureCard(int index, int totalCards) {
    final card = _featureCards[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Icon(card.icon, size: 56, color: AppTheme.amber),
        const SizedBox(height: 32),
        Text(
          card.headline,
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          card.body,
          style: GoogleFonts.dmSans(fontSize: 16, color: AppTheme.tobacco),
        ),
        const Spacer(),
        _DotRow(current: index, total: totalCards),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStylePickerCard(int totalCards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'How do you like to read?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Pick a style. You can change it any time in Settings.',
          style: GoogleFonts.dmSans(fontSize: 16, color: AppTheme.tobacco),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _StyleTile(
                label: 'Swipe down',
                subLabel: 'Scroll Style',
                selected: _selectedStyle == 'vertical',
                slideOut: _verticalOut,
                slideIn: _verticalIn,
                onTap: () => setState(() => _selectedStyle = 'vertical'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StyleTile(
                label: 'Tap across',
                subLabel: 'Stories Style',
                selected: _selectedStyle == 'horizontal',
                slideOut: _horizontalOut,
                slideIn: _horizontalIn,
                onTap: () => setState(() => _selectedStyle = 'horizontal'),
              ),
            ),
          ],
        ),
        const Spacer(),
        _DotRow(current: _featureCards.length, total: totalCards),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedStyle != null ? _complete : null,
            child: const Text('Start reading →'),
          ),
        ),
      ],
    );
  }
}

class _StyleTile extends StatelessWidget {
  final String label;
  final String subLabel;
  final bool selected;
  final Animation<Offset> slideOut;
  final Animation<Offset> slideIn;
  final VoidCallback onTap;

  const _StyleTile({
    required this.label,
    required this.subLabel,
    required this.selected,
    required this.slideOut,
    required this.slideIn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.amber : AppTheme.fog,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            ClipRect(
              child: SizedBox(
                height: 80,
                child: Stack(
                  children: [
                    SlideTransition(
                        position: slideOut, child: const _MiniReaderCard()),
                    SlideTransition(
                        position: slideIn, child: const _MiniReaderCard()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink),
            ),
            Text(
              subLabel,
              style: GoogleFonts.dmMono(fontSize: 11, color: AppTheme.pewter),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniReaderCard extends StatelessWidget {
  const _MiniReaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.amberWash,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderSoft),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.fog,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 5),
          FractionallySizedBox(
            widthFactor: 0.8,
            child: Container(
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.fog,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 5),
          FractionallySizedBox(
            widthFactor: 0.6,
            child: Container(
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.fog,
                    borderRadius: BorderRadius.circular(2))),
          ),
        ],
      ),
    );
  }
}

class _DotRow extends StatelessWidget {
  final int current;
  final int total;
  const _DotRow({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: current == i ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: current == i ? AppTheme.amber : AppTheme.fog,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _CardData {
  final IconData icon;
  final String headline;
  final String body;
  const _CardData(
      {required this.icon, required this.headline, required this.body});
}
```

**Step 4: Update the `/onboarding` route in `lib/core/router.dart`**

Add `import 'package:provider/provider.dart';` to the imports, then replace the `/onboarding` route:

```dart
GoRoute(
  path: '/onboarding',
  builder: (context, __) => OnboardingScreen(
    onComplete: completeOnboarding,
    onStyleSelected: (style) async {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Provider.of<AppProvider>(context, listen: false)
            .setReadingStyle(userId, style);
      }
    },
  ),
),
```

Also add `import '../providers/app_provider.dart';` to `router.dart` imports.

---

**Step 5: Run tests**

```bash
flutter test test/screens/onboarding_screen_test.dart
```

Expected: all 6 tests pass.

**Step 6: Run full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 7: Commit**

```bash
git add lib/screens/onboarding_screen.dart lib/core/router.dart test/screens/onboarding_screen_test.dart
git commit -m "Refactor OnboardingScreen: 4th style picker card with animated mini preview, dots inside cards"
```

---

### Task 3: `ReaderScreen` dual mode

**Files:**
- Modify: `lib/screens/reader_screen.dart`
- Modify: `test/screens/reader_screen_test.dart`

**Context:**
- `ReaderScreen` currently uses `PageView` with `scrollDirection: Axis.vertical`
- Need to read `readingStyle` from `AppProvider` and switch axis accordingly
- For `'horizontal'` mode: wrap the `PageView` in a `Stack` with left/right tap zones (30% width each) that call `previousPage` / `nextPage`
- Tests currently use plain `MaterialApp` — need `ChangeNotifierProvider` wrapper since `ReaderScreen` will call `Provider.of<AppProvider>`

---

**Step 1: Write failing tests**

Replace `test/screens/reader_screen_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/reader_screen.dart';

Widget _wrap({String readingStyle = 'vertical'}) {
  final provider = AppProvider()..readingStyle = readingStyle;
  return ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.light,
      home: ReaderScreen(bookId: 'moby-dick'),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ReaderScreen', () {
    testWidgets('shows loading indicator on init', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows coming soon for book without chunks', (tester) async {
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
      expect(find.textContaining('Coming Soon'), findsOneWidget);
    });

    testWidgets('shows back button in header', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('builds with horizontal reading style', (tester) async {
      await tester.pumpWidget(_wrap(readingStyle: 'horizontal'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
```

**Step 2: Run to verify failure**

```bash
flutter test test/screens/reader_screen_test.dart
```

Expected: FAIL — `ReaderScreen` calls `Provider.of<AppProvider>` which isn't in the tree yet (compile passes, runtime throws).

---

**Step 3: Implement dual mode in `ReaderScreen`**

In `lib/screens/reader_screen.dart`:

1. Add imports at top:
```dart
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
```

2. Replace `_buildBody` — extract `PageView` into a variable, add horizontal tap zones:

```dart
Widget _buildBody(Book book) {
  if (_loading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_fetchError) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Couldn't load book", style: TextStyle(color: AppTheme.pewter)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() { _loading = true; _fetchError = false; });
              _loadReader();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  if (!book.hasChunks || _chunks.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Coming Soon',
            style: TextStyle(
              color: AppTheme.fog,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            book.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Full text arriving soon.',
            style: TextStyle(color: AppTheme.tobacco, fontSize: 15),
          ),
        ],
      ),
    );
  }

  final style =
      Provider.of<AppProvider>(context, listen: false).readingStyle;
  final isHorizontal = style == 'horizontal';

  final pageView = PageView.builder(
    controller: _pageController,
    scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
    itemCount: _chunks.length,
    onPageChanged: _onPageChanged,
    itemBuilder: (_, index) => ReaderCard(
      text: _chunks[index],
      chunkIndex: index,
      totalChunks: _chunks.length,
      onShare: () => _share(_chunks[index]),
    ),
  );

  if (!isHorizontal) return pageView;

  return Stack(
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
  );
}
```

---

**Step 4: Run tests**

```bash
flutter test test/screens/reader_screen_test.dart
```

Expected: all 4 tests pass.

**Step 5: Run full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/screens/reader_screen.dart test/screens/reader_screen_test.dart
git commit -m "Add dual reading mode to ReaderScreen: Scroll Style (vertical) and Stories Style (horizontal) with tap zones"
```

---

### Task 4: Profile settings — `ReadingStyleScreen`, `ProfileScreen` tile, router

**Files:**
- Create: `lib/screens/reading_style_screen.dart`
- Modify: `lib/screens/profile_screen.dart`
- Modify: `lib/core/router.dart`
- Create: `test/screens/reading_style_screen_test.dart`
- Modify: `test/screens/profile_screen_test.dart`

**Context:**
- `ProfileScreen` currently uses plain `MaterialApp` in tests (no provider) — tests need updating since `ProfileScreen` will now call `Provider.of<AppProvider>(context)`
- `ReadingStyleScreen` is a two-option picker: "Scroll Style" / "Stories Style" with a checkmark on the selected option
- Route `/app/profile/reading-style` goes inside the `ShellRoute` (so the bottom nav shows)

---

**Step 1: Write failing tests**

Create `test/screens/reading_style_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/reading_style_screen.dart';

Widget _wrap({String readingStyle = 'vertical'}) {
  final provider = AppProvider()..readingStyle = readingStyle;
  return ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/reading-style',
        routes: [
          GoRoute(
            path: '/reading-style',
            builder: (_, __) => const ReadingStyleScreen(),
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ReadingStyleScreen', () {
    testWidgets('shows Scroll Style option', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Scroll Style'), findsOneWidget);
    });

    testWidgets('shows Stories Style option', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Stories Style'), findsOneWidget);
    });

    testWidgets('shows check icon on currently selected style', (tester) async {
      await tester.pumpWidget(_wrap(readingStyle: 'vertical'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('shows check on Stories Style when horizontal selected',
        (tester) async {
      await tester.pumpWidget(_wrap(readingStyle: 'horizontal'));
      await tester.pumpAndSettle();
      // One check icon visible, next to Stories Style
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
```

Update `test/screens/profile_screen_test.dart` to add a `ChangeNotifierProvider` wrapper (since `ProfileScreen` will now use `Provider.of<AppProvider>`) and a test for the new tile. Replace the file contents:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/providers/app_provider.dart';
import 'package:scroll_books/screens/profile_screen.dart';

Widget _wrap() => ChangeNotifierProvider<AppProvider>.value(
      value: AppProvider(),
      child: MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ProfileScreen', () {
    testWidgets('shows sign out button', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('shows email text widget', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows How Scroll Books works tile', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('How Scroll Books works'), findsOneWidget);
    });

    testWidgets('shows Reading style tile', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Reading style'), findsOneWidget);
    });
  });
}
```

**Step 2: Run to verify failure**

```bash
flutter test test/screens/reading_style_screen_test.dart
```

Expected: compile error — `ReadingStyleScreen` doesn't exist.

```bash
flutter test test/screens/profile_screen_test.dart
```

Expected: compile or runtime error — `ProfileScreen` doesn't yet use `AppProvider` so provider tests may still pass, but "Reading style" tile test fails.

---

**Step 3: Create `lib/screens/reading_style_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';

class ReadingStyleScreen extends StatelessWidget {
  const ReadingStyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppTheme.page,
      appBar: AppBar(title: const Text('Reading style')),
      body: Column(
        children: [
          const Divider(color: AppTheme.borderSoft),
          _StyleTile(
            label: 'Scroll Style',
            selected: provider.readingStyle == 'vertical',
            onTap: () async {
              if (userId != null) {
                await provider.setReadingStyle(userId, 'vertical');
              }
              if (context.mounted) context.pop();
            },
          ),
          const Divider(color: AppTheme.borderSoft),
          _StyleTile(
            label: 'Stories Style',
            selected: provider.readingStyle == 'horizontal',
            onTap: () async {
              if (userId != null) {
                await provider.setReadingStyle(userId, 'horizontal');
              }
              if (context.mounted) context.pop();
            },
          ),
          const Divider(color: AppTheme.borderSoft),
        ],
      ),
    );
  }
}

class _StyleTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StyleTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(
        label,
        style: GoogleFonts.dmSans(fontSize: 15, color: AppTheme.ink),
      ),
      trailing: selected ? Icon(Icons.check, color: AppTheme.amber) : null,
      onTap: onTap,
    );
  }
}
```

**Step 4: Update `lib/screens/profile_screen.dart`**

1. Add imports:
```dart
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
```

2. In `build()`, add at the top of the method body (after `final email = _currentEmail();`):
```dart
final readingStyle = Provider.of<AppProvider>(context).readingStyle;
final styleLabel = readingStyle == 'horizontal' ? 'Stories Style' : 'Scroll Style';
```

3. Add the new `ListTile` and `Divider` after the "How Scroll Books works" tile (after its `Divider`):
```dart
ListTile(
  contentPadding: EdgeInsets.zero,
  title: Text(
    'Reading style',
    style: GoogleFonts.dmSans(color: AppTheme.ink, fontSize: 15),
  ),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        styleLabel,
        style: GoogleFonts.dmSans(color: AppTheme.pewter, fontSize: 15),
      ),
      Icon(Icons.chevron_right, color: AppTheme.pewter),
    ],
  ),
  onTap: () => context.push('/app/profile/reading-style'),
),
const Divider(color: AppTheme.borderSoft),
```

**Step 5: Add route to `lib/core/router.dart`**

Add import: `import '../screens/reading_style_screen.dart';`

Inside the `ShellRoute.routes` list, add after the `/app/profile` route:
```dart
GoRoute(
  path: '/app/profile/reading-style',
  builder: (_, __) => const ReadingStyleScreen(),
),
```

---

**Step 6: Run tests**

```bash
flutter test test/screens/reading_style_screen_test.dart
flutter test test/screens/profile_screen_test.dart
```

Expected: all tests in both files pass.

**Step 7: Run full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 8: Commit**

```bash
git add lib/screens/reading_style_screen.dart lib/screens/profile_screen.dart lib/core/router.dart test/screens/reading_style_screen_test.dart test/screens/profile_screen_test.dart
git commit -m "Add Reading style settings: ReadingStyleScreen picker, ProfileScreen tile, router route"
```
