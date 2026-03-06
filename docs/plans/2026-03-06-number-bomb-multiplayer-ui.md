# Number Bomb Multiplayer UI Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将数字炸弹扩展为多人轮流游玩的模式，并重做准备页版式，使其参考 Gravity Balance 的准备页结构，同时在进行中与结果页展示当前玩家和本轮输家/获胜信息。

**Architecture:** 继续使用 `BombState` + `NumberBombNotifier` 管理状态。状态层新增玩家人数、当前回合玩家和输家信息，保持爆炸即结束的规则；界面层在 `NumberBombScreen` 中分别重构 `setup`、`playing` 和 `explosion` 三个分支以反映多人模式。

**Tech Stack:** Flutter, flutter_riverpod, AppLocalizations, Flutter test.

---

### Task 1: 锁定多人状态机行为

**Files:**
- Modify: `test/unit/number_bomb_test.dart`
- Test: `test/unit/number_bomb_test.dart`

**Step 1: Write the failing test**
- 断言开始游戏时可设置玩家人数。
- 断言有效但未爆炸的猜测会把回合切到下一位玩家。
- 断言踩中炸弹时记录输家玩家编号并进入爆炸态。

**Step 2: Run test to verify it fails**
Run: `flutter test test/unit/number_bomb_test.dart`
Expected: FAIL（状态尚未支持多人字段/轮转）

**Step 3: Write minimal implementation**
- 在 `BombState` 中新增玩家人数、当前玩家、输家玩家等字段。
- 在 `NumberBombNotifier` 中更新 `startGame()` 和 `confirmGuess()` 逻辑。

**Step 4: Run test to verify it passes**
Run: `flutter test test/unit/number_bomb_test.dart`
Expected: PASS

### Task 2: 锁定准备页与结果页核心文案

**Files:**
- Create: `test/number_bomb_screen_test.dart`
- Test: `test/number_bomb_screen_test.dart`

**Step 1: Write the failing test**
- 准备页显示玩家人数设置与新的 Hero 文案。
- 进入进行中后显示当前玩家。
- 爆炸后结果层显示输家信息。

**Step 2: Run test to verify it fails**
Run: `flutter test test/number_bomb_screen_test.dart`
Expected: FAIL（UI 尚未反映多人信息）

**Step 3: Write minimal implementation**
- 仅补足通过测试所需的准备页、进行中提示和结果页文案展示。

**Step 4: Run test to verify it passes**
Run: `flutter test test/number_bomb_screen_test.dart`
Expected: PASS

### Task 3: 重构准备页与结算呈现

**Files:**
- Modify: `lib/features/number_bomb/number_bomb_screen.dart`
- Modify: `lib/l10n/app_localizations.dart`

**Step 1: Implement prep layout**
- 新增 Hero 区、玩家人数设置区、范围设置区、惩罚联动区、底部 CTA。
- 保持数字炸弹现有红色高压风格。

**Step 2: Implement multiplayer run-state UI**
- 进行中在顶部明确展示当前玩家。
- 结果页展示本轮输家和其余玩家获胜提示。

**Step 3: Keep existing game flow intact**
- 保持输入键盘、区间收缩、爆炸动画、惩罚盲盒逻辑。

### Task 4: 验证

**Files:**
- Test: `test/unit/number_bomb_test.dart`
- Test: `test/number_bomb_screen_test.dart`

**Step 1: Run focused tests**
Run:
- `flutter test test/unit/number_bomb_test.dart`
- `flutter test test/number_bomb_screen_test.dart`
Expected: PASS

**Step 2: Run analyzer on touched files**
Run:
- `flutter analyze lib/features/number_bomb/number_bomb_screen.dart lib/features/number_bomb/models/bomb_state.dart lib/features/number_bomb/providers/number_bomb_provider.dart lib/l10n/app_localizations.dart test/unit/number_bomb_test.dart test/number_bomb_screen_test.dart`
Expected: no issues
