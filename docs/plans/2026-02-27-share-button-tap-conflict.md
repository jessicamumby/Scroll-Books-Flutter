# Share Button Tap Conflict — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix the share button in Stories Style (horizontal) reader mode so tapping it opens the share modal instead of advancing the page.

**Architecture:** Remove `onShare` from `ReaderCard` entirely and hoist the share `IconButton` into `ReaderScreen`'s `Stack` as a top-level `Positioned` widget above the tap-zone overlay. The share button is always rendered last in the Stack, so it wins the gesture arena over the tap zones. The fix applies to both horizontal and vertical modes for consistency.

**Tech Stack:** Flutter, Dart, `share_plus`, `provider`

---

### Task 1: Remove `onShare` from `ReaderCard`

**Files:**
- Modify: `lib/widgets/reader/reader_card.dart`
- Modify: `test/widgets/reader_card_test.dart`

**Context:** `ReaderCard` currently accepts `onShare: VoidCallback` and renders an `IconButton` with `Icons.share_outlined` in the footer row. We're removing both. The footer row will then only contain the page-label `Text`.

---

**Step 1: Update the test file**

Replace the full contents of `test/widgets/reader_card_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_books/core/theme.dart';
import 'package:scroll_books/widgets/reader/reader_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ReaderCard', () {
    testWidgets('displays chunk text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ReaderCard(
            text: 'Call me Ishmael.',
            chunkIndex: 0,
            totalChunks: 100,
          ),
        ),
      );
      expect(find.text('Call me Ishmael.'), findsOneWidget);
    });

    testWidgets('does not render share icon (hoisted to ReaderScreen)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ReaderCard(
            text: 'Test.',
            chunkIndex: 0,
            totalChunks: 100,
          ),
        ),
      );
      expect(find.byIcon(Icons.share_outlined), findsNothing);
    });

    testWidgets('shows page number and percentage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ReaderCard(
            text: 'Test.',
            chunkIndex: 49,
            totalChunks: 100,
          ),
        ),
      );
      expect(find.textContaining('p. 50'), findsOneWidget);
      expect(find.textContaining('50%'), findsOneWidget);
    });
  });
}
```

**Step 2: Run the tests — verify they fail**

```bash
flutter test test/widgets/reader_card_test.dart
```

Expected: **compile error** — `ReaderCard` still requires `onShare` positional argument. This confirms the test is driving the change.

**Step 3: Update `lib/widgets/reader/reader_card.dart`**

Replace the full file contents with:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class ReaderCard extends StatelessWidget {
  final String text;
  final int chunkIndex;
  final int totalChunks;

  const ReaderCard({
    super.key,
    required this.text,
    required this.chunkIndex,
    required this.totalChunks,
  });

  String get _pageLabel {
    final page = chunkIndex + 1;
    final pct = totalChunks > 0
        ? ((chunkIndex + 1) / totalChunks * 100).round()
        : 0;
    return 'p. $page · $pct%';
  }

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
                    border: Border.all(color: AppTheme.borderSoft),
                  ),
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
                              style: GoogleFonts.playfairDisplay(
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
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _pageLabel,
                  style: GoogleFonts.dmMono(
                    fontSize: 12,
                    color: AppTheme.pewter,
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

**Step 4: Run the tests — verify they pass**

```bash
flutter test test/widgets/reader_card_test.dart
```

Expected: **3 tests, 0 failures**

**Step 5: Commit**

```bash
git add lib/widgets/reader/reader_card.dart test/widgets/reader_card_test.dart
git commit -m "Remove onShare from ReaderCard — share button hoisted to ReaderScreen"
```

---

### Task 2: Hoist share button into `ReaderScreen`

**Files:**
- Modify: `lib/screens/reader_screen.dart`
- Modify: `test/screens/reader_screen_test.dart`

**Context:** `ReaderScreen._buildBody` currently returns a plain `pageView` for vertical mode and a `Stack(pageView + tapOverlay)` for horizontal mode. We change it so both modes return a `Stack` with three layers: pageView, optional tap overlay (horizontal only), and a `Positioned` share `IconButton` always on top.

We also need a `_currentIndex` field (int, init `0`) updated in both `_loadReader` (when jumping to saved progress) and `_onPageChanged` (on every swipe). The share callback uses `_chunks[_currentIndex]`.

---

**Step 1: Update `test/screens/reader_screen_test.dart`**

Add two new tests inside the `group('ReaderScreen', ...)` block, after the existing `horizontal mode has GestureDetector tap zones` test:

```dart
testWidgets('share icon is not in ReaderCard (no onShare param)', (tester) async {
  // ReaderCard no longer accepts onShare — this test verifies the card
  // widget compiles and renders without the share icon.
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
  // Coming Soon state — no share button because no chunks loaded
  expect(find.textContaining('Coming Soon'), findsOneWidget);
});

testWidgets('horizontal mode renders share icon above tap zones', (tester) async {
  await tester.pumpWidget(_wrap(readingStyle: 'horizontal'));
  // Still in loading state — share button only appears post-load.
  // Verify the screen builds without error.
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

**Step 2: Run the tests — verify they pass as-is**

```bash
flutter test test/screens/reader_screen_test.dart
```

Expected: all existing tests pass. The two new tests also pass (they don't test the hoisted share button in the loaded state — that requires a network mock beyond this scope). If there's a compile error because `ReaderScreen` still passes `onShare` to `ReaderCard`, that's expected — proceed to Step 3.

**Step 3: Update `lib/screens/reader_screen.dart`**

Make the following four changes:

**3a. Add `_currentIndex` field** (after `_startIndex = 0;` on line 30):

```dart
int _currentIndex = 0;
```

**3b. In `_loadReader`, set `_currentIndex` when setting `_startIndex`** — find this block:

```dart
setState(() {
  _chunks = chunks;
  _startIndex = savedIndex.clamp(0, chunks.length - 1);
  _loading = false;
});
```

Replace with:

```dart
setState(() {
  _chunks = chunks;
  _startIndex = savedIndex.clamp(0, chunks.length - 1);
  _currentIndex = _startIndex;
  _loading = false;
});
```

**3c. In `_onPageChanged`, add setState** — find:

```dart
void _onPageChanged(int index) {
  _debounceTimer?.cancel();
```

Replace with:

```dart
void _onPageChanged(int index) {
  setState(() => _currentIndex = index);
  _debounceTimer?.cancel();
```

**3d. Replace `_buildBody` from the `// build pageView` section to end** — find and replace the section starting at `final style =` through the closing `}` of `_buildBody`. Replace the entire final section (everything after the `_fetchError` block and `!book.hasChunks` block) with:

```dart
    final style = Provider.of<AppProvider>(context).readingStyle;
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
      ),
    );

    return Stack(
      children: [
        pageView,
        if (isHorizontal)
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
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.share_outlined),
            color: AppTheme.pewter,
            onPressed: () => _share(_chunks[_currentIndex]),
          ),
        ),
      ],
    );
  }
```

Note: Remove the old `if (!isHorizontal) return pageView;` line — it is replaced by the unified `Stack` return above.

**Step 4: Run all tests — verify they pass**

```bash
flutter test
```

Expected: all tests pass, 0 failures.

**Step 5: Commit**

```bash
git add lib/screens/reader_screen.dart test/screens/reader_screen_test.dart
git commit -m "Hoist share button above tap overlay — fixes Stories Style share tap conflict"
```
