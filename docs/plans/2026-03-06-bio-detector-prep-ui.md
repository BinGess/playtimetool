# Bio Detector Prep UI Refresh Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 重构 Bio Detector 的准备态页面，借用 Gravity Balance 准备页的版式骨架，同时保留红黑警报式视觉气质。

**Architecture:** 仅修改 `BioDetectorScreen` 的 `setup` 分支，不改检测中、单轮结果和最终结果流程。通过重组准备态为 Hero 信息区、轮次设置区、惩罚设置区和底部强 CTA，提升信息层级和整体质感；必要时补充最少量本地化文案。

**Tech Stack:** Flutter, Material, AppLocalizations, Flutter widget test.

---

### Task 1: 锁定准备态新结构

**Files:**
- Modify: `test/bio_detector_screen_test.dart`
- Test: `test/bio_detector_screen_test.dart`

**Step 1: Write the failing test**
- 断言准备态存在新的 Hero 标题文案和轮次信息摘要。
- 保留现有轮次滑杆、惩罚预设和开始按钮断言，确保功能不退化。

**Step 2: Run test to verify it fails**
Run: `flutter test test/bio_detector_screen_test.dart`
Expected: FAIL（新结构文案尚未出现）

**Step 3: Write minimal implementation**
- 仅实现让测试通过所需的准备态版式重组和文案。

**Step 4: Run test to verify it passes**
Run: `flutter test test/bio_detector_screen_test.dart`
Expected: PASS

### Task 2: 重构准备态布局与视觉层级

**Files:**
- Modify: `lib/features/party_plus/bio_detector_screen.dart`
- Modify: `lib/l10n/app_localizations.dart`

**Step 1: Implement Hero 区**
- 增加“Bio-Scan / 准备检测”主视觉卡片。
- 用指纹图标、扫描线、状态芯片和说明文案形成主视觉，而不是把说明文字平铺在顶部。

**Step 2: Implement 设置分组**
- 将轮次控制做成独立卡片，突出当前轮次数值。
- 将 `PenaltyPresetCard` 放入单独分组卡片，保持现有逻辑和交互。

**Step 3: Implement 底部 CTA**
- 保留 `bio-detector-start-session` 键值和开始逻辑。
- 将 CTA 做成全宽高权重按钮，和准备态内容形成清晰的上下结构。

**Step 4: Refine responsive spacing**
- 确保在常见手机宽度上无溢出，滚动体验正常。

### Task 3: 回归验证

**Files:**
- Test: `test/bio_detector_screen_test.dart`

**Step 1: Run focused verification**
Run: `flutter test test/bio_detector_screen_test.dart`
Expected: PASS

**Step 2: Run analyzer on touched file if needed**
Run: `flutter analyze lib/features/party_plus/bio_detector_screen.dart`
Expected: no issues
