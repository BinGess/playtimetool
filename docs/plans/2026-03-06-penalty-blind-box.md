# Penalty Blind Box Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a shared penalty preset + blind-box reveal flow for all current games that already have both a setup page and a result page.

**Architecture:** Extend the shared penalty domain in `lib/shared/services/penalty_service.dart` with typed preset, entry, level, category, and blind-box resolution APIs while keeping legacy helpers intact. Add one shared setup widget and one shared result widget, then integrate each eligible game screen by storing a local preset in setup state and resolving blind-box cards once the loser list is known.

**Tech Stack:** Flutter, Riverpod where already used, `AppLocalizations`, Flutter unit tests, Flutter widget tests.

---

### Task 1: Add blind-box penalty domain models and resolver

**Files:**
- Modify: `lib/shared/services/penalty_service.dart`
- Test: `test/unit/shared/penalty_service_test.dart`

**Step 1: Write the failing test**

```dart
test('blind box draws three unique cards for a preset', () {
  final l10n = AppLocalizations(const Locale('zh'));
  final result = PenaltyService.resolveBlindBox(
    l10n: l10n,
    random: Random(1),
    preset: const PenaltyPreset(
      scene: PenaltyScene.home,
      intensity: PenaltyIntensity.wild,
    ),
    losers: const ['玩家1'],
  );

  expect(result.cards, hasLength(3));
  expect(result.cards.map((card) => card.entry.id).toSet().length, 3);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/shared/penalty_service_test.dart`
Expected: FAIL with missing blind-box models or API.

**Step 3: Write minimal implementation**

```dart
enum PenaltyScene { home, bar }
enum PenaltyIntensity { mild, wild, xtreme }
enum PenaltyCategory { physical, social, truth }
enum PenaltyLevel { level1, level2, level3 }

class PenaltyPreset {
  const PenaltyPreset({required this.scene, required this.intensity});
  final PenaltyScene scene;
  final PenaltyIntensity intensity;
}

class PenaltyBlindBoxResult {
  const PenaltyBlindBoxResult({required this.losers, required this.cards});
  final List<String> losers;
  final List<PenaltyBlindBoxCard> cards;
}
```

Add a minimal `resolveBlindBox(...)` implementation that returns three unique items from the preset scene pool.

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/shared/penalty_service_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/shared/services/penalty_service.dart test/unit/shared/penalty_service_test.dart
git commit -m "feat: add penalty blind box domain and resolver"
```

### Task 2: Cover probability mapping and fallback behavior

**Files:**
- Modify: `lib/shared/services/penalty_service.dart`
- Test: `test/unit/shared/penalty_service_test.dart`

**Step 1: Write the failing test**

```dart
test('mild preset only draws level1 cards', () {
  final l10n = AppLocalizations(const Locale('zh'));
  final result = PenaltyService.resolveBlindBox(
    l10n: l10n,
    random: Random(2),
    preset: const PenaltyPreset(
      scene: PenaltyScene.bar,
      intensity: PenaltyIntensity.mild,
    ),
    losers: const ['玩家1'],
  );

  expect(result.cards.every((card) => card.entry.level == PenaltyLevel.level1), isTrue);
});
```

Add another failing test for category diversity fallback.

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/shared/penalty_service_test.dart`
Expected: FAIL on level/category expectations.

**Step 3: Write minimal implementation**

Implement:

- intensity-to-level sampling
- prefer-distinct-category selection
- same-scene adjacent-level fallback
- generic fallback pool

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/shared/penalty_service_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/shared/services/penalty_service.dart test/unit/shared/penalty_service_test.dart
git commit -m "feat: add penalty blind box probability and fallback rules"
```

### Task 3: Add shared setup and result widgets

**Files:**
- Create: `lib/shared/widgets/penalty_preset_card.dart`
- Create: `lib/shared/widgets/penalty_blind_box_overlay.dart`
- Test: `test/widgets/penalty_blind_box_overlay_test.dart`

**Step 1: Write the failing test**

```dart
testWidgets('blind box overlay reveals one card and dims the others', (tester) async {
  await tester.pumpWidget(buildPenaltyBlindBoxTestApp());

  expect(find.byKey(const Key('penalty-card-back-0')), findsOneWidget);
  expect(find.byKey(const Key('penalty-card-back-1')), findsOneWidget);
  expect(find.byKey(const Key('penalty-card-back-2')), findsOneWidget);

  await tester.tap(find.byKey(const Key('penalty-card-back-1')));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('penalty-card-front-1')), findsOneWidget);
  expect(find.textContaining('错过'), findsNothing);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/penalty_blind_box_overlay_test.dart`
Expected: FAIL because shared widgets do not exist.

**Step 3: Write minimal implementation**

Implement:

- `PenaltyPresetCard` with scene and intensity selectors
- `PenaltyBlindBoxOverlay` with three cards, reveal animation, and dimmed non-selected cards

**Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/penalty_blind_box_overlay_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/shared/widgets/penalty_preset_card.dart lib/shared/widgets/penalty_blind_box_overlay.dart test/widgets/penalty_blind_box_overlay_test.dart
git commit -m "feat: add penalty preset and blind box widgets"
```

### Task 4: Integrate party-plus setup/result screens

**Files:**
- Modify: `lib/features/party_plus/bomb_pass_screen.dart`
- Modify: `lib/features/party_plus/gesture_duel_screen.dart`
- Modify: `lib/features/party_plus/left_right_react_screen.dart`
- Modify: `lib/features/party_plus/truth_or_raise_screen.dart`
- Modify: `lib/features/party_plus/bio_detector_screen.dart`
- Test: `test/gesture_duel_screen_test.dart`
- Test: `test/left_right_react_screen_test.dart`
- Create: `test/bio_detector_screen_test.dart`

**Step 1: Write the failing test**

Add widget expectations that:

- setup page renders `PenaltyPresetCard`
- result page renders blind-box cards when losers exist
- no blind box renders when the game ends without losers

**Step 2: Run test to verify it fails**

Run:

- `flutter test test/gesture_duel_screen_test.dart`
- `flutter test test/left_right_react_screen_test.dart`
- `flutter test test/bio_detector_screen_test.dart`

Expected: FAIL on missing preset card or blind-box overlay.

**Step 3: Write minimal implementation**

For each screen:

- add local `PenaltyPreset _penaltyPreset`
- render `PenaltyPresetCard` above start button
- resolve blind-box result once loser list is known
- replace direct penalty text rendering with `PenaltyBlindBoxOverlay`
- keep existing action bar behavior

**Step 4: Run test to verify it passes**

Run the same tests as step 2.
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/party_plus test/gesture_duel_screen_test.dart test/left_right_react_screen_test.dart test/bio_detector_screen_test.dart
git commit -m "feat: integrate penalty blind box into party plus games"
```

### Task 5: Integrate number bomb and decibel bomb

**Files:**
- Modify: `lib/features/number_bomb/number_bomb_screen.dart`
- Modify: `lib/features/decibel_bomb/decibel_bomb_screen.dart`
- Test: `test/widget_test.dart`
- Create: `test/decibel_bomb_screen_test.dart`

**Step 1: Write the failing test**

Add widget tests that:

- setup pages render `PenaltyPresetCard`
- explosion results show blind-box cards instead of a plain penalty sentence

**Step 2: Run test to verify it fails**

Run:

- `flutter test test/widget_test.dart`
- `flutter test test/decibel_bomb_screen_test.dart`

Expected: FAIL on missing preset card or overlay.

**Step 3: Write minimal implementation**

Update both screens to:

- carry preset through setup/start
- resolve loser names on explosion
- present `PenaltyBlindBoxOverlay`

**Step 4: Run test to verify it passes**

Run the same tests as step 2.
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/number_bomb/number_bomb_screen.dart lib/features/decibel_bomb/decibel_bomb_screen.dart test/widget_test.dart test/decibel_bomb_screen_test.dart
git commit -m "feat: integrate penalty blind box into bomb games"
```

### Task 6: Verify localization and final regressions

**Files:**
- Modify if needed: `lib/l10n/app_localizations.dart`
- Modify if needed: impacted tests

**Step 1: Write the failing test**

Add assertions for new labels:

- `惩罚预设`
- `居家模式`
- `酒吧模式`
- `热身`
- `进阶`
- `极限`
- `命运抉择`

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/shared/penalty_service_test.dart`
Expected: FAIL on missing localization keys or display text.

**Step 3: Write minimal implementation**

Add the required localized strings and adjust widget labels to use them.

**Step 4: Run test to verify it passes**

Run:

- `flutter test test/unit/shared/penalty_service_test.dart`
- `flutter test test/gesture_duel_screen_test.dart`
- `flutter test test/left_right_react_screen_test.dart`
- `flutter test test/bio_detector_screen_test.dart`
- `flutter test test/decibel_bomb_screen_test.dart`
- `flutter analyze`

Expected: PASS.

**Step 5: Commit**

```bash
git add lib/l10n/app_localizations.dart test
git commit -m "test: verify penalty blind box localization and regressions"
```
