import 'package:flutter/material.dart';

// waiting     → 等待手指放上（<2 根 或手指刚放下）
// locked      → ≥2根静止1.5s后锁定，显示"开始"按钮，再1.5s自动触发
// countdown   → 3-2-1 倒计时阶段，圆环高速旋转
// eliminating → 逐步排除落败者动画
// result      → 展示最终结果（胜利者烟花 + 落败者 X）
enum PickerPhase { waiting, locked, countdown, eliminating, result }

class FingerData {
  const FingerData({
    required this.pointerId,
    required this.position,
    required this.neonColor,
    this.isWinner = false,
    this.isEliminated = false,
  });

  final int pointerId;
  final Offset position;
  final Color neonColor;
  final bool isWinner;
  final bool isEliminated;

  FingerData copyWith({
    Offset? position,
    bool? isWinner,
    bool? isEliminated,
  }) {
    return FingerData(
      pointerId: pointerId,
      position: position ?? this.position,
      neonColor: neonColor,
      isWinner: isWinner ?? this.isWinner,
      isEliminated: isEliminated ?? this.isEliminated,
    );
  }
}

class FingerPickerState {
  const FingerPickerState({
    this.fingers = const {},
    this.phase = PickerPhase.waiting,
    this.countdownValue = 3,
    this.maxWinners = 1,
    this.showEscapeAlert = false,
    this.eliminationOrder = const [],
    this.visibleEliminationCount = 0,
  });

  final Map<int, FingerData> fingers;
  final PickerPhase phase;
  final int countdownValue;
  final int maxWinners;
  final bool showEscapeAlert;

  /// 落败者指针 ID 的有序列表（逐步揭晓用）
  final List<int> eliminationOrder;

  /// 已展示消除效果的落败者数量
  final int visibleEliminationCount;

  FingerPickerState copyWith({
    Map<int, FingerData>? fingers,
    PickerPhase? phase,
    int? countdownValue,
    int? maxWinners,
    bool? showEscapeAlert,
    List<int>? eliminationOrder,
    int? visibleEliminationCount,
  }) {
    return FingerPickerState(
      fingers: fingers ?? this.fingers,
      phase: phase ?? this.phase,
      countdownValue: countdownValue ?? this.countdownValue,
      maxWinners: maxWinners ?? this.maxWinners,
      showEscapeAlert: showEscapeAlert ?? this.showEscapeAlert,
      eliminationOrder: eliminationOrder ?? this.eliminationOrder,
      visibleEliminationCount:
          visibleEliminationCount ?? this.visibleEliminationCount,
    );
  }

  /// 该指针是否已在屏幕上显示「消除」效果
  bool isVisiblyEliminated(int pointerId) {
    final idx = eliminationOrder.indexOf(pointerId);
    return idx >= 0 && idx < visibleEliminationCount;
  }

  List<FingerData> get winners =>
      fingers.values.where((f) => f.isWinner).toList();
}
