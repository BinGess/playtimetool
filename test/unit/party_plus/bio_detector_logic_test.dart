import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/party_plus/logic/bio_detector_logic.dart';

void main() {
  group('bio_detector_logic', () {
    test('top-left override always resolves to truth', () {
      final result = resolveBioDetectorResult(
        cheatOverride: BioDetectorCheatOverride.forceTruth,
        randomUnit: 0.9,
      );

      expect(result, BioDetectorResult.truth);
    });

    test('bottom-right override always resolves to lie', () {
      final result = resolveBioDetectorResult(
        cheatOverride: BioDetectorCheatOverride.forceLie,
        randomUnit: 0.1,
      );

      expect(result, BioDetectorResult.lie);
    });

    test('no override uses probability threshold with random unit input', () {
      final truth = resolveBioDetectorResult(
        cheatOverride: BioDetectorCheatOverride.none,
        randomUnit: kBioDetectorTruthProbability - 0.001,
      );
      final lie = resolveBioDetectorResult(
        cheatOverride: BioDetectorCheatOverride.none,
        randomUnit: kBioDetectorTruthProbability + 0.001,
      );

      expect(truth, BioDetectorResult.truth);
      expect(lie, BioDetectorResult.lie);
    });

    test('confidence percent stays in configured range and changes by unit', () {
      final low = confidencePercentFromUnit(0.0);
      final mid = confidencePercentFromUnit(0.5);
      final high = confidencePercentFromUnit(0.999999);

      expect(low, greaterThanOrEqualTo(kBioDetectorMinConfidencePercent));
      expect(high, lessThanOrEqualTo(kBioDetectorMaxConfidencePercent));
      expect(low, isNot(equals(mid)));
      expect(mid, isNot(equals(high)));
    });

    test('flow phase boundaries match initialization + 0-5s + 5-10s', () {
      expect(
        flowPhaseForElapsed(const Duration(milliseconds: 0)),
        BioDetectorFlowPhase.initializing,
      );
      expect(
        flowPhaseForElapsed(const Duration(milliseconds: 799)),
        BioDetectorFlowPhase.initializing,
      );
      expect(
        flowPhaseForElapsed(const Duration(milliseconds: 800)),
        BioDetectorFlowPhase.sampling,
      );
      expect(
        flowPhaseForElapsed(const Duration(seconds: 5, milliseconds: 799)),
        BioDetectorFlowPhase.sampling,
      );
      expect(
        flowPhaseForElapsed(const Duration(seconds: 5, milliseconds: 800)),
        BioDetectorFlowPhase.pressure,
      );
      expect(
        flowPhaseForElapsed(const Duration(seconds: 10, milliseconds: 799)),
        BioDetectorFlowPhase.pressure,
      );
      expect(
        flowPhaseForElapsed(const Duration(seconds: 10, milliseconds: 800)),
        BioDetectorFlowPhase.result,
      );
    });
  });
}
