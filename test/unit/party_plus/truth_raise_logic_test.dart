import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/party_plus/logic/truth_raise_logic.dart';

void main() {
  group('truth_raise_logic', () {
    test('answer action resets raise with no penalty', () {
      final result = applyAnswerAction();

      expect(result.nextRaise, 0);
      expect(result.penaltyDelta, 0);
    });

    test('skip action increments raise and penalty', () {
      final result = applySkipAction(2);

      expect(result.nextRaise, 3);
      expect(result.penaltyDelta, 3);
    });

    test('raise level is capped at 5', () {
      final result = applySkipAction(5);

      expect(result.nextRaise, 5);
      expect(result.penaltyDelta, 5);
      expect(nextRaiseLevelOnSkip(10), 5);
    });

    test('skip action supports custom step and cap for scale levels', () {
      final result = applySkipAction(2, maxRaise: 8, step: 2);

      expect(result.nextRaise, 4);
      expect(result.penaltyDelta, 4);
    });

    test('custom cap is respected when current raise exceeds cap', () {
      final result = applySkipAction(9, maxRaise: 8, step: 2);

      expect(result.nextRaise, 8);
      expect(result.penaltyDelta, 8);
      expect(nextRaiseLevelOnSkip(9, maxRaise: 8, step: 2), 8);
    });

    test('built-in scale configs expose expected step and cap', () {
      expect(configForScale(TruthRaiseScaleLevel.gentle).step, 1);
      expect(configForScale(TruthRaiseScaleLevel.gentle).maxRaise, 3);
      expect(configForScale(TruthRaiseScaleLevel.standard).step, 1);
      expect(configForScale(TruthRaiseScaleLevel.standard).maxRaise, 5);
      expect(configForScale(TruthRaiseScaleLevel.spicy).step, 2);
      expect(configForScale(TruthRaiseScaleLevel.spicy).maxRaise, 8);
      expect(configForScale(TruthRaiseScaleLevel.extreme).step, 3);
      expect(configForScale(TruthRaiseScaleLevel.extreme).maxRaise, 12);
    });
  });
}
