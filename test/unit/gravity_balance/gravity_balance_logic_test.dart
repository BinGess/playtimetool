import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/gravity_balance/logic/gravity_balance_logic.dart';

void main() {
  test('path generator creates 5-8 anchors and 1.5x track width', () {
    final path = GravityBalancePathGenerator.generate(
      random: Random(42),
      arenaSize: const Size(360, 640),
      ballDiameter: 40,
    );

    expect(path.anchors.length, inInclusiveRange(5, 8));
    expect(path.trackWidth, closeTo(60, 0.0001));
    expect(path.sampledCenterline.length, greaterThan(80));
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
}
