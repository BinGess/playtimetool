# Unified Penalty Service Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Route all game result-page penalty copy through one shared service that chooses penalty content by language and global alcohol/pure mode.

**Architecture:** Add a shared `PenaltyService` in `lib/shared/services` as the single source of truth for penalty pools and formatting helpers. Migrate each result page to call this service (random penalties, score/rule penalties, guidance penalties), and remove Number Bomb's local hardcoded penalty list.

**Tech Stack:** Flutter, Riverpod, existing `AppLocalizations`, Flutter unit/widget tests.

---

### Task 1: Add unified penalty service API and pool

**Files:**
- Create: `lib/shared/services/penalty_service.dart`
- Test: `test/unit/shared/penalty_service_test.dart`

**Steps:**
1. Write failing tests for:
   - alcohol mode only returns alcohol pool item ids
   - pure mode only returns pure pool item ids
   - score-based/rule-based helpers produce expected localized text
2. Run `flutter test test/unit/shared/penalty_service_test.dart` and confirm RED.
3. Implement minimal `PenaltyService` and `PenaltyPlan`.
4. Re-run same test and confirm GREEN.

### Task 2: Migrate random-penalty game result pages

**Files:**
- Modify: `lib/features/party_plus/bomb_pass_screen.dart`
- Modify: `lib/features/party_plus/word_chain_bomb_screen.dart`
- Modify: `lib/features/party_plus/gesture_duel_screen.dart`
- Modify: `lib/features/number_bomb/providers/number_bomb_provider.dart`
- Modify: `lib/features/number_bomb/models/bomb_state.dart`
- Modify: `lib/features/number_bomb/number_bomb_screen.dart`

**Steps:**
1. Keep behavior the same but fetch penalties from `PenaltyService`.
2. Remove Number Bomb local hardcoded `_punishments` list and `randomPunishment()`.
3. Ensure Number Bomb explosion penalty is assigned through the shared service path.
4. Run targeted tests:
   - `flutter test test/unit/number_bomb_test.dart`
   - `flutter test test/word_chain_bomb_screen_test.dart`

### Task 3: Migrate rule/guidance result pages

**Files:**
- Modify: `lib/features/party_plus/left_right_react_screen.dart`
- Modify: `lib/features/party_plus/truth_or_raise_screen.dart`
- Modify: `lib/features/party_plus/challenge_auction_screen.dart`
- Modify: `lib/features/finger_picker/finger_picker_screen.dart`
- Modify: `lib/features/spin_wheel/spin_wheel_screen.dart`

**Steps:**
1. Replace direct l10n penalty formatting in result pages with `PenaltyService` helpers.
2. Keep existing gameplay logic and stage flow unchanged.
3. Run targeted tests:
   - `flutter test test/spin_wheel_layout_test.dart`
   - `flutter test test/gesture_duel_screen_test.dart`

### Task 4: Verify and stabilize

**Files:**
- Modify if needed: impacted tests and imports

**Steps:**
1. Run `flutter analyze` on changed files.
2. Run `flutter test` (full suite) and capture unrelated pre-existing failures separately.
3. Summarize migration coverage per game screen.
