import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/constants/app_sounds.dart';
import '../models/finger_state.dart';

class FingerPickerNotifier extends StateNotifier<FingerPickerState> {
  FingerPickerNotifier() : super(const FingerPickerState());

  Timer? _stillnessTimer;
  Timer? _autoStartTimer; // 锁定后 1.5s 自动触发倒计时
  Timer? _countdownTimer;
  Timer? _eliminationTimer;
  final _random = Random();

  // ── 位移阈值防抖 ──────────────────────────────────────────────────
  // iOS 静止时也会持续以 60Hz 发出微小 PointerMove（< 2px）
  // 必须过滤掉这些抖动，否则 stillnessTimer 永远无法计满 1.5s
  final Map<int, Offset> _stablePos = {};
  static const double _moveThreshold = 8.0;

  // ═══════════════════════════════════════════════════════════════════
  //  触控事件
  // ═══════════════════════════════════════════════════════════════════

  void addFinger(int pointerId, Offset position) {
    // 只有在 result 阶段点击才重置，否则如果是 waiting/locked 阶段，就走下面的逻辑
    if (state.phase == PickerPhase.result) {
       reset();
       // reset 会清空 fingers 和状态，重置为 waiting
       // 继续往下走，把当前这个点击作为第一个手指添加进去
    }
    
    if (state.phase == PickerPhase.countdown ||
        state.phase == PickerPhase.eliminating) { return; }

    // 防止同一个 pointerId 重复添加
    if (state.fingers.containsKey(pointerId)) {
        updateFinger(pointerId, position);
        return;
    }

    // 超过人数限制：重置并提示
    if (state.fingers.length >= kMaxFingerPlayers) {
      _overflowAndReset();
      return;
    }

    final colorIndex = state.fingers.length % AppColors.fingerNeons.length;
    final finger = FingerData(
      pointerId: pointerId,
      position: position,
      neonColor: AppColors.fingerNeons[colorIndex],
    );

    final updated = Map<int, FingerData>.from(state.fingers)
      ..[pointerId] = finger;
    _stablePos[pointerId] = position;

    state = state.copyWith(
      fingers: updated,
      phase: PickerPhase.waiting,
      showEscapeAlert: false,
    );

    HapticService.selectionClick();
    AudioService.play(AppSounds.fingerTouch);
    _resetStillnessTimer();
  }

  void updateFinger(int pointerId, Offset position) {
    if (!state.fingers.containsKey(pointerId)) return;
    if (state.phase == PickerPhase.result ||
        state.phase == PickerPhase.countdown ||
        state.phase == PickerPhase.eliminating) { return; }

    // 更新屏幕上的指尖位置
    final updated = Map<int, FingerData>.from(state.fingers)
      ..[pointerId] =
          state.fingers[pointerId]!.copyWith(position: position);
    state = state.copyWith(fingers: updated);

    // 只在 waiting/locked 阶段判断是否真实移动
    final stable = _stablePos[pointerId];
    if (stable == null ||
        (position - stable).distance >= _moveThreshold) {
      _stablePos[pointerId] = position;
      // 真实移动 → 取消锁定 & 重置静止计时器
      if (state.phase == PickerPhase.locked) {
        state = state.copyWith(phase: PickerPhase.waiting);
      }
      _resetStillnessTimer();
    }
  }

  void removeFinger(int pointerId) {
    // 倒计时 / 消除阶段松手 → 逃跑
    if (state.phase == PickerPhase.countdown ||
        state.phase == PickerPhase.eliminating) {
      _abortAndShowEscape();
      return;
    }

    if (!state.fingers.containsKey(pointerId)) return;

    _stablePos.remove(pointerId);
    final updated = Map<int, FingerData>.from(state.fingers)
      ..remove(pointerId);
    _cancelAllTimers();

    state = state.copyWith(fingers: updated, phase: PickerPhase.waiting);
    if (updated.length >= 2) _resetStillnessTimer();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  游戏流程
  // ═══════════════════════════════════════════════════════════════════

  /// 静止 1.5s → locked；locked 再保持 1.5s → 自动启动倒计时
  void _resetStillnessTimer() {
    _stillnessTimer?.cancel();
    _autoStartTimer?.cancel();
    if (state.fingers.length < 2) {
      if (state.phase == PickerPhase.locked) {
        state = state.copyWith(phase: PickerPhase.waiting);
      }
      return;
    }

    _stillnessTimer = Timer(const Duration(milliseconds: 1500), () {
      if (state.fingers.length >= 2 &&
          state.phase == PickerPhase.waiting) {
        state = state.copyWith(phase: PickerPhase.locked);
        HapticService.mediumImpact();
        // 锁定后再 1.5s 自动触发
        _autoStartTimer = Timer(const Duration(milliseconds: 1500), () {
          if (state.phase == PickerPhase.locked) _startCountdown();
        });
      }
    });
  }

  /// 手动点击屏幕中央"开始"按钮
  void startManually() {
    if (state.phase != PickerPhase.locked) return;
    if (state.fingers.length < 2) return;
    _autoStartTimer?.cancel();
    _startCountdown();
  }

  void _startCountdown() {
    _stillnessTimer?.cancel();
    state = state.copyWith(phase: PickerPhase.countdown, countdownValue: 3);
    AudioService.play(AppSounds.fingerCountdown);
    HapticService.lightImpact();

    int remaining = 3;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining--;
      if (remaining <= 0) {
        t.cancel();
        _selectWinnersSequentially();
      } else {
        state = state.copyWith(countdownValue: remaining);
        // 递增震动强度
        if (remaining == 2) HapticService.lightImpact();
        if (remaining == 1) HapticService.heavyImpact();
        AudioService.play(AppSounds.fingerCountdown);
      }
    });
  }

  /// 确定胜者 → 逐步排除落败者 → 揭晓胜者
  void _selectWinnersSequentially() {
    final ids = state.fingers.keys.toList()..shuffle(_random);
    final winnerCount = min(state.maxWinners, state.fingers.length);
    final winnerIds = ids.take(winnerCount).toSet();
    final loserIds = ids.skip(winnerCount).toList();

    // 状态中立刻标好所有人的胜负，但画布只在 visibleEliminationCount 递增时才显示
    final updated = state.fingers.map((id, f) => MapEntry(
          id,
          f.copyWith(
            isWinner: winnerIds.contains(id),
            isEliminated: !winnerIds.contains(id),
          ),
        ));

    state = state.copyWith(
      fingers: updated,
      phase: PickerPhase.eliminating,
      eliminationOrder: loserIds,
      visibleEliminationCount: 0,
    );

    if (loserIds.isEmpty) {
      // 全员胜利（选中人数 ≥ 参与人数）
      _revealWinners();
      return;
    }

    int revealed = 0;
    _eliminationTimer =
        Timer.periodic(const Duration(milliseconds: 500), (t) {
      revealed++;
      HapticService.lightImpact(); // 轻微震动
      AudioService.play(AppSounds.wheelTick, volume: 0.5); // 轻微提示音
      state = state.copyWith(visibleEliminationCount: revealed);

      if (revealed >= loserIds.length) {
        t.cancel();
        // 全部淘汰完毕 → 延迟后揭晓胜利者
        Future.delayed(const Duration(milliseconds: 600), _revealWinners);
      }
    });
  }

  void _revealWinners() {
    state = state.copyWith(phase: PickerPhase.result);
    HapticService.tripleHeavyImpact();
    AudioService.play(AppSounds.fingerWinner);
  }

  void _abortAndShowEscape() {
    _cancelAllTimers();
    state = FingerPickerState(
      showEscapeAlert: true,
      maxWinners: state.maxWinners,
    );
    HapticService.errorVibrate();
  }

  void _overflowAndReset() {
    _cancelAllTimers();
    _stablePos.clear();
    state = FingerPickerState(
      showOverflowAlert: true,
      maxWinners: state.maxWinners,
    );
    HapticService.notificationWarning();
  }

  void dismissEscapeAlert() {
    state = state.copyWith(showEscapeAlert: false);
  }

  void dismissOverflowAlert() {
    state = state.copyWith(showOverflowAlert: false);
  }

  void reset() {
    _cancelAllTimers();
    _stablePos.clear();
    state = FingerPickerState(maxWinners: state.maxWinners);
  }

  void setMaxWinners(int count) {
    state = state.copyWith(maxWinners: count.clamp(1, kMaxFingerPlayers));
  }

  void _cancelAllTimers() {
    _stillnessTimer?.cancel();
    _autoStartTimer?.cancel();
    _countdownTimer?.cancel();
    _eliminationTimer?.cancel();
  }

  @override
  void dispose() {
    _cancelAllTimers();
    super.dispose();
  }
}

final fingerPickerProvider = StateNotifierProvider.autoDispose<
    FingerPickerNotifier, FingerPickerState>(
  (ref) => FingerPickerNotifier(),
);
