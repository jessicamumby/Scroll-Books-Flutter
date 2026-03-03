# Reader Card Border Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the reader card's brand-red glow shadow and left accent strip with a thin brandPale (#FFD0C8) border around the full card perimeter.

**Architecture:** Two files change: the widget test first (TDD), then the widget itself. The outer card `Container`'s `BoxDecoration` loses `boxShadow` and gains `border: Border.all(color: AppTheme.brandPale, width: 1.5)`. The 3px `Container(color: AppTheme.brand)` strip inside the `Row` is deleted entirely. The `ClipRRect` stays — it still clips inner content to rounded corners.

**Tech Stack:** Flutter/Dart, `flutter_test`, `google_fonts`

---

### Task 1: Update widget tests

**Files:**
- Modify: `test/widgets/reader_card_test.dart:68-95`

The existing test (`'card decoration has brand glow shadow and no border'`) must be renamed and its assertions inverted. A second new test asserts the left-strip `Container` is gone.

**Step 1: Update the existing glow test (rename + invert assertions)**

Replace lines 68–95 in `test/widgets/reader_card_test.dart` with:

```dart
    testWidgets('card decoration has brandPale border and no box shadow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: ReaderCard(text: 'Test passage', chunkIndex: 0, totalChunks: 10),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container)).toList();
      final cardContainer = containers.firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration as BoxDecoration).borderRadius != null,
        orElse: () => throw TestFailure(
          'No Container with a rounded BoxDecoration found in the widget tree',
        ),
      );
      final dec = cardContainer.decoration as BoxDecoration;

      expect(dec.boxShadow, isNull,
          reason: 'BoxShadow glow must be removed');
      expect(dec.border, isNotNull,
          reason: 'brandPale Border.all must be present');
      final border = dec.border! as Border;
      expect(border.top.color, AppTheme.brandPale,
          reason: 'Border color should be AppTheme.brandPale');
      expect(border.top.width, 1.5,
          reason: 'Border width should be 1.5');
    });
```

**Step 2: Add new test for absent left strip**

Append this test inside the `group('ReaderCard', ...)` block, after the test above:

```dart
    testWidgets('does not render left accent strip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: ReaderCard(text: 'Test passage', chunkIndex: 0, totalChunks: 10),
          ),
        ),
      );
      final brandContainers = tester.widgetList<Container>(find.byType(Container))
          .where((c) => c.color == AppTheme.brand)
          .toList();
      expect(brandContainers, isEmpty,
          reason: 'Left accent strip Container with brand color should be removed');
    });
```

**Step 3: Run tests to verify they fail**

```bash
flutter test test/widgets/reader_card_test.dart --no-pub
```

Expected output — two failures:
- `card decoration has brandPale border and no box shadow` → FAIL (boxShadow still present, border still null)
- `does not render left accent strip` → FAIL (brand-colored Container still present)

All other tests should still pass.

**Step 4: Commit the failing tests**

```bash
git add test/widgets/reader_card_test.dart
git commit -m "test: update reader card tests for brandPale border and no left strip"
```

---

### Task 2: Update ReaderCard widget

**Files:**
- Modify: `lib/widgets/reader/reader_card.dart:36-56`

**Step 1: Replace `boxShadow` with `border` in BoxDecoration**

In `lib/widgets/reader/reader_card.dart`, find the `BoxDecoration` block (around line 37). Replace the entire `BoxDecoration` with:

```dart
decoration: BoxDecoration(
  color: AppTheme.surface,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppTheme.brandPale, width: 1.5),
),
```

The `boxShadow` list is removed entirely. Do not change `color` or `borderRadius`.

**Step 2: Remove the 3px left-strip Container**

Inside the `ClipRRect` → `Row`, delete this child entirely:

```dart
Container(
  width: 3,
  color: AppTheme.brand,
),
```

The `Row` should now contain only the single `Expanded` child with the text padding.

After both edits, the relevant section of `reader_card.dart` should look like:

```dart
Expanded(
  child: Container(
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.brandPale, width: 1.5),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
```

**Step 3: Run tests to verify they pass**

```bash
flutter test test/widgets/reader_card_test.dart --no-pub
```

Expected: all tests PASS. Count should remain the same as baseline (was 128 before this branch).

**Step 4: Run the full test suite**

```bash
flutter test --no-pub
```

Expected: all tests pass, 0 failures.

**Step 5: Commit**

```bash
git add lib/widgets/reader/reader_card.dart
git commit -m "feat: replace card glow/left strip with brandPale border"
```
