enum BombPhase { setup, playing, explosion }

class BombState {
  const BombState({
    this.phase = BombPhase.setup,
    this.secretNumber = 0,
    this.minRange = 1,
    this.maxRange = 100,
    this.originalMin = 1,
    this.originalMax = 100,
    this.currentInput = '',
    this.lastGuessInvalid = false,
    this.punishmentText = '',
  });

  final BombPhase phase;
  final int secretNumber;
  final int minRange;
  final int maxRange;
  final int originalMin;
  final int originalMax;
  final String currentInput;
  final bool lastGuessInvalid;
  final String punishmentText;

  /// 0.0 = calm, 1.0 = critical
  double get pressureRatio {
    final original = originalMax - originalMin;
    if (original <= 0) return 1.0;
    final remaining = maxRange - minRange;
    return 1.0 - (remaining / original).clamp(0.0, 1.0);
  }

  bool get isCritical => (maxRange - minRange) <= 3;

  BombState copyWith({
    BombPhase? phase,
    int? secretNumber,
    int? minRange,
    int? maxRange,
    int? originalMin,
    int? originalMax,
    String? currentInput,
    bool? lastGuessInvalid,
    String? punishmentText,
  }) {
    return BombState(
      phase: phase ?? this.phase,
      secretNumber: secretNumber ?? this.secretNumber,
      minRange: minRange ?? this.minRange,
      maxRange: maxRange ?? this.maxRange,
      originalMin: originalMin ?? this.originalMin,
      originalMax: originalMax ?? this.originalMax,
      currentInput: currentInput ?? this.currentInput,
      lastGuessInvalid: lastGuessInvalid ?? this.lastGuessInvalid,
      punishmentText: punishmentText ?? this.punishmentText,
    );
  }
}
