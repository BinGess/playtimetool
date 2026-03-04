import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/party_plus/logic/left_right_logic.dart';

void main() {
  group('left_right_logic', () {
    test('correct swipe has no penalty', () {
      final result = resolveReaction(
        target: SwipeDirection.left,
        actual: SwipeDirection.left,
      );

      expect(result.success, true);
      expect(result.penaltyDelta, 0);
    });

    test('wrong swipe adds one penalty', () {
      final result = resolveReaction(
        target: SwipeDirection.right,
        actual: SwipeDirection.left,
      );

      expect(result.success, false);
      expect(result.penaltyDelta, 1);
    });

    test('timeout adds one penalty', () {
      final result = timeoutReaction();

      expect(result.success, false);
      expect(result.penaltyDelta, 1);
    });
  });
}
