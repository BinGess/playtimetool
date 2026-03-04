int nextRaiseLevelOnSkip(int currentRaise) {
  final next = currentRaise + 1;
  return next > 5 ? 5 : next;
}

class TruthRaiseActionResult {
  const TruthRaiseActionResult({
    required this.nextRaise,
    required this.penaltyDelta,
  });

  final int nextRaise;
  final int penaltyDelta;
}

TruthRaiseActionResult applyAnswerAction() {
  return const TruthRaiseActionResult(nextRaise: 0, penaltyDelta: 0);
}

TruthRaiseActionResult applySkipAction(int currentRaise) {
  final nextRaise = nextRaiseLevelOnSkip(currentRaise);
  return TruthRaiseActionResult(nextRaise: nextRaise, penaltyDelta: nextRaise);
}
