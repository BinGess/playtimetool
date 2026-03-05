# Bio-Detector Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 新增 Bio-Detector 游戏，完整实现伪检测流程、隐藏操纵杆与结果页表现，并接入 Hub/路由/本地化。

**Architecture:** 采用 UI + logic 分层。`bio_detector_logic.dart` 负责阶段推进、隐藏操纵杆结果决策与告警/提示序列；`bio_detector_screen.dart` 负责动画、手势、绘制和震动调度。通过 router/hub/l10n 接入主应用。

**Tech Stack:** Flutter, go_router, 现有 HapticService, AppLocalizations, Flutter test.

---

### Task 1: 编写逻辑层失败测试并实现

**Files:**
- Create: `lib/features/party_plus/logic/bio_detector_logic.dart`
- Test: `test/unit/party_plus/bio_detector_logic_test.dart`

**Step 1: Write the failing test**
- 覆盖：
  - 左上触发 => TRUTH
  - 右下触发 => LIE
  - 无触发时随机决策依赖随机布尔值
  - 阶段切换：0-5-10 秒

**Step 2: Run test to verify it fails**
Run: `flutter test test/unit/party_plus/bio_detector_logic_test.dart`
Expected: FAIL（文件/类型不存在）

**Step 3: Write minimal implementation**
- 新建 `BioDetectorResult`、`BioDetectorCheatOverride`、`BioDetectorPhase`。
- 实现 `resolveBioDetectorResult()` 与 `phaseForElapsed()`。

**Step 4: Run test to verify it passes**
Run: `flutter test test/unit/party_plus/bio_detector_logic_test.dart`
Expected: PASS

### Task 2: 页面与动效实现

**Files:**
- Create: `lib/features/party_plus/bio_detector_screen.dart`
- Test: `test/bio_detector_screen_test.dart`

**Step 1: Write the failing test**
- 初始显示“长按开始检测”按钮
- 长按后出现 `Initializing Bio-Link...`

**Step 2: Run test to verify it fails**
Run: `flutter test test/bio_detector_screen_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**
- 完成页面状态机、手势、计时器、动画控制器、结果渲染。
- 实现扫描线/网格/脉搏波 painter。

**Step 4: Run test to verify it passes**
Run: `flutter test test/bio_detector_screen_test.dart`
Expected: PASS

### Task 3: 应用接入与回归

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/hub/hub_screen.dart`
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `test/hub_screen_test.dart`

**Step 1: Write/adjust failing test**
- Hub 页面可见 Bio-Detector 卡片标题。

**Step 2: Run targeted tests to verify failures/passing**
Run:
- `flutter test test/hub_screen_test.dart`

**Step 3: Implement integration**
- 加路由 `/games/bio-detector`
- Hub 新增游戏项
- 增补 zh/en 文案（标题、副标题、描述、帮助）

**Step 4: Verification**
Run:
- `flutter test test/unit/party_plus/bio_detector_logic_test.dart`
- `flutter test test/bio_detector_screen_test.dart`
- `flutter test test/hub_screen_test.dart`
