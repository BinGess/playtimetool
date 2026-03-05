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

    test('oppositeDirection maps all directions correctly', () {
      expect(oppositeDirection(SwipeDirection.left), SwipeDirection.right);
      expect(oppositeDirection(SwipeDirection.right), SwipeDirection.left);
      expect(oppositeDirection(SwipeDirection.up), SwipeDirection.down);
      expect(oppositeDirection(SwipeDirection.down), SwipeDirection.up);
    });

    test('directionFromVelocity resolves horizontal swipe', () {
      final result = directionFromVelocity(dx: -250, dy: 30);
      expect(result, SwipeDirection.left);
    });

    test('directionFromVelocity resolves vertical swipe', () {
      final result = directionFromVelocity(dx: 40, dy: 300);
      expect(result, SwipeDirection.down);
    });

    test('directionFromVelocity returns null for tiny movement', () {
      final result = directionFromVelocity(dx: 60, dy: 80);
      expect(result, isNull);
    });
  });
}
