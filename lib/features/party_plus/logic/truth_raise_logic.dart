enum TruthRaiseScaleLevel { gentle, standard, spicy, extreme }

class TruthRaiseScaleConfig {
  const TruthRaiseScaleConfig({
    required this.step,
    required this.maxRaise,
  });

  final int step;
  final int maxRaise;
}

const Map<TruthRaiseScaleLevel, TruthRaiseScaleConfig> truthRaiseScaleConfigs =
    {
  TruthRaiseScaleLevel.gentle: TruthRaiseScaleConfig(step: 1, maxRaise: 3),
  TruthRaiseScaleLevel.standard: TruthRaiseScaleConfig(step: 1, maxRaise: 5),
  TruthRaiseScaleLevel.spicy: TruthRaiseScaleConfig(step: 2, maxRaise: 8),
  TruthRaiseScaleLevel.extreme: TruthRaiseScaleConfig(step: 3, maxRaise: 12),
};

TruthRaiseScaleConfig configForScale(TruthRaiseScaleLevel scale) {
  return truthRaiseScaleConfigs[scale]!;
}

int nextRaiseLevelOnSkip(
  int currentRaise, {
  int maxRaise = 5,
  int step = 1,
}) {
  final safeStep = step < 1 ? 1 : step;
  final safeCap = maxRaise < 0 ? 0 : maxRaise;
  final next = currentRaise + safeStep;
  return next > safeCap ? safeCap : next;
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

TruthRaiseActionResult applySkipAction(
  int currentRaise, {
  int maxRaise = 5,
  int step = 1,
}) {
  final nextRaise = nextRaiseLevelOnSkip(
    currentRaise,
    maxRaise: maxRaise,
    step: step,
  );
  return TruthRaiseActionResult(nextRaise: nextRaise, penaltyDelta: nextRaise);
}
