import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/number_bomb/models/bomb_state.dart';
import 'package:playtimetool/features/number_bomb/providers/number_bomb_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('NumberBombNotifier', () {
    late ProviderContainer container;
    late NumberBombNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(numberBombProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('initial state is setup phase', () {
      final state = container.read(numberBombProvider);
      expect(state.phase, BombPhase.setup);
    });

    test('startGame creates playing state with correct range', () {
      notifier.startGame(min: 1, max: 50, playerCount: 4);
      final state = container.read(numberBombProvider);

      expect(state.phase, BombPhase.playing);
      expect(state.playerCount, 4);
      expect(state.currentPlayerIndex, 0);
      expect(state.minRange, 1);
      expect(state.maxRange, 50);
      expect(state.originalMin, 1);
      expect(state.originalMax, 50);
      expect(state.secretNumber >= 1, true);
      expect(state.secretNumber <= 50, true);
    });

    test('addDigit appends digit to input', () {
      notifier.startGame();
      notifier.addDigit('4');
      notifier.addDigit('2');
      expect(container.read(numberBombProvider).currentInput, '42');
    });

    test('addDigit limited to 4 digits', () {
      notifier.startGame();
      for (final d in ['1', '2', '3', '4', '5']) {
        notifier.addDigit(d);
      }
      expect(container.read(numberBombProvider).currentInput.length, 4);
    });

    test('backspace removes last digit', () {
      notifier.startGame();
      notifier.addDigit('4');
      notifier.addDigit('2');
      notifier.backspace();
      expect(container.read(numberBombProvider).currentInput, '4');
    });

    test('guess narrowing: lower guess raises minRange', () {
      // We need to control the secret. Use a known range where
      // we know a guess is below the secret.
      // We will start game and manually test a guess that is
      // below the current range max to verify narrowing.
      // Since we can't set secret directly, we test range narrowing logic.

      // Create a container where we can inspect state after a valid guess
      // below secret. We'll start game and ensure logic narrows range.
      notifier.startGame(min: 10, max: 20);
      final state0 = container.read(numberBombProvider);
      final secret = state0.secretNumber;

      // Guess a number below secret (if possible)
      if (secret > 10) {
        notifier.addDigit('${secret - 1 < 10 ? secret - 1 : 10}');
        notifier.confirmGuess();
        final state1 = container.read(numberBombProvider);
        if (state1.phase == BombPhase.playing) {
          expect(state1.minRange > state0.minRange || state1.maxRange < state0.maxRange, true);
        }
      }
    });

    test('invalid guess (out of range) sets lastGuessInvalid', () {
      notifier.startGame(min: 1, max: 100);
      // Guess 150 which is out of range
      notifier.addDigit('1');
      notifier.addDigit('5');
      notifier.addDigit('0');
      notifier.confirmGuess();
      expect(container.read(numberBombProvider).lastGuessInvalid, true);
      expect(container.read(numberBombProvider).currentInput, '');
    });

    test('pressure ratio starts at 0 and increases', () {
      notifier.startGame(min: 1, max: 100);
      final state0 = container.read(numberBombProvider);
      expect(state0.pressureRatio, 0.0);

      // Manually simulate range narrowing (without hitting secret)
      // by checking the pressure ratio formula
      const narrowed = BombState(
        phase: BombPhase.playing,
        secretNumber: 50,
        minRange: 40,
        maxRange: 60,
        originalMin: 1,
        originalMax: 100,
      );
      // Range went from 99 to 20, so pressureRatio = 1 - 20/99 ≈ 0.8
      expect(narrowed.pressureRatio, greaterThan(0.0));
      expect(narrowed.pressureRatio, lessThan(1.0));
    });

    test('isCritical when range ≤ 3', () {
      const critical = BombState(
        phase: BombPhase.playing,
        secretNumber: 50,
        minRange: 49,
        maxRange: 51,
        originalMin: 1,
        originalMax: 100,
      );
      expect(critical.isCritical, true);

      const notCritical = BombState(
        phase: BombPhase.playing,
        secretNumber: 50,
        minRange: 1,
        maxRange: 100,
        originalMin: 1,
        originalMax: 100,
      );
      expect(notCritical.isCritical, false);
    });

    test('reset returns to setup phase', () {
      notifier.startGame();
      notifier.reset();
      expect(container.read(numberBombProvider).phase, BombPhase.setup);
    });

    test('valid guess rotates turn to next player', () {
      notifier = NumberBombNotifier(random: Random(0));
      container.dispose();
      container = ProviderContainer(
        overrides: [
          numberBombProvider.overrideWith((ref) => notifier),
        ],
      );

      notifier.startGame(min: 1, max: 10, playerCount: 3);
      final initial = container.read(numberBombProvider);
      final secret = initial.secretNumber;
      final guess = secret == 10 ? 9 : 10;

      for (final digit in '$guess'.split('')) {
        notifier.addDigit(digit);
      }
      notifier.confirmGuess();

      final state = container.read(numberBombProvider);
      expect(state.phase, BombPhase.playing);
      expect(state.currentPlayerIndex, 1);
      expect(state.loserPlayerIndex, isNull);
    });

    test('secret hit records loser and ends round immediately', () {
      notifier = NumberBombNotifier(random: Random(0));
      container.dispose();
      container = ProviderContainer(
        overrides: [
          numberBombProvider.overrideWith((ref) => notifier),
        ],
      );

      notifier.startGame(min: 1, max: 10, playerCount: 4);
      final secret = container.read(numberBombProvider).secretNumber;

      for (final digit in '$secret'.split('')) {
        notifier.addDigit(digit);
      }
      notifier.confirmGuess();

      final state = container.read(numberBombProvider);
      expect(state.phase, BombPhase.explosion);
      expect(state.loserPlayerIndex, 0);
      expect(state.playerCount, 4);
    });
  });
}
