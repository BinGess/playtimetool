# Penalty Plugin System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a reusable penalty plugin system for all punishable games, with country/difficulty/scale controls and result-page manual/random selection.

**Architecture:** Replace ad-hoc `PartyPlusStrings.randomPenalty(...)` usage with a typed penalty domain model and plugin registry. Each game result page calls one shared `PenaltyResolver` API that reads runtime policy (`country`, `difficulty`, `scale`, `selection mode`) and returns a penalty suggestion list plus selected item. UI selection happens in a shared result-sheet widget, while settings provide default policy and a global alcohol-safe gate.

**Tech Stack:** Flutter, Riverpod, SharedPreferences, existing `AppLocalizations`, Flutter test/widget test.

---

## Scope And Assumptions

- In scope:
  - Support punishable game result flows: `pass_bomb`, `gesture_duel`, `word_bomb`, `left_right`, `truth_raise`, `challenge_auction`.
  - Support policy dimensions: country, difficulty, scale, selection mode (manual/random).
  - Keep existing `alcoholPenaltyEnabled` as hard gate (off => only non-alcohol items).
  - Result page supports: pick from list, random one-click, reroll random.
- Out of scope (phase 1):
  - Network-loaded plugins, user-generated plugin editing UI, cloud sync.
  - Complex moderation pipeline.

## Proposed Domain Model (Phase 1)

- `PenaltyCountry`: `cn`, `us` (can extend later).
- `PenaltyDifficulty`: `easy`, `normal`, `hard`.
- `PenaltyScale`: `light`, `medium`, `wild`.
- `PenaltySelectionMode`: `manual`, `random`.
- `PenaltyKind`: `alcohol`, `clean`, `mixed`.
- `PenaltyItem`:
  - `id`, `country`, `difficulty`, `scale`, `kind`, `textKey`, `tags`.
- `PenaltyPolicy`:
  - `country`, `difficulty`, `scale`, `selectionMode`, `alcoholEnabled`.
- `PenaltyContext`:
  - `gameId`, `loserCount`, `round`, `extra`.

## Shared UX Contract

- On result page for punishable modes:
  - Show “Penalty Card” with selected penalty text.
  - Show quick chips: country, difficulty, scale.
  - Show actions:
    - `Random` (respect policy and alcohol gate).
    - `Choose` (open sheet list for manual pick).
    - `Apply` (confirm final result text).
- If no candidate exists under strict filter:
  - fallback priority:
    1. same country + loosen scale
    2. same country + any scale/difficulty
    3. global clean fallback pool

---

### Task 1: Create Penalty Domain + Registry Skeleton

**Files:**
- Create: `lib/features/penalty_plugin/domain/penalty_models.dart`
- Create: `lib/features/penalty_plugin/domain/penalty_policy.dart`
- Create: `lib/features/penalty_plugin/domain/penalty_plugin.dart`
- Create: `lib/features/penalty_plugin/domain/penalty_registry.dart`
- Test: `test/unit/penalty_plugin/penalty_registry_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/penalty_plugin/domain/penalty_registry.dart';
import 'package:playtimetool/features/penalty_plugin/domain/penalty_plugin.dart';

void main() {
  test('registry returns plugin by country', () {
    final registry = PenaltyRegistry([
      InMemoryPenaltyPlugin(country: PenaltyCountry.cn, items: []),
      InMemoryPenaltyPlugin(country: PenaltyCountry.us, items: []),
    ]);

    final plugin = registry.requireByCountry(PenaltyCountry.us);
    expect(plugin.country, PenaltyCountry.us);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/penalty_plugin/penalty_registry_test.dart`
Expected: FAIL with missing types/files.

**Step 3: Write minimal implementation**

```dart
class PenaltyRegistry {
  PenaltyRegistry(this.plugins);
  final List<PenaltyPlugin> plugins;

  PenaltyPlugin requireByCountry(PenaltyCountry country) {
    return plugins.firstWhere((p) => p.country == country);
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/penalty_plugin/penalty_registry_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/penalty_plugin/domain test/unit/penalty_plugin/penalty_registry_test.dart
git commit -m "feat: add penalty plugin domain and registry skeleton"
```

### Task 2: Add Built-in Country Plugins (CN/US) + Localization Keys

**Files:**
- Create: `lib/features/penalty_plugin/plugins/cn_penalty_plugin.dart`
- Create: `lib/features/penalty_plugin/plugins/us_penalty_plugin.dart`
- Modify: `lib/l10n/app_localizations.dart`
- Test: `test/unit/penalty_plugin/country_plugins_test.dart`

**Step 1: Write the failing test**

```dart
test('cn plugin exposes clean and alcohol items in all scale tiers', () {
  final plugin = CnPenaltyPlugin();
  final all = plugin.items;

  expect(all.any((e) => e.kind == PenaltyKind.clean), true);
  expect(all.any((e) => e.kind == PenaltyKind.alcohol), true);
  expect(all.any((e) => e.scale == PenaltyScale.light), true);
  expect(all.any((e) => e.scale == PenaltyScale.medium), true);
  expect(all.any((e) => e.scale == PenaltyScale.wild), true);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/penalty_plugin/country_plugins_test.dart`
Expected: FAIL due to missing plugin classes.

**Step 3: Write minimal implementation**

```dart
class CnPenaltyPlugin implements PenaltyPlugin {
  @override
  PenaltyCountry get country => PenaltyCountry.cn;

  @override
  List<PenaltyItem> get items => [
        PenaltyItem(
          id: 'cn_clean_squat_8',
          country: PenaltyCountry.cn,
          difficulty: PenaltyDifficulty.easy,
          scale: PenaltyScale.light,
          kind: PenaltyKind.clean,
          textKey: 'penaltyCnCleanSquat8',
          tags: const ['fitness'],
        ),
      ];
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/penalty_plugin/country_plugins_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/penalty_plugin/plugins lib/l10n/app_localizations.dart test/unit/penalty_plugin/country_plugins_test.dart
git commit -m "feat: add built-in cn/us penalty plugins and localization keys"
```

### Task 3: Implement Penalty Resolver (Filter + Fallback + Random)

**Files:**
- Create: `lib/features/penalty_plugin/application/penalty_resolver.dart`
- Test: `test/unit/penalty_plugin/penalty_resolver_test.dart`

**Step 1: Write the failing test**

```dart
test('resolver excludes alcohol items when alcohol gate is off', () {
  final resolver = PenaltyResolver(registry: fakeRegistryWithMixedItems());
  final result = resolver.resolve(
    policy: const PenaltyPolicy(
      country: PenaltyCountry.cn,
      difficulty: PenaltyDifficulty.normal,
      scale: PenaltyScale.medium,
      selectionMode: PenaltySelectionMode.random,
      alcoholEnabled: false,
    ),
    context: const PenaltyContext(gameId: 'pass_bomb', loserCount: 1, round: 1),
    random: Random(1),
  );

  expect(result.selected.kind == PenaltyKind.clean || result.selected.kind == PenaltyKind.mixed, true);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/penalty_plugin/penalty_resolver_test.dart`
Expected: FAIL (resolver not implemented).

**Step 3: Write minimal implementation**

```dart
class PenaltyResolver {
  PenaltyResolver({required this.registry});
  final PenaltyRegistry registry;

  PenaltyResolution resolve({
    required PenaltyPolicy policy,
    required PenaltyContext context,
    required Random random,
  }) {
    final plugin = registry.requireByCountry(policy.country);
    final filtered = plugin.items.where((item) {
      if (!policy.alcoholEnabled && item.kind == PenaltyKind.alcohol) return false;
      return item.difficulty == policy.difficulty && item.scale == policy.scale;
    }).toList();

    final pool = filtered.isEmpty ? _fallbackPool(plugin, policy) : filtered;
    final selected = pool[random.nextInt(pool.length)];
    return PenaltyResolution(candidates: pool, selected: selected);
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/penalty_plugin/penalty_resolver_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/penalty_plugin/application/penalty_resolver.dart test/unit/penalty_plugin/penalty_resolver_test.dart
git commit -m "feat: add penalty resolver with policy filtering and fallback"
```

### Task 4: Add Penalty Policy To Settings (Defaults)

**Files:**
- Modify: `lib/features/settings/providers/settings_provider.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `lib/l10n/app_localizations.dart`
- Test: `test/unit/settings/penalty_policy_settings_test.dart`

**Step 1: Write the failing test**

```dart
test('settings persists default penalty policy fields', () async {
  final notifier = SettingsNotifier();
  final state = await notifier.build();

  expect(state.defaultPenaltyCountry, PenaltyCountry.cn);
  expect(state.defaultPenaltyDifficulty, PenaltyDifficulty.normal);
  expect(state.defaultPenaltyScale, PenaltyScale.medium);
  expect(state.defaultPenaltySelectionMode, PenaltySelectionMode.random);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/settings/penalty_policy_settings_test.dart`
Expected: FAIL due to missing fields/persistence keys.

**Step 3: Write minimal implementation**

```dart
class AppSettings {
  const AppSettings({
    // existing
    this.defaultPenaltyCountry = PenaltyCountry.cn,
    this.defaultPenaltyDifficulty = PenaltyDifficulty.normal,
    this.defaultPenaltyScale = PenaltyScale.medium,
    this.defaultPenaltySelectionMode = PenaltySelectionMode.random,
  });
}
```

Add toggle/setter methods + SharedPreferences keys:
- `penaltyCountry`
- `penaltyDifficulty`
- `penaltyScale`
- `penaltySelectionMode`

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/settings/penalty_policy_settings_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/settings/providers/settings_provider.dart lib/features/settings/settings_screen.dart lib/l10n/app_localizations.dart test/unit/settings/penalty_policy_settings_test.dart
git commit -m "feat: persist default penalty policy in settings"
```

### Task 5: Build Shared Result-Sheet UI For Penalty Selection

**Files:**
- Create: `lib/features/penalty_plugin/presentation/penalty_picker_sheet.dart`
- Create: `lib/features/penalty_plugin/presentation/penalty_result_card.dart`
- Test: `test/widget/penalty_plugin/penalty_picker_sheet_test.dart`

**Step 1: Write the failing test**

```dart
testWidgets('penalty picker supports random and manual selection', (tester) async {
  await tester.pumpWidget(buildPenaltyPickerHost());

  expect(find.text('Random'), findsOneWidget);
  await tester.tap(find.text('Random'));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('penalty-selected-item')), findsOneWidget);
  await tester.tap(find.byKey(const Key('penalty-choose-button')));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('penalty-item-list')), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/widget/penalty_plugin/penalty_picker_sheet_test.dart`
Expected: FAIL (widget missing).

**Step 3: Write minimal implementation**

```dart
Future<PenaltyItem?> showPenaltyPickerSheet(
  BuildContext context, {
  required PenaltyResolution initial,
  required VoidCallback onRandom,
}) async {
  return showModalBottomSheet<PenaltyItem>(
    context: context,
    builder: (_) => PenaltyPickerSheet(initial: initial, onRandom: onRandom),
  );
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/widget/penalty_plugin/penalty_picker_sheet_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/penalty_plugin/presentation test/widget/penalty_plugin/penalty_picker_sheet_test.dart
git commit -m "feat: add reusable penalty picker result sheet"
```

### Task 6: Integrate Shared Penalty Flow Into Bomb Pass + Word Bomb

**Files:**
- Modify: `lib/features/party_plus/bomb_pass_screen.dart`
- Modify: `lib/features/party_plus/word_chain_bomb_screen.dart`
- Modify: `lib/features/party_plus/party_plus_strings.dart` (remove random source responsibility)
- Test: `test/widget/party_plus/penalty_integration_bomb_word_test.dart`

**Step 1: Write the failing test**

```dart
testWidgets('bomb pass result can reroll penalty from picker', (tester) async {
  await tester.pumpWidget(buildBombPassScenario());
  await tester.tap(find.byKey(const Key('open-penalty-picker')));
  await tester.pumpAndSettle();

  final before = tester.widget<Text>(find.byKey(const Key('penalty-selected-item'))).data;
  await tester.tap(find.text('Random'));
  await tester.pumpAndSettle();
  final after = tester.widget<Text>(find.byKey(const Key('penalty-selected-item'))).data;

  expect(after, isNot(equals(before)));
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/widget/party_plus/penalty_integration_bomb_word_test.dart`
Expected: FAIL with missing picker integration.

**Step 3: Write minimal implementation**

- Replace `_penalty = PartyPlusStrings.randomPenalty(...)` with resolver call.
- Add button key: `open-penalty-picker`.
- Store selected `PenaltyItem` in state and render localized text from `textKey`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/widget/party_plus/penalty_integration_bomb_word_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/party_plus/bomb_pass_screen.dart lib/features/party_plus/word_chain_bomb_screen.dart lib/features/party_plus/party_plus_strings.dart test/widget/party_plus/penalty_integration_bomb_word_test.dart
git commit -m "feat: integrate penalty picker into bomb pass and word bomb results"
```

### Task 7: Integrate Shared Penalty Flow Into Gesture Duel + Left Right + Truth Raise + Challenge Auction

**Files:**
- Modify: `lib/features/party_plus/gesture_duel_screen.dart`
- Modify: `lib/features/party_plus/left_right_react_screen.dart`
- Modify: `lib/features/party_plus/truth_or_raise_screen.dart`
- Modify: `lib/features/party_plus/challenge_auction_screen.dart`
- Test: `test/widget/party_plus/penalty_integration_other_modes_test.dart`

**Step 1: Write the failing test**

```dart
testWidgets('gesture duel final result supports penalty picker actions', (tester) async {
  await tester.pumpWidget(buildGestureDuelResultScenario());

  expect(find.byKey(const Key('open-penalty-picker')), findsOneWidget);
  await tester.tap(find.byKey(const Key('open-penalty-picker')));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('penalty-item-list')), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/widget/party_plus/penalty_integration_other_modes_test.dart`
Expected: FAIL until integration is added.

**Step 3: Write minimal implementation**

- In each result flow, map game-specific loser/winner data into `PenaltyContext`.
- Use shared resolver + picker sheet.
- Keep existing scoring logic unchanged; only replace penalty text generation.

**Step 4: Run test to verify it passes**

Run: `flutter test test/widget/party_plus/penalty_integration_other_modes_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/party_plus/gesture_duel_screen.dart lib/features/party_plus/left_right_react_screen.dart lib/features/party_plus/truth_or_raise_screen.dart lib/features/party_plus/challenge_auction_screen.dart test/widget/party_plus/penalty_integration_other_modes_test.dart
git commit -m "feat: roll out shared penalty plugin flow across remaining party modes"
```

### Task 8: Backward Compatibility + Cleanup + Full Verification

**Files:**
- Modify: `lib/features/party_plus/party_plus_strings.dart` (deprecate or remove penalty random API)
- Modify: `lib/l10n/app_localizations.dart` (remove obsolete keys only if unused)
- Modify: `docs/plans/2026-03-05-penalty-plugin-system.md` (mark done sections if needed)
- Test: `test/unit/party_plus/party_plus_strings_test.dart` (adapt/remove)

**Step 1: Write the failing test**

```dart
test('legacy randomPenalty path is not used by result screens', () async {
  // static usage guard via simple string scan helper
  final result = await findUsages('PartyPlusStrings.randomPenalty(');
  expect(result, isEmpty);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/party_plus/party_plus_strings_test.dart`
Expected: FAIL while legacy path still exists.

**Step 3: Write minimal implementation**

- Replace remaining callsites.
- Keep a tiny compatibility wrapper only if needed by old tests.

**Step 4: Run test to verify it passes**

Run:
- `flutter test`
- `flutter analyze`
Expected: all PASS, no analyzer errors.

**Step 5: Commit**

```bash
git add lib test docs/plans/2026-03-05-penalty-plugin-system.md
git commit -m "refactor: finalize penalty plugin migration and remove legacy penalty path"
```

---

## Rollout Notes

- Phase rollout recommendation:
  1. ship domain+resolver hidden behind one game (`pass_bomb`) feature flag
  2. expand to all party modes after one internal test round
- Suggested feature flag key (SharedPreferences): `penaltyPluginEnabled`

## Risk Checklist

- Localization drift risk when adding many penalty keys across zh/en.
- Result page layout risk on small screens due to added control chips.
- Regression risk in existing scoring logic; keep logic unit tests unchanged and only add integration tests around penalty selection.

## Verification Checklist

- `flutter test test/unit/penalty_plugin`
- `flutter test test/widget/penalty_plugin`
- `flutter test test/widget/party_plus/penalty_integration_bomb_word_test.dart`
- `flutter test test/widget/party_plus/penalty_integration_other_modes_test.dart`
- `flutter test`
- `flutter analyze`
