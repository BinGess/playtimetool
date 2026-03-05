enum SwipeDirection { left, right, up, down }

class ReactionResolution {
  const ReactionResolution({
    required this.success,
    required this.penaltyDelta,
  });

  final bool success;
  final int penaltyDelta;
}

ReactionResolution resolveReaction({
  required SwipeDirection target,
  required SwipeDirection actual,
}) {
  if (target == actual) {
    return const ReactionResolution(success: true, penaltyDelta: 0);
  }
  return const ReactionResolution(success: false, penaltyDelta: 1);
}

ReactionResolution timeoutReaction() {
  return const ReactionResolution(success: false, penaltyDelta: 1);
}

SwipeDirection oppositeDirection(SwipeDirection direction) {
  switch (direction) {
    case SwipeDirection.left:
      return SwipeDirection.right;
    case SwipeDirection.right:
      return SwipeDirection.left;
    case SwipeDirection.up:
      return SwipeDirection.down;
    case SwipeDirection.down:
      return SwipeDirection.up;
  }
}

SwipeDirection? directionFromVelocity({
  required double dx,
  required double dy,
  double minVelocity = 120,
}) {
  if (dx.abs() < minVelocity && dy.abs() < minVelocity) return null;
  if (dx.abs() >= dy.abs()) {
    return dx >= 0 ? SwipeDirection.right : SwipeDirection.left;
  }
  return dy >= 0 ? SwipeDirection.down : SwipeDirection.up;
}
