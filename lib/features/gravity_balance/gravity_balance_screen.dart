import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/haptics/haptic_service.dart';
import '../../core/help/game_help_service.dart';
import '../../core/sensors/device_motion_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/web3_game_background.dart';
import 'logic/gravity_balance_logic.dart';

enum _GravityBalanceState { playing, exploded, completed }

class GravityBalanceScreen extends ConsumerStatefulWidget {
  const GravityBalanceScreen({super.key});

  @override
  ConsumerState<GravityBalanceScreen> createState() =>
      _GravityBalanceScreenState();
}

class _GravityBalanceScreenState extends ConsumerState<GravityBalanceScreen>
    with SingleTickerProviderStateMixin {
  static const double _ballDiameter = 36;

  final Random _random = Random();
  final OutOfBoundsJudge _outOfBoundsJudge = OutOfBoundsJudge();

  late final Ticker _ticker;

  Size? _arenaSize;
  GravityBalancePath? _path;
  List<Offset> _activeCenterline = const <Offset>[];
  VerletBallState? _ballState;
  ShockScheduler? _shockScheduler;

  Duration _lastElapsed = Duration.zero;
  double _elapsedSeconds = 0;
  double _progress = 0;

  double _earthquakeRemainingSeconds = 0;
  double _earthquakeForceX = 0;

  bool _showHelpButton = false;
  bool _arenaInitScheduled = false;
  _GravityBalanceState _state = _GravityBalanceState.playing;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFirstTimeHelp();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _showFirstTimeHelp() async {
    final l10n = AppLocalizations.of(context);
    await GameHelpService.ensureFirstTimeShown(
      context: context,
      gameId: 'gravity_balance',
      gameTitle: l10n.t('gravityBalance'),
      helpBody: l10n.t('helpGravityBalanceBody'),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _showHelpButton = true;
    });
  }

  void _ensureArena(Size size) {
    final current = _arenaSize;
    if (_path != null && current != null) {
      final sameSize = (current.width - size.width).abs() < 0.5 &&
          (current.height - size.height).abs() < 0.5;
      if (sameSize) {
        return;
      }
    }

    if (_arenaInitScheduled) {
      return;
    }

    _arenaInitScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _arenaInitScheduled = false;
      if (!mounted) {
        return;
      }
      _arenaSize = size;
      _resetGame();
    });
  }

  void _resetGame() {
    final size = _arenaSize;
    if (size == null) {
      return;
    }

    final path = GravityBalancePathGenerator.generate(
      random: _random,
      arenaSize: size,
      ballDiameter: _ballDiameter,
    );

    _path = path;
    _activeCenterline = path.sampledCenterline;
    _ballState = VerletBallState(
      position: path.start,
      previousPosition: path.start,
    );
    _shockScheduler = ShockScheduler(random: _random);

    _state = _GravityBalanceState.playing;
    _outOfBoundsJudge.reset();
    _lastElapsed = Duration.zero;
    _elapsedSeconds = 0;
    _progress = 0;
    _earthquakeRemainingSeconds = 0;
    _earthquakeForceX = 0;

    if (!_ticker.isActive) {
      _ticker.start();
    }

    setState(() {});
  }

  void _tick(Duration elapsed) {
    if (!mounted || _state != _GravityBalanceState.playing) {
      return;
    }

    final path = _path;
    final ball = _ballState;
    final scheduler = _shockScheduler;
    final arenaSize = _arenaSize;

    if (path == null ||
        ball == null ||
        scheduler == null ||
        arenaSize == null) {
      return;
    }

    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final dtRaw = (elapsed - _lastElapsed).inMicroseconds / 1000000;
    _lastElapsed = elapsed;
    final dt = dtRaw.clamp(0.0, 0.05);
    if (dt == 0) {
      return;
    }

    _elapsedSeconds += dt;

    if (scheduler.consumeIfTriggered(_elapsedSeconds)) {
      _triggerEarthquake();
    }

    if (_earthquakeRemainingSeconds > 0) {
      _earthquakeRemainingSeconds = max(0, _earthquakeRemainingSeconds - dt);
      if (_earthquakeRemainingSeconds == 0) {
        _earthquakeForceX = 0;
      }
    }

    final tiltAsync = ref.read(deviceTiltProvider);
    final tilt = tiltAsync.asData?.value ?? const DeviceTilt(pitch: 0, roll: 0);

    var nextState = simulateVerletStep(
      state: ball,
      tilt: tilt,
      deltaSeconds: dt,
      externalAcceleration: Offset(_earthquakeForceX, 0),
    );

    nextState = _clampBallState(nextState, arenaSize);

    _activeCenterline = applyPathSway(
      baseCenterline: path.sampledCenterline,
      elapsedSeconds: _elapsedSeconds,
      frequencyHz: 0.5,
      amplitude: _ballDiameter * 0.9,
      startProgress: 0.5,
    );

    final projection =
        projectPointToPolyline(nextState.position, _activeCenterline);
    final isOutOfBounds = projection.distance > path.trackWidth / 2;
    final exploded = _outOfBoundsJudge.update(
      isOutOfBounds: isOutOfBounds,
      deltaSeconds: dt,
    );

    _progress = projection.progress;
    _ballState = nextState;

    if (exploded) {
      _state = _GravityBalanceState.exploded;
      _ticker.stop();
      HapticService.tripleHeavyImpact();
    } else if (_progress >= 0.995 &&
        projection.distance <= path.trackWidth * 0.35) {
      _state = _GravityBalanceState.completed;
      _ticker.stop();
      HapticService.notificationSuccess();
    }

    setState(() {});
  }

  VerletBallState _clampBallState(VerletBallState state, Size arenaSize) {
    const radius = _ballDiameter / 2;
    final clampedPosition = Offset(
      state.position.dx.clamp(radius, arenaSize.width - radius).toDouble(),
      state.position.dy.clamp(radius, arenaSize.height - radius).toDouble(),
    );

    if (clampedPosition == state.position) {
      return state;
    }

    final dampedVelocity = state.velocity * 0.35;
    return VerletBallState(
      position: clampedPosition,
      previousPosition: clampedPosition - dampedVelocity,
    );
  }

  void _triggerEarthquake() {
    if (_state != _GravityBalanceState.playing) {
      return;
    }

    final direction = _random.nextBool() ? 1.0 : -1.0;

    _earthquakeRemainingSeconds = 0.95;
    _earthquakeForceX = 2800 * direction;
    HapticService.heavyImpact();

    final ball = _ballState;
    if (ball != null) {
      final impulse = Offset(direction * (_ballDiameter * 0.45), 0);
      _ballState = VerletBallState(
        position: ball.position + impulse,
        previousPosition: ball.previousPosition,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.watch(deviceTiltProvider);

    final flashOpacity = (_outOfBoundsJudge.accumulatedOutSeconds /
            _outOfBoundsJudge.bufferSeconds)
        .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Web3GameBackground(
            accentColor: Color(0xFF4DFFD8),
            secondaryColor: Color(0xFFFF6B6B),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        color: Colors.white,
                      ),
                      Expanded(
                        child: Text(
                          l10n.t('gravityBalance'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      _showHelpButton
                          ? GameHelpButton(
                              onTap: () {
                                GameHelpService.showGameHelpDialog(
                                  context,
                                  gameTitle: l10n.t('gravityBalance'),
                                  helpBody: l10n.t('helpGravityBalanceBody'),
                                );
                              },
                            )
                          : const SizedBox(width: 32, height: 32),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.t('gravityBalanceRule'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ProgressIndicator(progress: _progress),
                  const SizedBox(height: 10),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _ensureArena(constraints.biggest);
                        final path = _path;
                        final ball = _ballState;

                        if (path == null || ball == null) {
                          return const SizedBox.expand();
                        }

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            RepaintBoundary(
                              child: CustomPaint(
                                painter: _GravityBalancePainter(
                                  centerline: _activeCenterline,
                                  ballState: ball,
                                  trackWidth: path.trackWidth,
                                  ballRadius: _ballDiameter / 2,
                                  exploded:
                                      _state == _GravityBalanceState.exploded,
                                ),
                              ),
                            ),
                            IgnorePointer(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 80),
                                opacity: _state == _GravityBalanceState.playing
                                    ? flashOpacity * 0.75
                                    : 0,
                                child: Container(
                                  color: const Color(0x55FF1A1A),
                                ),
                              ),
                            ),
                            if (_earthquakeRemainingSeconds > 0 &&
                                _state == _GravityBalanceState.playing)
                              Align(
                                alignment: const Alignment(0, -0.72),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xCC1A0000),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFFF6B6B),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.t('gravityBalanceQuake'),
                                    style: const TextStyle(
                                      color: Color(0xFFFF9B9B),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ),
                            if (_state != _GravityBalanceState.playing)
                              _ResultOverlay(
                                title: _state == _GravityBalanceState.completed
                                    ? l10n.t('gravityBalanceCompleted')
                                    : l10n.t('gravityBalanceExploded'),
                                onRetry: _resetGame,
                                retryLabel: l10n.t('gravityBalanceRetry'),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [Color(0xFF4DFFD8), Color(0xFF96FF4D)],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.title,
    required this.onRetry,
    required this.retryLabel,
  });

  final String title;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xE60D0F16),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DFFD8),
                  foregroundColor: Colors.black,
                ),
                child: Text(retryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GravityBalancePainter extends CustomPainter {
  const _GravityBalancePainter({
    required this.centerline,
    required this.ballState,
    required this.trackWidth,
    required this.ballRadius,
    required this.exploded,
  });

  final List<Offset> centerline;
  final VerletBallState ballState;
  final double trackWidth;
  final double ballRadius;
  final bool exploded;

  @override
  void paint(Canvas canvas, Size size) {
    if (centerline.length < 2) {
      return;
    }

    final trackPath = _polylineToPath(centerline);

    final trackGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0x554DFFD8);

    final centerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF9DFFF1);

    canvas.drawPath(trackPath, trackGlow);
    canvas.drawPath(trackPath, centerStroke);

    final markerPaint = Paint()..color = Colors.white.withAlpha(210);
    canvas.drawCircle(centerline.first, 5, markerPaint);
    canvas.drawCircle(centerline.last, 5, markerPaint);

    final controlPoints = buildLiquidControlPoints(
      center: ballState.position,
      radius: ballRadius,
      velocity: ballState.velocity,
      pointCount: 12,
    );

    final ballPath = _smoothClosedPath(controlPoints);
    final ballShader = RadialGradient(
      colors: exploded
          ? const [Color(0xFFFF7A7A), Color(0xFFFF1A1A), Color(0xAA7A0000)]
          : const [Color(0xFFC8FFF7), Color(0xFF4DFFD8), Color(0xAA0098AA)],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(
      Rect.fromCircle(center: ballState.position, radius: ballRadius * 1.25),
    );

    canvas.drawPath(
      ballPath,
      Paint()..shader = ballShader,
    );
    canvas.drawPath(
      ballPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withAlpha(160),
    );

    if (exploded) {
      final sparkPaint = Paint()
        ..color = const Color(0xFFFFC2C2)
        ..strokeWidth = 2;
      for (int i = 0; i < 8; i++) {
        final angle = (pi * 2 * i) / 8;
        final start = ballState.position + Offset(cos(angle), sin(angle)) * 16;
        final end = ballState.position + Offset(cos(angle), sin(angle)) * 30;
        canvas.drawLine(start, end, sparkPaint);
      }
    }
  }

  Path _polylineToPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path;
  }

  Path _smoothClosedPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) {
      return path;
    }

    final firstMid = Offset(
      (points.last.dx + points.first.dx) / 2,
      (points.last.dy + points.first.dy) / 2,
    );
    path.moveTo(firstMid.dx, firstMid.dy);

    for (int i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      final mid = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _GravityBalancePainter oldDelegate) {
    return centerline != oldDelegate.centerline ||
        ballState.position != oldDelegate.ballState.position ||
        ballState.previousPosition != oldDelegate.ballState.previousPosition ||
        exploded != oldDelegate.exploded ||
        trackWidth != oldDelegate.trackWidth;
  }
}
