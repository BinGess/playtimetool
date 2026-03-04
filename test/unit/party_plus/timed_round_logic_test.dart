import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/party_plus/logic/timed_round_logic.dart';

void main() {
  group('timed_round_logic', () {
    test('creates holder and duration inside expected range', () {
      final round = createTimedHolderRound(
        playerCount: 4,
        minDuration: 6,
        maxDuration: 14,
        random: Random(1),
      );

      expect(round.holderIndex >= 0 && round.holderIndex < 4, true);
      expect(round.durationSeconds >= 6 && round.durationSeconds <= 14, true);
    });

    test('pickRandomWord returns value from source list', () {
      final words = ['a', 'b', 'c'];
      final picked = pickRandomWord(words, Random(2));
      expect(words.contains(picked), true);
    });

    test('throws for invalid input', () {
      expect(
        () => createTimedHolderRound(
          playerCount: 0,
          minDuration: 1,
          maxDuration: 2,
          random: Random(1),
        ),
        throwsArgumentError,
      );
      expect(() => pickRandomWord(const [], Random(1)), throwsArgumentError);
    });
  });
}
