# Long-Press to Share Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the visible Positioned share button in the reader with a long-press gesture on the card, and add a new onboarding tip card that teaches users about it with a replaying animation.

**Architecture:** Two independent changes — (1) `ReaderScreen` drops `_currentIndex` state, wraps each `ReaderCard` in a `GestureDetector` with `onLongPress`, and removes the `Positioned` overlay; (2) `OnboardingScreen` gains a second `AnimationController` for a press-and-reveal animation, inserts a new card at position 3 (2nd to last), and updates all existing tests that assumed the style picker was at position 3.

**Tech Stack:** Flutter, Dart, `share_plus`, `AnimationController`, `TweenSequence`

---

### Task 1: Remove Positioned share button, add long-press to ReaderScreen

**Files:**
- Modify: `lib/screens/reader_screen.dart`
- Modify: `test/screens/reader_screen_test.dart`

**Context:** `_ReaderScreenState` currently tracks `_currentIndex` so the Positioned share button knows which chunk to share. With long-press, `index` is already in scope inside `itemBuilder`, so `_currentIndex` and its updates can be removed entirely. The Positioned share button is also removed. For vertical mode, the Stack reverts to returning a bare `pageView`.

**Current state of `_buildBody` end section (from `final style =` onwards):**

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
      right: 8,
      child: IconButton(
        icon: const Icon(Icons.share_outlined),
        color: AppTheme.pewter,
        onPressed: () => _share(_chunks[_currentIndex]),
      ),
    ),
  ],
);
```

---

**Step 1: Write failing test**

Add this test to the `group('ReaderScreen', ...)` block in `test/screens/reader_screen_test.dart`:

```dart
testWidgets('no share icon visible in reader (share via long press)', (tester) async {
  await tester.pumpWidget(_wrap());
  expect(find.byIcon(Icons.share_outlined), findsNothing);
});
```

**Step 2: Run test — verify it fails**

```bash
flutter test test/screens/reader_screen_test.dart
```

Expected: **FAIL** — `find.byIcon(Icons.share_outlined)` finds the Positioned `IconButton` in the loading-state widget tree.

**Step 3: Update `lib/screens/reader_screen.dart`**

**3a.** Remove the `_currentIndex` field. Find and delete this line (around line 32):
```dart
int _currentIndex = 0;
```

**3b.** Remove `_currentIndex = _startIndex;` from the `setState` block in `_loadReader`. Find:
```dart
setState(() {
  _chunks = chunks;
  _startIndex = savedIndex.clamp(0, chunks.length - 1);
  _currentIndex = _startIndex;
  _loading = false;
});
```
Replace with:
```dart
setState(() {
  _chunks = chunks;
  _startIndex = savedIndex.clamp(0, chunks.length - 1);
  _loading = false;
});
```

**3c.** Remove `setState(() => _currentIndex = index);` from `_onPageChanged`. Find:
```dart
void _onPageChanged(int index) {
  setState(() => _currentIndex = index);
  _debounceTimer?.cancel();
```
Replace with:
```dart
void _onPageChanged(int index) {
  _debounceTimer?.cancel();
```

**3d.** Replace the final section of `_buildBody` (from `final style =` to the closing `}` of `_buildBody`) with:

```dart
    final style = Provider.of<AppProvider>(context).readingStyle;
    final isHorizontal = style == 'horizontal';

    final pageView = PageView.builder(
      controller: _pageController,
      scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
      itemCount: _chunks.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (_, index) => GestureDetector(
        onLongPress: () => _share(_chunks[index]),
        child: ReaderCard(
          text: _chunks[index],
          chunkIndex: index,
          totalChunks: _chunks.length,
        ),
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

**Step 4: Run tests — verify they pass**

```bash
flutter test test/screens/reader_screen_test.dart
```

Expected: all tests pass including the new one.

**Step 5: Run full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/screens/reader_screen.dart test/screens/reader_screen_test.dart
git commit -m "Replace Positioned share button with long-press gesture on ReaderCard"
```

---

### Task 2: Add share tip onboarding card with animation

**Files:**
- Modify: `lib/screens/onboarding_screen.dart`
- Modify: `test/screens/onboarding_screen_test.dart`

**Context:** The onboarding currently has 4 cards (3 feature + 1 style picker). A new card is inserted at index 3 (2nd to last), pushing the style picker to index 4. `totalCards` becomes `_featureCards.length + 2 = 5`.

The existing `_scrollToStyleCard` test helper drags 3 times (indices 0→1→2→3). It now needs to drag 4 times to reach index 4. All tests using `_scrollToStyleCard` must keep working — updating that helper fixes them all at once.

A second `AnimationController` (`_shareController`) drives a press-indicator + share-icon animation on the new card. `SingleTickerProviderStateMixin` must change to `TickerProviderStateMixin` to support two controllers.

---

**Step 1: Write failing tests**

Add these to `test/screens/onboarding_screen_test.dart`.

First, update the `_scrollToStyleCard` helper — it needs one more drag now (4 drags for 5 cards):

```dart
Future<void> _scrollToStyleCard(WidgetTester tester) async {
  final pageView = find.byType(PageView);
  final size = tester.getSize(pageView);
  await tester.drag(pageView, Offset(0, -size.height));
  await tester.pumpAndSettle();
  await tester.drag(pageView, Offset(0, -size.height));
  await tester.pumpAndSettle();
  await tester.drag(pageView, Offset(0, -size.height));
  await tester.pumpAndSettle();
  await tester.drag(pageView, Offset(0, -size.height));
  await tester.pumpAndSettle();
}
```

Also add a new helper for navigating to the share tip card (3 drags):

```dart
Future<void> _scrollToShareCard(WidgetTester tester) async {
  final pageView = find.byType(PageView);
  final size = tester.getSize(pageView);
  await tester.drag(pageView, Offset(0, -size.height));
  await tester.pumpAndSettle();
  await tester.drag(pageView, Offset(0, -size.height));
  await tester.pumpAndSettle();
  await tester.drag(pageView, Offset(0, -size.height));
  await tester.pumpAndSettle();
}
```

Add this test inside `group('OnboardingScreen', ...)`:

```dart
testWidgets('4th card shows share tip headline', (tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  await _scrollToShareCard(tester);
  expect(find.text('Long press to share.'), findsOneWidget);
});
```

Also rename the existing `'4th card shows style picker headline'` test to `'5th card shows style picker headline'` to reflect the new position.

**Step 2: Run tests — verify they fail**

```bash
flutter test test/screens/onboarding_screen_test.dart
```

Expected: `'4th card shows share tip headline'` fails (card doesn't exist yet). The `'4th card shows style picker headline'` (now renamed `'5th card shows style picker headline'`) may also fail because `_scrollToStyleCard` now drags 4 times but the style picker is still at position 3.

**Step 3: Update `lib/screens/onboarding_screen.dart`**

Make the following changes in order:

**3a.** Change the mixin from `SingleTickerProviderStateMixin` to `TickerProviderStateMixin`:

Find:
```dart
class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
```
Replace with:
```dart
class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
```

**3b.** Add the share controller and animation fields after the existing animation fields (after `_horizontalIn` declaration):

```dart
  late final AnimationController _shareController;
  Timer? _sharePauseTimer;
  late final Animation<double> _pressOpacity;
  late final Animation<double> _pressScale;
  late final Animation<double> _shareIconOpacity;
```

**3c.** In `initState`, after the existing `_previewController` setup block (after `_previewController.forward();` and before the `_verticalOut =` line), add:

```dart
    _shareController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _shareController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _sharePauseTimer = Timer(const Duration(milliseconds: 600), () {
          if (mounted) {
            _shareController.reset();
            _shareController.forward();
          }
        });
      }
    });
    _pressOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
    ]).animate(_shareController);
    _pressScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(tween: ConstantTween(1.4), weight: 55),
    ]).animate(_shareController);
    _shareIconOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_shareController);
```

**3d.** In `dispose`, add before `_pageController.dispose();`:

```dart
    _sharePauseTimer?.cancel();
    _shareController.dispose();
```

**3e.** Replace the `onPageChanged` callback in `build`:

Find:
```dart
          onPageChanged: (i) {
            if (i == _featureCards.length) {
              _previewPauseTimer?.cancel();
              setState(() {
                _previewController.reset();
                _previewController.forward();
              });
            }
          },
```
Replace with:
```dart
          onPageChanged: (i) {
            _previewPauseTimer?.cancel();
            _sharePauseTimer?.cancel();
            if (i == _featureCards.length) {
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
            } else {
              setState(() {
                _shareController.reset();
                _previewController.reset();
              });
            }
          },
```

**3f.** Update `totalCards` and `itemBuilder` in `build`:

Find:
```dart
    final totalCards = _featureCards.length + 1;
```
Replace with:
```dart
    final totalCards = _featureCards.length + 2;
```

Find the `itemBuilder` child logic:
```dart
                child: isStylePicker
                    ? _buildStylePickerCard(totalCards)
                    : _buildFeatureCard(index, totalCards),
```
Replace with (and update the `isStylePicker` declaration above it):

Find:
```dart
            final isStylePicker = index == _featureCards.length;
            return Padding(
              ...
                child: isStylePicker
                    ? _buildStylePickerCard(totalCards)
                    : _buildFeatureCard(index, totalCards),
```
Replace with:
```dart
            final isShareCard = index == _featureCards.length;
            final isStylePicker = index == _featureCards.length + 1;
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
                    : isShareCard
                        ? _buildShareTipCard(totalCards)
                        : _buildFeatureCard(index, totalCards),
              ),
            );
```

Note: the `Padding` + `Container` wrapper is already in the `itemBuilder` — only the `child:` logic changes. Be careful not to duplicate the wrapper.

**3g.** Add the `_buildShareTipCard` method after `_buildFeatureCard` and before `_buildStylePickerCard`:

```dart
  Widget _buildShareTipCard(int totalCards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Icon(Icons.share_outlined, size: 56, color: AppTheme.amber),
        const SizedBox(height: 32),
        Text(
          'Long press to share.',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Hold any passage to share it with a friend.',
          style: GoogleFonts.dmSans(fontSize: 16, color: AppTheme.tobacco),
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
                          color: AppTheme.amber.withOpacity(0.25),
                          border: Border.all(
                            color: AppTheme.amber.withOpacity(0.6),
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
                      child: Icon(
                        Icons.share_outlined,
                        size: 14,
                        color: AppTheme.amber,
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

**Step 4: Run onboarding tests — verify they pass**

```bash
flutter test test/screens/onboarding_screen_test.dart
```

Expected: all 8 tests pass (7 existing + 1 new share tip test).

**Step 5: Run full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/screens/onboarding_screen.dart test/screens/onboarding_screen_test.dart
git commit -m "Add long-press share tip onboarding card with press-and-reveal animation"
```
