import 'dart:math';
import 'dart:ui';

enum GravityBalanceDifficulty { easy, medium, hard }

class GravityBalanceSessionResult {
  const GravityBalanceSessionResult({
    required this.playerIndex,
    required this.success,
    required this.elapsedSeconds,
  });

  final int playerIndex;
  final bool success;
  final double elapsedSeconds;
}

class GravityBalanceDifficultyConfig {
  const GravityBalanceDifficultyConfig({
    required this.minAnchors,
    required this.maxAnchors,
    required this.horizontalSpreadFactor,
    required this.swayAmplitudeMultiplier,
    required this.swayStartProgress,
  });

  final int minAnchors;
  final int maxAnchors;
  final double horizontalSpreadFactor;
  final double swayAmplitudeMultiplier;
  final double swayStartProgress;
}

GravityBalanceDifficulty parseGravityBalanceDifficulty(String? raw) {
  return switch (raw) {
    'easy' => GravityBalanceDifficulty.easy,
    'hard' => GravityBalanceDifficulty.hard,
    _ => GravityBalanceDifficulty.medium,
  };
}

int parseGravityBalanceParticipantCount(
  String? raw, {
  int min = 1,
  int max = 8,
  int fallback = 2,
}) {
  final parsed = int.tryParse(raw ?? '');
  if (parsed == null) {
    return fallback;
  }
  return parsed.clamp(min, max).toInt();
}

String gravityBalanceDifficultyId(GravityBalanceDifficulty difficulty) {
  return switch (difficulty) {
    GravityBalanceDifficulty.easy => 'easy',
    GravityBalanceDifficulty.medium => 'medium',
    GravityBalanceDifficulty.hard => 'hard',
  };
}

GravityBalanceSessionResult? gravityBalanceChampion(
  List<GravityBalanceSessionResult> results,
) {
  if (results.isEmpty || results.any((result) => !result.success)) {
    return null;
  }

  var champion = results.first;
  for (final result in results.skip(1)) {
    if (result.elapsedSeconds < champion.elapsedSeconds) {
      champion = result;
    }
  }
  return champion;
}

GravityBalanceDifficultyConfig gravityBalanceDifficultyConfig(
  GravityBalanceDifficulty difficulty,
) {
  return switch (difficulty) {
    GravityBalanceDifficulty.easy => const GravityBalanceDifficultyConfig(
        minAnchors: 4,
        maxAnchors: 5,
        horizontalSpreadFactor: 0.14,
        swayAmplitudeMultiplier: 0.45,
        swayStartProgress: 0.65,
      ),
    GravityBalanceDifficulty.medium => const GravityBalanceDifficultyConfig(
        minAnchors: 5,
        maxAnchors: 7,
        horizontalSpreadFactor: 0.28,
        swayAmplitudeMultiplier: 0.9,
        swayStartProgress: 0.5,
      ),
    GravityBalanceDifficulty.hard => const GravityBalanceDifficultyConfig(
        minAnchors: 7,
        maxAnchors: 9,
        horizontalSpreadFactor: 0.4,
        swayAmplitudeMultiplier: 1.3,
        swayStartProgress: 0.38,
      ),
  };
}

class DeviceTilt {
  const DeviceTilt({
    required this.pitch,
    required this.roll,
  });

  final double pitch;
  final double roll;
}

class VerletBallState {
  const VerletBallState({
    required this.position,
    required this.previousPosition,
  });

  final Offset position;
  final Offset previousPosition;

  Offset get velocity => position - previousPosition;
}

VerletBallState simulateVerletStep({
  required VerletBallState state,
  required DeviceTilt tilt,
  required double deltaSeconds,
  double gravityAcceleration = 1400,
  double dampingPerFrame = 0.02,
  Offset externalAcceleration = Offset.zero,
}) {
  final dampingFactor = (1 - dampingPerFrame).clamp(0.0, 1.0);
  final acceleration = Offset(
        gravityAcceleration * sin(tilt.roll),
        gravityAcceleration * sin(tilt.pitch),
      ) +
      externalAcceleration;

  final dampedVelocity = state.velocity * dampingFactor;
  final nextPosition = state.position +
      dampedVelocity +
      acceleration * (deltaSeconds * deltaSeconds);

  return VerletBallState(
    position: nextPosition,
    previousPosition: state.position,
  );
}

class GravityBalancePath {
  const GravityBalancePath({
    required this.anchors,
    required this.sampledCenterline,
    required this.trackWidth,
  });

  final List<Offset> anchors;
  final List<Offset> sampledCenterline;
  final double trackWidth;

  Offset get start => sampledCenterline.first;
  Offset get end => sampledCenterline.last;
}

class GravityBalancePathGenerator {
  static GravityBalancePath generate({
    required Random random,
    required Size arenaSize,
    required double ballDiameter,
    GravityBalanceDifficulty difficulty = GravityBalanceDifficulty.medium,
  }) {
    final config = gravityBalanceDifficultyConfig(difficulty);
    final anchorCount = config.minAnchors +
        random.nextInt(config.maxAnchors - config.minAnchors + 1);
    final topPadding = max(ballDiameter * 1.2, 24.0);
    final bottomPadding = max(ballDiameter * 1.2, 24.0);
    final verticalSpan =
        max(1.0, arenaSize.height - topPadding - bottomPadding);

    final centerX = arenaSize.width / 2;
    final horizontalSpread = max(
      ballDiameter * 0.45,
      arenaSize.width * config.horizontalSpreadFactor,
    );

    final anchors = <Offset>[];
    for (int i = 0; i < anchorCount; i++) {
      final progress = anchorCount == 1 ? 0.0 : i / (anchorCount - 1);
      final y = topPadding + verticalSpan * progress;
      if (i == 0 || i == anchorCount - 1) {
        anchors.add(Offset(centerX, y));
      } else {
        final noise = (random.nextDouble() * 2 - 1) * horizontalSpread;
        final x = (centerX + noise)
            .clamp(ballDiameter, arenaSize.width - ballDiameter);
        anchors.add(Offset(x, y));
      }
    }

    final sampled = sampleBezierCenterline(anchors, samplesPerSegment: 24);

    return GravityBalancePath(
      anchors: anchors,
      sampledCenterline: sampled,
      trackWidth: ballDiameter * 1.5,
    );
  }
}

List<Offset> sampleBezierCenterline(
  List<Offset> anchors, {
  int samplesPerSegment = 20,
}) {
  if (anchors.isEmpty) {
    return const <Offset>[];
  }
  if (anchors.length == 1) {
    return List<Offset>.from(anchors);
  }

  final points = <Offset>[anchors.first];

  for (int i = 0; i < anchors.length - 1; i++) {
    final p0 = i > 0 ? anchors[i - 1] : anchors[i];
    final p1 = anchors[i];
    final p2 = anchors[i + 1];
    final p3 = i + 2 < anchors.length ? anchors[i + 2] : p2;

    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;

    for (int s = 1; s <= samplesPerSegment; s++) {
      final t = s / samplesPerSegment;
      points.add(_cubicBezierPoint(p1, c1, c2, p2, t));
    }
  }

  return points;
}

Offset _cubicBezierPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  final u = 1 - t;
  return p0 * (u * u * u) +
      p1 * (3 * u * u * t) +
      p2 * (3 * u * t * t) +
      p3 * (t * t * t);
}

double circleOverlapArea({
  required double radiusA,
  required double radiusB,
  required double centerDistance,
}) {
  if (radiusA <= 0 || radiusB <= 0) {
    return 0;
  }

  if (centerDistance >= radiusA + radiusB) {
    return 0;
  }

  if (centerDistance <= (radiusA - radiusB).abs()) {
    final smallerRadius = min(radiusA, radiusB);
    return pi * smallerRadius * smallerRadius;
  }

  final angleA = 2 *
      acos(
        (((centerDistance * centerDistance) +
                    (radiusA * radiusA) -
                    (radiusB * radiusB)) /
                (2 * centerDistance * radiusA))
            .clamp(-1.0, 1.0),
      );
  final angleB = 2 *
      acos(
        (((centerDistance * centerDistance) +
                    (radiusB * radiusB) -
                    (radiusA * radiusA)) /
                (2 * centerDistance * radiusB))
            .clamp(-1.0, 1.0),
      );

  final segmentA = 0.5 * radiusA * radiusA * (angleA - sin(angleA));
  final segmentB = 0.5 * radiusB * radiusB * (angleB - sin(angleB));
  return segmentA + segmentB;
}

double ballHoleOverlapRatio({
  required double ballRadius,
  required double holeRadius,
  required double centerDistance,
}) {
  if (ballRadius <= 0) {
    return 0;
  }
  final ballArea = pi * ballRadius * ballRadius;
  if (ballArea == 0) {
    return 0;
  }
  return circleOverlapArea(
        radiusA: ballRadius,
        radiusB: holeRadius,
        centerDistance: centerDistance,
      ) /
      ballArea;
}

bool isBallCapturedByHole({
  required double ballRadius,
  required double holeRadius,
  required double centerDistance,
  double requiredBallOverlapRatio = 0.35,
}) {
  return ballHoleOverlapRatio(
        ballRadius: ballRadius,
        holeRadius: holeRadius,
        centerDistance: centerDistance,
      ) >=
      requiredBallOverlapRatio;
}

class ShockScheduler {
  ShockScheduler({
    required this.random,
    this.minIntervalSeconds = 3,
    this.maxIntervalSeconds = 7,
  }) : _nextTriggerSeconds = minIntervalSeconds +
            random.nextDouble() * (maxIntervalSeconds - minIntervalSeconds);

  final Random random;
  final double minIntervalSeconds;
  final double maxIntervalSeconds;

  double _nextTriggerSeconds;

  double get nextTriggerSeconds => _nextTriggerSeconds;

  bool consumeIfTriggered(double elapsedSeconds) {
    if (elapsedSeconds < _nextTriggerSeconds) {
      return false;
    }
    final nextInterval = minIntervalSeconds +
        random.nextDouble() * (maxIntervalSeconds - minIntervalSeconds);
    _nextTriggerSeconds = elapsedSeconds + nextInterval;
    return true;
  }
}

class OutOfBoundsJudge {
  OutOfBoundsJudge({
    this.bufferSeconds = 0.3,
  });

  final double bufferSeconds;
  double _accumulatedOutSeconds = 0;

  double get accumulatedOutSeconds => _accumulatedOutSeconds;
  bool get isBuffering => _accumulatedOutSeconds > 0;

  bool update({
    required bool isOutOfBounds,
    required double deltaSeconds,
  }) {
    if (!isOutOfBounds) {
      _accumulatedOutSeconds = 0;
      return false;
    }

    _accumulatedOutSeconds += deltaSeconds;
    return _accumulatedOutSeconds > bufferSeconds;
  }

  void reset() {
    _accumulatedOutSeconds = 0;
  }
}

List<Offset> buildLiquidControlPoints({
  required Offset center,
  required double radius,
  required Offset velocity,
  int pointCount = 12,
  double maxStretch = 0.28,
}) {
  if (pointCount < 3) {
    throw ArgumentError.value(pointCount, 'pointCount', 'must be >= 3');
  }

  final speed = velocity.distance;
  final stretch = (speed / 500).clamp(0.0, maxStretch);
  final oppositeDirection = atan2(-velocity.dy, -velocity.dx);

  final points = <Offset>[];
  for (int i = 0; i < pointCount; i++) {
    final angle = 2 * pi * (i / pointCount);
    final angleDelta = _normalizeAngle(angle - oppositeDirection);
    final directionalWeight = max(0.0, cos(angleDelta));
    final localRadius = radius * (1 + stretch * directionalWeight);

    points.add(
      center + Offset(cos(angle) * localRadius, sin(angle) * localRadius),
    );
  }
  return points;
}

double _normalizeAngle(double angle) {
  var a = angle;
  while (a <= -pi) {
    a += 2 * pi;
  }
  while (a > pi) {
    a -= 2 * pi;
  }
  return a;
}

List<Offset> applyPathSway({
  required List<Offset> baseCenterline,
  required double elapsedSeconds,
  double frequencyHz = 0.5,
  double amplitude = 24,
  double startProgress = 0.5,
}) {
  if (baseCenterline.length <= 1 || amplitude == 0) {
    return List<Offset>.from(baseCenterline);
  }

  final waveOffset = amplitude * sin(2 * pi * frequencyHz * elapsedSeconds);
  final lastIndex = baseCenterline.length - 1;

  return List<Offset>.generate(baseCenterline.length, (index) {
    final progress = index / lastIndex;
    if (progress <= startProgress) {
      return baseCenterline[index];
    }

    final influence =
        ((progress - startProgress) / (1 - startProgress)).clamp(0.0, 1.0);
    return baseCenterline[index].translate(waveOffset * influence, 0);
  });
}

double distanceToPolyline(Offset point, List<Offset> polyline) {
  return projectPointToPolyline(point, polyline).distance;
}

class PolylineProjection {
  const PolylineProjection({
    required this.distance,
    required this.nearestPoint,
    required this.progress,
  });

  final double distance;
  final Offset nearestPoint;
  final double progress;
}

PolylineProjection projectPointToPolyline(Offset point, List<Offset> polyline) {
  if (polyline.isEmpty) {
    return PolylineProjection(
      distance: double.infinity,
      nearestPoint: point,
      progress: 0,
    );
  }
  if (polyline.length == 1) {
    return PolylineProjection(
      distance: (point - polyline.first).distance,
      nearestPoint: polyline.first,
      progress: 1,
    );
  }

  double totalLength = 0;
  final segmentLengths = <double>[];
  for (int i = 0; i < polyline.length - 1; i++) {
    final length = (polyline[i + 1] - polyline[i]).distance;
    segmentLengths.add(length);
    totalLength += length;
  }

  double bestDistance = double.infinity;
  Offset bestPoint = polyline.first;
  double bestProgressDistance = 0;

  double traversed = 0;
  for (int i = 0; i < polyline.length - 1; i++) {
    final a = polyline[i];
    final b = polyline[i + 1];
    final projection = _projectPointToSegment(point, a, b);
    final distance = (point - projection.projected).distance;

    if (distance < bestDistance) {
      bestDistance = distance;
      bestPoint = projection.projected;
      bestProgressDistance = traversed + segmentLengths[i] * projection.t;
    }

    traversed += segmentLengths[i];
  }

  final progress = totalLength <= 0
      ? 0.0
      : (bestProgressDistance / totalLength).clamp(0.0, 1.0);

  return PolylineProjection(
    distance: bestDistance,
    nearestPoint: bestPoint,
    progress: progress,
  );
}

class _SegmentProjection {
  const _SegmentProjection({
    required this.projected,
    required this.t,
  });

  final Offset projected;
  final double t;
}

_SegmentProjection _projectPointToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final abLengthSquared = ab.dx * ab.dx + ab.dy * ab.dy;
  if (abLengthSquared <= 0) {
    return _SegmentProjection(projected: a, t: 0);
  }

  final ap = p - a;
  final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / abLengthSquared).clamp(0.0, 1.0);
  return _SegmentProjection(
    projected: a + ab * t,
    t: t,
  );
}
