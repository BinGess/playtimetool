enum BioDetectorResult { truth, lie }

enum BioDetectorCheatOverride { none, forceTruth, forceLie }

enum BioDetectorFlowPhase { initializing, sampling, pressure, result }

const Duration kBioDetectorInitializingDuration = Duration(milliseconds: 800);
const Duration kBioDetectorSamplingDuration = Duration(seconds: 5);
const Duration kBioDetectorPressureDuration = Duration(seconds: 5);
const double kBioDetectorTruthProbability = 0.5;
const int kBioDetectorMinConfidencePercent = 55;
const int kBioDetectorMaxConfidencePercent = 99;

BioDetectorResult resolveBioDetectorResult({
  required BioDetectorCheatOverride cheatOverride,
  required double randomUnit,
}) {
  switch (cheatOverride) {
    case BioDetectorCheatOverride.forceTruth:
      return BioDetectorResult.truth;
    case BioDetectorCheatOverride.forceLie:
      return BioDetectorResult.lie;
    case BioDetectorCheatOverride.none:
      return randomUnit < kBioDetectorTruthProbability
          ? BioDetectorResult.truth
          : BioDetectorResult.lie;
  }
}

int confidencePercentFromUnit(double unit) {
  final clamped = unit.clamp(0.0, 0.999999999).toDouble();
  const span =
      (kBioDetectorMaxConfidencePercent - kBioDetectorMinConfidencePercent) + 1;
  return kBioDetectorMinConfidencePercent + (clamped * span).floor();
}

BioDetectorFlowPhase flowPhaseForElapsed(Duration elapsed) {
  if (elapsed < kBioDetectorInitializingDuration) {
    return BioDetectorFlowPhase.initializing;
  }

  final detectionElapsed = elapsed - kBioDetectorInitializingDuration;
  if (detectionElapsed < kBioDetectorSamplingDuration) {
    return BioDetectorFlowPhase.sampling;
  }
  if (detectionElapsed <
      kBioDetectorSamplingDuration + kBioDetectorPressureDuration) {
    return BioDetectorFlowPhase.pressure;
  }
  return BioDetectorFlowPhase.result;
}
