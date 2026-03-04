enum SwipeDirection { left, right }

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
