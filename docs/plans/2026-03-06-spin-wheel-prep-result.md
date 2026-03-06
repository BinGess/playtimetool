# Spin Wheel Prep Result Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a dedicated preparation view and richer result presentation to the spin wheel game.

**Architecture:** Keep wheel physics and provider state intact, and add a local setup flow in `SpinWheelScreen`. Preparation UI owns visible configuration and penalty preset selection; result UI consumes the chosen segment plus a generated penalty blind-box result.

**Tech Stack:** Flutter, Riverpod, existing game UI components, widget tests

---

### Task 1: Document And Lock The UX

**Files:**
- Create: `docs/plans/2026-03-06-spin-wheel-prep-result-design.md`
- Create: `docs/plans/2026-03-06-spin-wheel-prep-result.md`

**Step 1: Write the design doc**

Describe:
- prep-first flow
- visible setup controls
- up-to-6-player reminder
- penalty preset placement
- selected-color result presentation

**Step 2: Save the implementation plan**

List the screen, localization, and test work needed.

**Step 3: Commit later with code**

Keep docs in the same implementation commit unless user requests otherwise.

### Task 2: Add Failing Widget Tests

**Files:**
- Modify: `test/spin_wheel_layout_test.dart`

**Step 1: Write a failing setup test**

Cover:
- setup copy is visible
- no player count control is shown
- penalty preset card is visible
- start button is visible

**Step 2: Write a failing result widget test**

Cover:
- selected option text is visible
- selected color section is visible
- blind-box penalty component is visible

**Step 3: Run the focused test file**

Run: `flutter test test/spin_wheel_layout_test.dart`

Expected: fail because the current screen lacks the new setup/result UI.

### Task 3: Implement Screen Redesign

**Files:**
- Modify: `lib/features/spin_wheel/spin_wheel_screen.dart`
- Modify: `lib/l10n/app_localizations.dart`

**Step 1: Add local setup state**

Start the screen in a preparation phase and gate the wheel view behind the start button.

**Step 2: Move setup controls into the preparation body**

Add:
- preset selector
- prank/fair toggle
- edit button
- reminder card for up to 6 players
- penalty preset card

**Step 3: Add richer result content**

Update the result overlay to include:
- selected option label
- selected color swatch + hex
- punishment summary
- `PenaltyBlindBoxOverlay`

**Step 4: Add needed localization strings**

Add new prep/result labels in Chinese and English.

### Task 4: Verify

**Files:**
- Modify: `test/spin_wheel_layout_test.dart`

**Step 1: Run focused widget tests**

Run: `flutter test test/spin_wheel_layout_test.dart`

Expected: pass

**Step 2: Run related validation**

Run: `flutter analyze`

Expected: no new errors

**Step 3: Build app targets**

Run:
- `flutter build apk --debug`
- `flutter build ios --debug --simulator --no-codesign`

Expected: both succeed
