# Reader Card Style Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update `ReaderCard` so chunk text sits inside a surface-coloured panel, and the bottom row shows the reader's position (page + percentage) on the left, share button on the right.

**Architecture:** Two-file change. `ReaderCard` gets two new required params (`chunkIndex`, `totalChunks`) and a restructured layout. `ReaderScreen` passes those params from the `PageView.builder`. Existing tests updated for the new signature; one new test added for position display.

**Tech Stack:** Flutter, `google_fonts`, `AppTheme` tokens (`AppTheme.page`, `AppTheme.surface`, `AppTheme.borderSoft`, `AppTheme.pewter`, `AppTheme.ink`)

---

### Task 1: Update `ReaderCard` widget

**Files:**
- Modify: `lib/widgets/reader/reader_card.dart`
- Modify: `test/widgets/reader_card_test.dart`

**Step 1: Update the test file first**

Replace the entire contents of `test/widgets/reader_card_test.dart` with:

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
            onShare: () {},
          ),
        ),
      );
      expect(find.text('Call me Ishmael.'), findsOneWidget);
    });

    testWidgets('shows share button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ReaderCard(
            text: 'Test chunk.',
            chunkIndex: 0,
            totalChunks: 100,
            onShare: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    });

    testWidgets('tapping share calls onShare callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ReaderCard(
            text: 'Test.',
            chunkIndex: 0,
            totalChunks: 100,
            onShare: () { tapped = true; },
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.share_outlined));
      expect(tapped, isTrue);
    });

    testWidgets('shows page number and percentage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ReaderCard(
            text: 'Test.',
            chunkIndex: 49,
            totalChunks: 100,
            onShare: () {},
          ),
        ),
      );
      // chunkIndex 49 → p. 50 · 50%
      expect(find.textContaining('p. 50'), findsOneWidget);
      expect(find.textContaining('50%'), findsOneWidget);
    });
  });
}
```

**Step 2: Run to verify existing tests now fail**

```bash
flutter test test/widgets/reader_card_test.dart
```

Expected: FAIL — `ReaderCard` constructor missing `chunkIndex` and `totalChunks`.

**Step 3: Replace `lib/widgets/reader/reader_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class ReaderCard extends StatelessWidget {
  final String text;
  final int chunkIndex;
  final int totalChunks;
  final VoidCallback onShare;

  const ReaderCard({
    super.key,
    required this.text,
    required this.chunkIndex,
    required this.totalChunks,
    required this.onShare,
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
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    color: AppTheme.pewter,
                    onPressed: onShare,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Run tests to verify they pass**

```bash
flutter test test/widgets/reader_card_test.dart
```

Expected: All 4 tests PASS.

**Step 5: Commit**

```bash
git add lib/widgets/reader/reader_card.dart test/widgets/reader_card_test.dart
git commit -m "Update reader card: surface panel, page number and percentage"
```

---

### Task 2: Update `ReaderScreen` to pass new params

**Files:**
- Modify: `lib/screens/reader_screen.dart`
- Modify: `test/screens/reader_screen_test.dart`

**Step 1: Update `lib/screens/reader_screen.dart`**

Find the `PageView.builder` `itemBuilder` (near the bottom of `_buildBody`):

```dart
itemBuilder: (_, index) => ReaderCard(
  text: _chunks[index],
  onShare: () => _share(_chunks[index]),
),
```

Replace with:

```dart
itemBuilder: (_, index) => ReaderCard(
  text: _chunks[index],
  chunkIndex: index,
  totalChunks: _chunks.length,
  onShare: () => _share(_chunks[index]),
),
```

**Step 2: Run full test suite**

```bash
flutter test
```

Expected: All 49 tests PASS. (The reader_screen tests don't construct `ReaderCard` directly, so no changes needed there.)

**Step 3: Commit**

```bash
git add lib/screens/reader_screen.dart
git commit -m "Pass chunkIndex and totalChunks to ReaderCard in reader screen"
```
