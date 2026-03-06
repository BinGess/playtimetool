import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bomb_state.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/constants/app_sounds.dart';

class NumberBombNotifier extends StateNotifier<BombState> {
  NumberBombNotifier({Random? random})
      : _random = random ?? Random(),
        super(const BombState());

  final Random _random;

  void startGame({int min = 1, int max = 100, int playerCount = 2}) {
    final secret = min + _random.nextInt(max - min + 1);
    state = BombState(
      phase: BombPhase.playing,
      secretNumber: secret,
      playerCount: playerCount,
      currentPlayerIndex: 0,
      loserPlayerIndex: null,
      minRange: min,
      maxRange: max,
      originalMin: min,
      originalMax: max,
    );
  }

  void addDigit(String digit) {
    if (state.phase != BombPhase.playing) return;
    if (state.currentInput.length >= 4) return; // max 4 digits
    state = state.copyWith(
      currentInput: state.currentInput + digit,
      lastGuessInvalid: false,
    );
    HapticService.lightImpact();
  }

  void backspace() {
    if (state.currentInput.isEmpty) return;
    state = state.copyWith(
      currentInput:
          state.currentInput.substring(0, state.currentInput.length - 1),
      lastGuessInvalid: false,
    );
    HapticService.lightImpact();
  }

  void confirmGuess() {
    if (state.phase != BombPhase.playing) return;
    final input = int.tryParse(state.currentInput);
    if (input == null) return;

    // Validate range
    if (input < state.minRange || input > state.maxRange) {
      state = state.copyWith(
        currentInput: '',
        lastGuessInvalid: true,
      );
      HapticService.errorVibrate();
      return;
    }

    // Check if hit secret
    if (input == state.secretNumber) {
      state = state.copyWith(
        phase: BombPhase.explosion,
        loserPlayerIndex: state.currentPlayerIndex,
        currentInput: '',
        punishmentText: '',
      );
      HapticService.tripleHeavyImpact();
      AudioService.play(AppSounds.bombExplosion);
      return;
    }

    // Narrow range
    int newMin = state.minRange;
    int newMax = state.maxRange;

    if (input < state.secretNumber) {
      newMin = input + 1;
    } else {
      newMax = input - 1;
    }

    state = state.copyWith(
      currentInput: '',
      currentPlayerIndex: (state.currentPlayerIndex + 1) % state.playerCount,
      minRange: newMin,
      maxRange: newMax,
      lastGuessInvalid: false,
    );

    HapticService.mediumImpact();
    AudioService.play(AppSounds.bombBeep);

    // Critical warning
    if (state.isCritical) {
      HapticService.pulseCritical();
    }
  }

  void reset() {
    state = const BombState();
  }

  void setPunishmentText(String text) {
    if (state.phase != BombPhase.explosion) return;
    state = state.copyWith(punishmentText: text);
  }
}

final numberBombProvider =
    StateNotifierProvider.autoDispose<NumberBombNotifier, BombState>(
  (ref) => NumberBombNotifier(),
);
