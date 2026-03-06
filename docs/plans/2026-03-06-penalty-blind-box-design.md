# 惩罚盲盒设计说明

**日期：** 2026-03-06  
**范围：** 为当前具备准备页和结果页的小游戏接入统一惩罚预设与盲盒翻牌结算

---

## 1. 目标

为小游戏提供统一的惩罚闭环：

1. 准备阶段允许用户设置惩罚预设。
2. 游戏阶段保留原有玩法逻辑。
3. 结算阶段在已知输家后进入惩罚盲盒揭晓流程。

本次只实现核心闭环，不实现免死金牌、语音播报、拍照存证。

---

## 2. 接入范围

本次纳入：

- `lib/features/party_plus/bomb_pass_screen.dart`
- `lib/features/party_plus/gesture_duel_screen.dart`
- `lib/features/party_plus/left_right_react_screen.dart`
- `lib/features/party_plus/truth_or_raise_screen.dart`
- `lib/features/party_plus/bio_detector_screen.dart`
- `lib/features/number_bomb/number_bomb_screen.dart`
- `lib/features/decibel_bomb/decibel_bomb_screen.dart`

本次不纳入：

- `lib/features/finger_picker/finger_picker_screen.dart`
- `lib/features/spin_wheel/spin_wheel_screen.dart`
- `lib/features/gravity_balance/gravity_balance_screen.dart`

原因：这三个页面当前没有稳定的“准备页配置 + 输家结算”结构，硬接会变成玩法改造。

---

## 3. 设计原则

- 逻辑统一：惩罚词库、抽取概率、盲盒生成走共享服务。
- UI 统一：准备页预设组件与结果页盲盒组件为共享组件。
- 接入轻量：每个游戏页面只负责保存预设，并在结果阶段传入输家名单。
- 平滑兼容：保留旧 `PenaltyService` API，新增盲盒相关能力，避免一次性重写所有惩罚逻辑。

---

## 4. 领域模型

### 4.1 惩罚预设

- `PenaltyScene`
  - `home`
  - `bar`
- `PenaltyIntensity`
  - `mild`
  - `wild`
  - `xtreme`
- `PenaltyPreset`
  - `scene`
  - `intensity`

默认值：

- `scene = home`
- `intensity = mild`

### 4.2 惩罚词条

- `PenaltyCategory`
  - `physical`
  - `social`
  - `truth`
- `PenaltyLevel`
  - `level1`
  - `level2`
  - `level3`
- `PenaltyEntry`
  - `id`
  - `scene`
  - `level`
  - `category`
  - `textKey`
  - `tags`
  - 预留：`isCustom`, `isMercy`

### 4.3 盲盒结果

- `PenaltyBlindBoxCard`
  - `entry`
  - `level`
  - `revealed`
  - `dimmed`
- `PenaltyBlindBoxResult`
  - `loserNames`
  - `cards`
  - `selectedIndex`

---

## 5. 词库组织

内置两套主词库：

- `bar`：酒吧 / KTV / 夜场
- `home`：家庭聚会 / 宿舍 / 团建

每套词库按 `Level 1 / 2 / 3` 分类，并尽量给每个 level 分配到 `physical / social / truth` 三类，以保证盲盒三张卡的内容风格有差异。

如果同一 level 下某类不足，则允许回退到相邻 level 补位，但不能重复同一词条。

同时保留通用 fallback 词包，用于极端情况下的离线与词库不足兜底。

---

## 6. 抽取算法

### 6.1 强度到 level 的映射

- `mild`：100% `level1`
- `wild`：70% `level2`，30% `level1`
- `xtreme`：60% `level3`，30% `level2`，10% `level1`

### 6.2 三张卡生成规则

输入：

- `PenaltyPreset`
- `loserNames`
- `Random`

流程：

1. 根据强度采样目标 `PenaltyLevel`。
2. 从对应 `scene + level` 池中优先抽取 3 个不同 `category` 的词条。
3. 若类别不足，则放宽为同 `scene` 的相邻 `level`。
4. 若仍不足，则用通用词包补齐。
5. 结果按展示顺序输出 3 张背面一致的盲盒卡。

约束：

- 三张内容不能重复。
- 优先不同 category。
- 所有游戏共享同一套抽取逻辑。

---

## 7. 准备页 UI

新增共享组件：`PenaltyPresetCard`

放置位置：

- 每个游戏“开始”按钮上方。

内容：

- 标题：`惩罚预设 Penalty Preset`
- 场景选择：
  - `居家模式`
  - `酒吧模式`
- 强度选择：
  - `热身`
  - `进阶`
  - `极限`

交互：

- 点击选项触发 `HapticService.selectionClick()`
- 不影响原有 setup 配置项
- 各游戏页面本地持有预设状态，本次不做持久化

---

## 8. 结果页 UI

新增共享组件：`PenaltyBlindBoxOverlay`

### 8.1 状态机

- `awaitingReveal`
- `revealing`
- `revealed`
- `settled`

### 8.2 展示规则

- 屏幕中央显示 3 张黑金卡片
- 背面为磨砂黑 + 金属边框 + 中央圆环标识
- 待翻时有轻微呼吸动画
- 点击一张卡片后执行 3D 翻转
- 选中卡根据等级发光：
  - `level1` 青色
  - `level2` 橙色
  - `level3` 红色
- 未选中的两张自动变暗，并半透明显示内容

### 8.3 文案

- 顶部显示输家，例如：`玩家 2 接受命运抉择`
- 翻开后显示惩罚正文
- 底部沿用各游戏已有的“再来一局 / 下一轮 / 返回”动作栏

---

## 9. 各游戏接入方式

### 单输家游戏

- `bomb_pass`
- `number_bomb`
- `decibel_bomb`
- `bio_detector`

这些页面在结算时传入一个输家名字并显示盲盒。

### 多输家游戏

- `gesture_duel`
- `left_right`
- `truth_or_raise`

这些页面在结算时传入多个输家名字，共享一次盲盒揭晓。

### 无输家场景

若某局没有明确输家，则保留现有指导文案，不弹出盲盒。

---

## 10. 兼容策略

继续保留旧接口：

- `randomPlan`
- `pointsPlan`
- `actionPlan`
- `guidancePlan`

新增盲盒相关模型和 API，让已改造页面优先使用新能力，未改造页面仍可继续运行。

---

## 11. 测试策略

### 单元测试

- 强度到 level 的采样符合规则
- 三张盲盒卡不重复
- 优先不同 category
- 词库不足时 fallback 正常

### Widget 测试

- 准备页出现惩罚预设组件
- 结果页显示 3 张盲盒卡
- 点击后只翻开 1 张，其余两张变暗显示
- 无输家时不显示盲盒

---

## 12. 后续扩展预留

本次不做，但模型和组件保持可扩展：

- `免死金牌`
- `手动遮蔽敏感类型`
- `自定义词包`
- `语音播报`
- `拍照存证`
