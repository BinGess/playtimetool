import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/decibel_bomb/logic/decibel_bomb_logic.dart';

void main() {
  group('DecibelBombRules', () {
    test('randomCapacity generates value inside [1000, 3000]', () {
      final random = Random(7);
      for (int i = 0; i < 100; i++) {
        final value = DecibelBombRules.randomCapacity(random);
        expect(value, inInclusiveRange(1000, 3000));
      }
    });

    test('energy accumulates only while speaking', () {
      const state = DecibelBombState(
        maxEnergy: 2000,
        baselineDb: 40,
      );

      final speaking = DecibelBombRules.applySample(
        state,
        currentDb: 60,
        deltaSeconds: 0.1,
        speaking: true,
      );
      expect(speaking.energy, closeTo(2.0, 1e-6));
      expect(speaking.exploded, false);

      final notSpeaking = DecibelBombRules.applySample(
        speaking,
        currentDb: 80,
        deltaSeconds: 0.1,
        speaking: false,
      );
      expect(notSpeaking.energy, closeTo(2.0, 1e-6));
    });

    test('sensitivity grows by 0.2 each handoff', () {
      var state = const DecibelBombState(maxEnergy: 2000, baselineDb: 40);
      state = DecibelBombRules.startHandoffSensitiveWindow(state);
      expect(state.sensitivity, closeTo(1.2, 1e-6));
      state = DecibelBombRules.startHandoffSensitiveWindow(state);
      expect(state.sensitivity, closeTo(1.4, 1e-6));
      expect(state.handoffWindowRemaining, closeTo(0.5, 1e-6));
    });

    test('handoff spike explodes immediately when deltaDb > 20 in window', () {
      final started = DecibelBombRules.startHandoffSensitiveWindow(
        const DecibelBombState(maxEnergy: 2000, baselineDb: 40),
      );
      final exploded = DecibelBombRules.applySample(
        started,
        currentDb: 61,
        deltaSeconds: 0.1,
        speaking: false,
      );
      expect(exploded.exploded, true);
      expect(exploded.explosionReason, ExplosionReason.handoffSpike);
    });

    test('energy overflow explodes when bucket reaches maxEnergy', () {
      const state = DecibelBombState(maxEnergy: 3, baselineDb: 40);
      final exploded = DecibelBombRules.applySample(
        state,
        currentDb: 80,
        deltaSeconds: 0.1,
        speaking: true,
      );
      expect(exploded.exploded, true);
      expect(exploded.explosionReason, ExplosionReason.energyOverflow);
      expect(exploded.energy, 3);
    });
  });
}
