import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sounds.dart';
import '../../../core/haptics/haptic_service.dart';
import '../models/finger_state.dart';

class FingerPickerNotifier extends StateNotifier<FingerPickerState> {
  FingerPickerNotifier() : super(const FingerPickerState());

  Timer? _stillnessTimer;
  Timer? _autoStartTimer;
  Timer? _countdownTimer;
  Timer? _eliminationTimer;
  final _random = Random();

  void startGame() {
    _cancelAllTimers();
    state = FingerPickerState(
      phase: PickerPhase.waiting,
      maxWinners: state.maxWinners,
    );
  }

  void backToSetup() {
    _cancelAllTimers();
    state = FingerPickerState(
      phase: PickerPhase.setup,
      maxWinners: state.maxWinners,
    );
  }

  void addFinger(int pointerId, Offset position) {
    if (state.phase == PickerPhase.setup ||
        state.phase == PickerPhase.result ||
        state.phase == PickerPhase.countdown ||
        state.phase == PickerPhase.eliminating) {
      return;
    }

    if (state.fingers.containsKey(pointerId)) {
      updateFinger(pointerId, position);
      return;
    }

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

    state = state.copyWith(
      fingers: updated,
      phase: PickerPhase.waiting,
      showEscapeAlert: false,
      showOverflowAlert: false,
    );

    HapticService.selectionClick();
    AudioService.play(AppSounds.fingerTouch);
    _resetStillnessTimer();
  }

  void updateFinger(int pointerId, Offset position) {
    if (!state.fingers.containsKey(pointerId)) return;
    if (state.phase == PickerPhase.setup ||
        state.phase == PickerPhase.result ||
        state.phase == PickerPhase.countdown ||
        state.phase == PickerPhase.eliminating) {
      return;
    }

    final updated = Map<int, FingerData>.from(state.fingers)
      ..[pointerId] = state.fingers[pointerId]!.copyWith(position: position);
    state = state.copyWith(fingers: updated);
  }

  void removeFinger(int pointerId) {
    if (state.phase == PickerPhase.result || state.phase == PickerPhase.setup) {
      return;
    }

    if (state.phase == PickerPhase.countdown ||
        state.phase == PickerPhase.eliminating) {
      _abortAndShowEscape();
      return;
    }

    if (!state.fingers.containsKey(pointerId)) return;

    final updated = Map<int, FingerData>.from(state.fingers)..remove(pointerId);
    _cancelAllTimers();

    state = state.copyWith(fingers: updated, phase: PickerPhase.waiting);
    if (updated.length >= 2) {
      _resetStillnessTimer();
    }
  }

  /// 静止 1.5s → locked；locked 再保持 1.5s → 自动启动倒计时
  /// 注：移动手指不会重置倒计时，只有抬手才会重置。
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
      if (state.fingers.length >= 2 && state.phase == PickerPhase.waiting) {
        state = state.copyWith(phase: PickerPhase.locked);
        HapticService.mediumImpact();
        _autoStartTimer = Timer(const Duration(milliseconds: 1500), () {
          if (state.phase == PickerPhase.locked && state.fingers.length >= 2) {
            _startCountdown();
          }
        });
      }
    });
  }

  void startManually() {
    if (state.phase != PickerPhase.locked || state.fingers.length < 2) return;
    _autoStartTimer?.cancel();
    _startCountdown();
  }

  void _startCountdown() {
    if (state.fingers.length < 2) return;
    _stillnessTimer?.cancel();
    _autoStartTimer?.cancel();

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
        if (remaining == 2) HapticService.lightImpact();
        if (remaining == 1) HapticService.heavyImpact();
        AudioService.play(AppSounds.fingerCountdown);
      }
    });
  }

  void _selectWinnersSequentially() {
    final ids = state.fingers.keys.toList()..shuffle(_random);
    final winnerCount = min(state.maxWinners, state.fingers.length);
    final winnerIds = ids.take(winnerCount).toSet();
    final loserIds = ids.skip(winnerCount).toList();

    final updated = state.fingers.map(
      (id, f) => MapEntry(
        id,
        f.copyWith(
          isWinner: winnerIds.contains(id),
          isEliminated: !winnerIds.contains(id),
        ),
      ),
    );

    state = state.copyWith(
      fingers: updated,
      phase: PickerPhase.eliminating,
      eliminationOrder: loserIds,
      visibleEliminationCount: 0,
    );

    if (loserIds.isEmpty) {
      _revealWinners();
      return;
    }

    int revealed = 0;
    _eliminationTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      revealed++;
      HapticService.lightImpact();
      AudioService.play(AppSounds.wheelTick, volume: 0.5);
      state = state.copyWith(visibleEliminationCount: revealed);

      if (revealed >= loserIds.length) {
        t.cancel();
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
      phase: PickerPhase.waiting,
      showEscapeAlert: true,
      maxWinners: state.maxWinners,
    );
    HapticService.errorVibrate();
  }

  void _overflowAndReset() {
    _cancelAllTimers();
    state = FingerPickerState(
      phase: PickerPhase.waiting,
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
    state = FingerPickerState(
      phase: PickerPhase.waiting,
      maxWinners: state.maxWinners,
    );
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

final fingerPickerProvider =
    StateNotifierProvider.autoDispose<FingerPickerNotifier, FingerPickerState>(
  (ref) => FingerPickerNotifier(),
);
