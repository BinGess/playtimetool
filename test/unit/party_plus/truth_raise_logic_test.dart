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
  });
}
