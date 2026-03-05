import 'dart:math';
import 'dart:ui';

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
  }) {
    final anchorCount = 5 + random.nextInt(4);
    final topPadding = max(ballDiameter * 1.2, 24.0);
    final bottomPadding = max(ballDiameter * 1.2, 24.0);
    final verticalSpan =
        max(1.0, arenaSize.height - topPadding - bottomPadding);

    final centerX = arenaSize.width / 2;
    final horizontalSpread = max(ballDiameter, arenaSize.width * 0.32);

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
