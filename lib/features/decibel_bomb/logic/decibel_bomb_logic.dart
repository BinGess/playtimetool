import 'dart:math';

enum ExplosionReason {
  energyOverflow,
  handoffSpike,
}

class DecibelBombState {
  const DecibelBombState({
    required this.maxEnergy,
    required this.baselineDb,
    this.energy = 0,
    this.sensitivity = 1.0,
    this.handoffWindowRemaining = 0,
    this.exploded = false,
    this.explosionReason,
  });

  final double maxEnergy;
  final double baselineDb;
  final double energy;
  final double sensitivity;
  final double handoffWindowRemaining;
  final bool exploded;
  final ExplosionReason? explosionReason;

  DecibelBombState copyWith({
    double? maxEnergy,
    double? baselineDb,
    double? energy,
    double? sensitivity,
    double? handoffWindowRemaining,
    bool? exploded,
    ExplosionReason? explosionReason,
    bool clearExplosionReason = false,
  }) {
    return DecibelBombState(
      maxEnergy: maxEnergy ?? this.maxEnergy,
      baselineDb: baselineDb ?? this.baselineDb,
      energy: energy ?? this.energy,
      sensitivity: sensitivity ?? this.sensitivity,
      handoffWindowRemaining:
          handoffWindowRemaining ?? this.handoffWindowRemaining,
      exploded: exploded ?? this.exploded,
      explosionReason: clearExplosionReason
          ? null
          : (explosionReason ?? this.explosionReason),
    );
  }
}

abstract final class DecibelBombRules {
  static int randomCapacity(Random random, {int min = 1000, int max = 3000}) {
    if (min > max) {
      throw ArgumentError('min must be <= max');
    }
    return min + random.nextInt(max - min + 1);
  }

  static DecibelBombState startHandoffSensitiveWindow(DecibelBombState state) {
    if (state.exploded) return state;
    return state.copyWith(
      sensitivity: state.sensitivity + 0.2,
      handoffWindowRemaining: 0.5,
    );
  }

  static DecibelBombState applySample(
    DecibelBombState state, {
    required double currentDb,
    required double deltaSeconds,
    required bool speaking,
  }) {
    if (state.exploded) return state;
    if (deltaSeconds <= 0) return state;

    final deltaDb = currentDb - state.baselineDb;

    if (state.handoffWindowRemaining > 0 && deltaDb > 20) {
      return state.copyWith(
        exploded: true,
        explosionReason: ExplosionReason.handoffSpike,
      );
    }

    var nextEnergy = state.energy;
    if (speaking && deltaDb > 0) {
      final increasePerSecond = deltaDb * state.sensitivity;
      nextEnergy += increasePerSecond * deltaSeconds;
    }

    if (nextEnergy >= state.maxEnergy) {
      return state.copyWith(
        energy: state.maxEnergy,
        exploded: true,
        explosionReason: ExplosionReason.energyOverflow,
        handoffWindowRemaining:
            max(0, state.handoffWindowRemaining - deltaSeconds),
      );
    }

    return state.copyWith(
      energy: nextEnergy,
      handoffWindowRemaining:
          max(0, state.handoffWindowRemaining - deltaSeconds),
    );
  }
}
