import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/gravity_balance/logic/gravity_balance_logic.dart';

void main() {
  test('path generator creates medium anchors and 1.5x track width', () {
    final path = GravityBalancePathGenerator.generate(
      random: Random(42),
      arenaSize: const Size(360, 640),
      ballDiameter: 40,
    );

    expect(path.anchors.length, inInclusiveRange(5, 7));
    expect(path.trackWidth, closeTo(60, 0.0001));
    expect(path.sampledCenterline.length, greaterThan(80));
  });

  test('hard difficulty produces more lateral path complexity than easy', () {
    const arenaSize = Size(360, 640);
    final centerX = arenaSize.width / 2;

    final easyPath = GravityBalancePathGenerator.generate(
      random: Random(11),
      arenaSize: arenaSize,
      ballDiameter: 40,
      difficulty: GravityBalanceDifficulty.easy,
    );
    final hardPath = GravityBalancePathGenerator.generate(
      random: Random(11),
      arenaSize: arenaSize,
      ballDiameter: 40,
      difficulty: GravityBalanceDifficulty.hard,
    );

    final easyDeviation = easyPath.anchors
            .skip(1)
            .take(easyPath.anchors.length - 2)
            .fold<double>(0, (sum, p) => sum + (p.dx - centerX).abs()) /
        (easyPath.anchors.length - 2);
    final hardDeviation = hardPath.anchors
            .skip(1)
            .take(hardPath.anchors.length - 2)
            .fold<double>(0, (sum, p) => sum + (p.dx - centerX).abs()) /
        (hardPath.anchors.length - 2);

    expect(easyPath.anchors.length, inInclusiveRange(4, 5));
    expect(hardPath.anchors.length, inInclusiveRange(7, 9));
    expect(hardDeviation, greaterThan(easyDeviation));
  });

  test('difficulty parser supports easy/medium/hard ids', () {
    expect(
      parseGravityBalanceDifficulty('easy'),
      GravityBalanceDifficulty.easy,
    );
    expect(
      parseGravityBalanceDifficulty('medium'),
      GravityBalanceDifficulty.medium,
    );
    expect(
      parseGravityBalanceDifficulty('hard'),
      GravityBalanceDifficulty.hard,
    );
    expect(
      parseGravityBalanceDifficulty('unknown'),
      GravityBalanceDifficulty.medium,
    );

    expect(gravityBalanceDifficultyId(GravityBalanceDifficulty.easy), 'easy');
    expect(
      gravityBalanceDifficultyId(GravityBalanceDifficulty.medium),
      'medium',
    );
    expect(gravityBalanceDifficultyId(GravityBalanceDifficulty.hard), 'hard');
  });

  test('participant count parser supports fallback and clamping', () {
    expect(parseGravityBalanceParticipantCount(null), 2);
    expect(parseGravityBalanceParticipantCount('abc'), 2);
    expect(parseGravityBalanceParticipantCount('0'), 1);
    expect(parseGravityBalanceParticipantCount('3'), 3);
    expect(parseGravityBalanceParticipantCount('99'), 8);
  });

  test('champion exists only when everyone succeeds', () {
    final noChampion = gravityBalanceChampion(const [
      GravityBalanceSessionResult(
        playerIndex: 0,
        success: true,
        elapsedSeconds: 12.4,
      ),
      GravityBalanceSessionResult(
        playerIndex: 1,
        success: false,
        elapsedSeconds: 15.8,
      ),
    ]);
    expect(noChampion, isNull);

    final champion = gravityBalanceChampion(const [
      GravityBalanceSessionResult(
        playerIndex: 0,
        success: true,
        elapsedSeconds: 12.4,
      ),
      GravityBalanceSessionResult(
        playerIndex: 1,
        success: true,
        elapsedSeconds: 10.1,
      ),
      GravityBalanceSessionResult(
        playerIndex: 2,
        success: true,
        elapsedSeconds: 11.3,
      ),
    ]);
    expect(champion, isNotNull);
    expect(champion!.playerIndex, 1);
    expect(champion.elapsedSeconds, 10.1);
  });

  test('shock scheduler triggers and reschedules within 3-7 seconds', () {
    final scheduler = ShockScheduler(random: Random(1));
    final firstTrigger = scheduler.nextTriggerSeconds;

    expect(firstTrigger, inInclusiveRange(3, 7));

    final triggered = scheduler.consumeIfTriggered(firstTrigger + 0.01);
    expect(triggered, isTrue);

    final delta = scheduler.nextTriggerSeconds - (firstTrigger + 0.01);
    expect(delta, inInclusiveRange(3, 7));
  });

  test('out-of-bounds buffer explodes only after 0.3s continuous timeout', () {
    final judge = OutOfBoundsJudge(bufferSeconds: 0.3);

    expect(
      judge.update(isOutOfBounds: true, deltaSeconds: 0.10),
      isFalse,
    );
    expect(
      judge.update(isOutOfBounds: true, deltaSeconds: 0.10),
      isFalse,
    );
    expect(
      judge.update(isOutOfBounds: true, deltaSeconds: 0.11),
      isTrue,
    );

    judge.reset();
    expect(
      judge.update(isOutOfBounds: true, deltaSeconds: 0.20),
      isFalse,
    );
    expect(
      judge.update(isOutOfBounds: false, deltaSeconds: 0.10),
      isFalse,
    );
    expect(
      judge.update(isOutOfBounds: true, deltaSeconds: 0.12),
      isFalse,
    );
  });

  test('verlet integrator keeps 2% damping per frame without acceleration', () {
    const state = VerletBallState(
      position: Offset(100, 100),
      previousPosition: Offset(90, 100),
    );

    final next = simulateVerletStep(
      state: state,
      tilt: const DeviceTilt(pitch: 0, roll: 0),
      deltaSeconds: 1 / 60,
    );

    expect(next.velocity.dx, closeTo(9.8, 0.001));
    expect(next.velocity.dy, closeTo(0, 0.0001));
  });

  test('liquid ball produces 12 points and stretches opposite to movement', () {
    final points = buildLiquidControlPoints(
      center: const Offset(100, 100),
      radius: 20,
      velocity: const Offset(50, 0),
    );

    expect(points, hasLength(12));

    final frontDistance = (points.first - const Offset(100, 100)).distance;
    final backDistance = (points[6] - const Offset(100, 100)).distance;

    expect(backDistance, greaterThan(frontDistance));
    expect(backDistance, greaterThan(20));
  });

  test('distance to centerline uses nearest segment', () {
    final distance = distanceToPolyline(
      const Offset(50, 10),
      const [Offset(0, 0), Offset(100, 0)],
    );

    expect(distance, closeTo(10, 0.0001));
  });

  test('ball-hole overlap ratio is zero when circles do not intersect', () {
    final ratio = ballHoleOverlapRatio(
      ballRadius: 18,
      holeRadius: 23,
      centerDistance: 41.1,
    );

    expect(ratio, 0);
    expect(
      isBallCapturedByHole(
        ballRadius: 18,
        holeRadius: 23,
        centerDistance: 41.1,
      ),
      isFalse,
    );
  });

  test('ball is captured once more than half of its area overlaps the hole',
      () {
    expect(
      ballHoleOverlapRatio(
        ballRadius: 18,
        holeRadius: 23,
        centerDistance: 20.4,
      ),
      greaterThan(0.5),
    );
    expect(
      isBallCapturedByHole(
        ballRadius: 18,
        holeRadius: 23,
        centerDistance: 20.4,
      ),
      isTrue,
    );
  });

  test('default hole capture accepts partial overlap before half coverage', () {
    final ratio = ballHoleOverlapRatio(
      ballRadius: 18,
      holeRadius: 23,
      centerDistance: 20.6,
    );

    expect(ratio, lessThan(0.5));
    expect(ratio, greaterThan(0.35));
    expect(
      isBallCapturedByHole(
        ballRadius: 18,
        holeRadius: 23,
        centerDistance: 20.6,
      ),
      isTrue,
    );
  });

  test('hole capture still fails when overlap is too shallow', () {
    expect(
      isBallCapturedByHole(
        ballRadius: 18,
        holeRadius: 23,
        centerDistance: 41.1,
        requiredBallOverlapRatio: 0.35,
      ),
      isFalse,
    );
  });
}
