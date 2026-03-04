import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/party_plus/logic/gesture_duel_logic.dart';

void main() {
  group('resolveGestureDuel', () {
    test('returns draw when all gestures are same', () {
      final resolution = resolveGestureDuel(
        picks: [
          DuelGesture.rock,
          DuelGesture.rock,
          DuelGesture.rock,
        ],
        minorityLoses: true,
      );

      expect(resolution.isDraw, true);
      expect(resolution.losers, isEmpty);
    });

    test('minority mode marks minority gesture players as losers', () {
      final resolution = resolveGestureDuel(
        picks: [
          DuelGesture.rock,
          DuelGesture.rock,
          DuelGesture.paper,
          DuelGesture.rock,
        ],
        minorityLoses: true,
      );

      expect(resolution.isDraw, false);
      expect(resolution.losers, [2]);
    });

    test('majority mode marks majority gesture players as losers', () {
      final resolution = resolveGestureDuel(
        picks: [
          DuelGesture.scissors,
          DuelGesture.paper,
          DuelGesture.scissors,
          DuelGesture.scissors,
        ],
        minorityLoses: false,
      );

      expect(resolution.isDraw, false);
      expect(resolution.losers, [0, 2, 3]);
    });

    test('returns draw when all players get selected as losers', () {
      final resolution = resolveGestureDuel(
        picks: [
          DuelGesture.rock,
          DuelGesture.paper,
          DuelGesture.scissors,
        ],
        minorityLoses: true,
      );

      expect(resolution.isDraw, true);
      expect(resolution.losers.length, 3);
    });
  });
}
