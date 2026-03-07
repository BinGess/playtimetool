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
import '../../shared/services/penalty_service.dart';
import '../../shared/widgets/penalty_blind_box_overlay.dart';
import '../../shared/styles/game_ui_style.dart';
import '../../shared/widgets/web3_game_background.dart';
import 'logic/gravity_balance_logic.dart';

enum _GravityBalanceState { playing, exploded, failed, completed }

enum _GravityBalanceSessionView { playing, roundResult, finalSummary }

class _GravityDifficultyConfig {
  const _GravityDifficultyConfig({
    required this.trackWidthMultiplier,
    required this.swayAmplitudeMultiplier,
    required this.quakeForce,
    required this.minShockInterval,
    required this.maxShockInterval,
    this.swayStartProgress = 0.5,
  });

  final double trackWidthMultiplier;
  final double swayAmplitudeMultiplier;
  final double quakeForce;
  final double minShockInterval;
  final double maxShockInterval;
  final double swayStartProgress;
}

class GravityBalanceDebugController {
  VoidCallback? _advanceFromRoundResult;
  VoidCallback? _showFinalSummary;
  void Function({required bool success, required double elapsedSeconds})?
      _finishRound;

  @visibleForTesting
  void finishRound({
    required bool success,
    double elapsedSeconds = 1,
  }) {
    _finishRound?.call(success: success, elapsedSeconds: elapsedSeconds);
  }

  @visibleForTesting
  void showFinalSummary() {
    _showFinalSummary?.call();
  }

  @visibleForTesting
  void advanceFromRoundResult() {
    _advanceFromRoundResult?.call();
  }
}

class GravityBalanceScreen extends ConsumerStatefulWidget {
  const GravityBalanceScreen({
    super.key,
    this.difficulty = GravityBalanceDifficulty.medium,
    this.participantCount = 2,
    this.penaltyPreset = PenaltyPreset.defaults,
    this.debugController,
  });

  final GravityBalanceDifficulty difficulty;
  final int participantCount;
  final PenaltyPreset penaltyPreset;
  final GravityBalanceDebugController? debugController;

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
  _GravityBalanceSessionView _sessionView = _GravityBalanceSessionView.playing;
  int _playerCount = 4;
  int _currentPlayer = 0;
  List<GravityBalanceSessionResult> _results = const [];
  GravityBalanceDifficulty _difficulty = GravityBalanceDifficulty.medium;
  PenaltyPreset _penaltyPreset = PenaltyPreset.defaults;
  PenaltyBlindBoxResult? _blindBoxResult;

  _GravityDifficultyConfig get _difficultyConfig {
    return switch (_difficulty) {
      GravityBalanceDifficulty.easy => const _GravityDifficultyConfig(
          trackWidthMultiplier: 1.18,
          swayAmplitudeMultiplier: 0.75,
          quakeForce: 2200,
          minShockInterval: 4.5,
          maxShockInterval: 7.5,
          swayStartProgress: 0.3,
        ),
      GravityBalanceDifficulty.medium => const _GravityDifficultyConfig(
          trackWidthMultiplier: 1.0,
          swayAmplitudeMultiplier: 1.0,
          quakeForce: 2800,
          minShockInterval: 3.0,
          maxShockInterval: 7.0,
          swayStartProgress: 0.4,
        ),
      GravityBalanceDifficulty.hard => const _GravityDifficultyConfig(
          trackWidthMultiplier: 0.84,
          swayAmplitudeMultiplier: 1.35,
          quakeForce: 3400,
          minShockInterval: 2.3,
          maxShockInterval: 5.2,
          swayStartProgress: 0.5,
        ),
    };
  }

  @override
  void initState() {
    super.initState();
    _difficulty = widget.difficulty;
    _playerCount = _safeParticipantCount;
    _penaltyPreset = widget.penaltyPreset;
    _attachDebugController(widget.debugController);
    _ticker = createTicker(_tick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFirstTimeHelp();
    });
  }

  @override
  void didUpdateWidget(covariant GravityBalanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.debugController != widget.debugController) {
      _detachDebugController(oldWidget.debugController);
      _attachDebugController(widget.debugController);
    }
  }

  @override
  void dispose() {
    _detachDebugController(widget.debugController);
    _ticker.dispose();
    super.dispose();
  }

  void _attachDebugController(GravityBalanceDebugController? controller) {
    if (controller == null) {
      return;
    }
    controller._finishRound = ({
      required bool success,
      required double elapsedSeconds,
    }) {
      if (!mounted) {
        return;
      }
      _ticker.stop();
      setState(() {
        _elapsedSeconds = elapsedSeconds;
        _state = success
            ? _GravityBalanceState.completed
            : _GravityBalanceState.failed;
        _finishCurrentRound(success: success);
      });
    };
    controller._showFinalSummary = () {
      if (!mounted) {
        return;
      }
      setState(() {
        _blindBoxResult = _buildFinalBlindBoxResult();
        _sessionView = _GravityBalanceSessionView.finalSummary;
      });
    };
    controller._advanceFromRoundResult = () {
      if (!mounted) {
        return;
      }
      _goNextFromRoundResult();
    };
  }

  void _detachDebugController(GravityBalanceDebugController? controller) {
    if (controller == null) {
      return;
    }
    controller._finishRound = null;
    controller._advanceFromRoundResult = null;
    controller._showFinalSummary = null;
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
      difficulty: widget.difficulty,
    );

    _path = GravityBalancePath(
      anchors: path.anchors,
      sampledCenterline: path.sampledCenterline,
      trackWidth: path.trackWidth * _difficultyConfig.trackWidthMultiplier,
    );
    _activeCenterline = path.sampledCenterline;
    _ballState = VerletBallState(
      position: path.start,
      previousPosition: path.start,
    );
    _shockScheduler = ShockScheduler(
      random: _random,
      minIntervalSeconds: _difficultyConfig.minShockInterval,
      maxIntervalSeconds: _difficultyConfig.maxShockInterval,
    );

    _state = _GravityBalanceState.playing;
    _sessionView = _GravityBalanceSessionView.playing;
    _blindBoxResult = null;
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

  void _finishCurrentRound({required bool success}) {
    _results = [
      ..._results,
      GravityBalanceSessionResult(
        playerIndex: _currentPlayer,
        success: success,
        elapsedSeconds: _elapsedSeconds,
      ),
    ];
    _sessionView = _GravityBalanceSessionView.roundResult;
  }

  void _goNextFromRoundResult() {
    if (_results.length >= _safeParticipantCount) {
      setState(() {
        _blindBoxResult = _buildFinalBlindBoxResult();
        _sessionView = _GravityBalanceSessionView.finalSummary;
      });
      return;
    }

    _currentPlayer = (_currentPlayer + 1) % _playerCount;
    _resetGame();
  }

  void _restartSession() {
    _currentPlayer = 0;
    _results = const [];
    _resetGame();
  }

  PenaltyBlindBoxResult? _buildFinalBlindBoxResult() {
    final l10n = AppLocalizations.of(context);
    final losers = _results
        .where((result) => !result.success)
        .map((result) => l10n.playerLabel(result.playerIndex + 1))
        .toList(growable: false);
    if (losers.isEmpty) {
      return null;
    }
    return PenaltyService.resolveBlindBox(
      l10n: l10n,
      random: _random,
      preset: _penaltyPreset,
      losers: losers,
    );
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
      amplitude:
          _ballDiameter * 0.9 * _difficultyConfig.swayAmplitudeMultiplier,
      startProgress: _difficultyConfig.swayStartProgress,
    );

    final projection =
        projectPointToPolyline(nextState.position, _activeCenterline);
    final isOutOfBounds = projection.distance > path.trackWidth / 2;
    final exploded = _outOfBoundsJudge.update(
      isOutOfBounds: isOutOfBounds,
      deltaSeconds: dt,
    );

    final holeCenter = _activeCenterline.last;
    final distanceToHole = (nextState.position - holeCenter).distance;

    _progress = projection.progress;
    _ballState = nextState;

    if (exploded) {
      _state = _GravityBalanceState.exploded;
      _ticker.stop();
      HapticService.tripleHeavyImpact();
      _finishCurrentRound(success: false);
    } else if (_progress >= 0.995) {
      _ticker.stop();
      if (isBallCapturedByHole(
        ballRadius: _ballDiameter / 2,
        holeRadius: _holeVisualRadius(path.trackWidth),
        centerDistance: distanceToHole,
      )) {
        _state = _GravityBalanceState.completed;
        HapticService.notificationSuccess();
        _finishCurrentRound(success: true);
      } else {
        _state = _GravityBalanceState.failed;
        HapticService.notificationWarning();
        _finishCurrentRound(success: false);
      }
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
    _earthquakeForceX = _difficultyConfig.quakeForce * direction;
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
    final latestResult = _results.isEmpty ? null : _results.last;
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
              padding: GameUiSpacing.screenPadding,
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
                          style: GameUiText.navTitle,
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
                    '${l10n.playerLabel(_currentPlayer + 1)} · ${switch (_difficulty) {
                      GravityBalanceDifficulty.easy =>
                        l10n.t('leftRightDifficultyEasy'),
                      GravityBalanceDifficulty.medium =>
                        l10n.t('leftRightDifficultyMedium'),
                      GravityBalanceDifficulty.hard =>
                        l10n.t('leftRightDifficultyHard'),
                    }}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                                  holeCenter: _activeCenterline.last,
                                  holeRadius:
                                      _holeVisualRadius(path.trackWidth),
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
                            if (_sessionView ==
                                _GravityBalanceSessionView.roundResult)
                              _RoundResultOverlay(
                                title:
                                    l10n.t('gravityBalanceRoundResultTitle', {
                                  'player':
                                      l10n.playerLabel(_currentPlayer + 1),
                                }),
                                resultText: latestResult == null
                                    ? ''
                                    : latestResult.success
                                        ? _resultTimeText(l10n, latestResult)
                                        : _resultStatusToken(l10n, false),
                                success: latestResult?.success ?? false,
                                onNext: _goNextFromRoundResult,
                                nextLabel:
                                    _results.length >= _safeParticipantCount
                                        ? l10n.t('gravityBalanceViewSummary')
                                        : l10n.t('nextPlayer'),
                              ),
                            if (_sessionView ==
                                _GravityBalanceSessionView.finalSummary)
                              _FinalSummaryOverlay(
                                l10n: l10n,
                                results: _results,
                                champion: _champion,
                                blindBoxResult: _blindBoxResult,
                                playerLabelBuilder: (i) =>
                                    l10n.playerLabel(i + 1),
                                resultStatusTextBuilder: (s) =>
                                    _resultStatusToken(l10n, s),
                                resultTimeTextBuilder: (r) =>
                                    _resultTimeToken(l10n, r),
                                onRestart: _restartSession,
                                restartLabel: l10n.t('gravityBalanceRetry'),
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

  int get _safeParticipantCount => widget.participantCount.clamp(1, 8).toInt();

  String _secondsText(AppLocalizations l10n, double seconds) {
    return l10n.t('gravityBalanceSeconds', {
      'seconds': seconds.toStringAsFixed(2),
    });
  }

  String _resultStatusToken(AppLocalizations l10n, bool success) {
    return success
        ? l10n.t('gravityBalanceResultSuccessYes')
        : l10n.t('gravityBalanceResultSuccessNo');
  }

  String _resultTimeToken(
    AppLocalizations l10n,
    GravityBalanceSessionResult result,
  ) {
    if (!result.success) {
      return l10n.t('gravityBalanceTimeUnavailable');
    }
    return _secondsText(l10n, result.elapsedSeconds);
  }

  String _resultTimeText(
    AppLocalizations l10n,
    GravityBalanceSessionResult result,
  ) {
    return l10n.t('gravityBalanceResultTime', {
      'time': _resultTimeToken(l10n, result),
    });
  }

  GravityBalanceSessionResult? get _champion =>
      gravityBalanceChampion(_results.toList());

  double _holeVisualRadius(double trackWidth) =>
      max(trackWidth * 0.38, _ballDiameter * 0.55);
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

class _RoundResultOverlay extends StatelessWidget {
  const _RoundResultOverlay({
    required this.title,
    required this.resultText,
    required this.success,
    required this.onNext,
    required this.nextLabel,
  });

  final String title;
  final String resultText;
  final bool success;
  final VoidCallback onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xE60D0F16),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GameUiText.sectionTitle,
            ),
            const SizedBox(height: 12),
            Text(
              resultText,
              textAlign: TextAlign.center,
              style: GameUiText.bodyStrong.copyWith(
                fontSize: 16,
                color:
                    success ? const Color(0xFF86FFD8) : const Color(0xFFFF8F8F),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4DFFD8),
                foregroundColor: Colors.black,
              ),
              child: Text(nextLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalSummaryOverlay extends StatelessWidget {
  const _FinalSummaryOverlay({
    required this.l10n,
    required this.results,
    required this.champion,
    required this.blindBoxResult,
    required this.playerLabelBuilder,
    required this.resultStatusTextBuilder,
    required this.resultTimeTextBuilder,
    required this.onRestart,
    required this.restartLabel,
  });

  final AppLocalizations l10n;
  final List<GravityBalanceSessionResult> results;
  final GravityBalanceSessionResult? champion;
  final PenaltyBlindBoxResult? blindBoxResult;
  final String Function(int playerIndex) playerLabelBuilder;
  final String Function(bool success) resultStatusTextBuilder;
  final String Function(GravityBalanceSessionResult result)
      resultTimeTextBuilder;
  final VoidCallback onRestart;
  final String restartLabel;

  @override
  Widget build(BuildContext context) {
    final championText = champion == null
        ? l10n.t('gravityBalanceNoChampion')
        : l10n.t('gravityBalanceChampion', {
            'player': playerLabelBuilder(champion!.playerIndex),
            'time': resultTimeTextBuilder(champion!),
          });

    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xE60D0F16),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.t('gravityBalanceSummaryTitle'),
                textAlign: TextAlign.center,
                style: GameUiText.sectionTitle,
              ),
              const SizedBox(height: 12),
              ...results.map((result) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withAlpha(34)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          playerLabelBuilder(result.playerIndex),
                          style: GameUiText.bodyStrong,
                        ),
                      ),
                      Text(
                        resultStatusTextBuilder(result.success),
                        style: TextStyle(
                          color: result.success
                              ? const Color(0xFF86FFD8)
                              : const Color(0xFFFF8F8F),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        resultTimeTextBuilder(result),
                        style: GameUiText.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),
              Text(
                championText,
                textAlign: TextAlign.center,
                style: GameUiText.bodyStrong,
              ),
              if (blindBoxResult != null) ...[
                const SizedBox(height: 14),
                PenaltyBlindBoxOverlay(result: blindBoxResult!),
              ],
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: onRestart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DFFD8),
                  foregroundColor: Colors.black,
                  textStyle: GameUiText.buttonLabel,
                ),
                child: Text(restartLabel),
              ),
            ],
          ),
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
    required this.holeCenter,
    required this.holeRadius,
    required this.exploded,
  });

  final List<Offset> centerline;
  final VerletBallState ballState;
  final double trackWidth;
  final double ballRadius;
  final Offset holeCenter;
  final double holeRadius;
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

    final holeOuterGlow = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x8868FFE3),
          Color(0x2256CFC1),
          Color(0x00000000),
        ],
      ).createShader(
        Rect.fromCircle(center: holeCenter, radius: holeRadius * 1.8),
      );
    canvas.drawCircle(holeCenter, holeRadius * 1.8, holeOuterGlow);

    final holeRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFF9BFFEB);
    canvas.drawCircle(holeCenter, holeRadius, holeRim);

    final holeCore = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF04080A),
          Color(0xFF0A1115),
          Color(0xFF16242B),
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(
        Rect.fromCircle(center: holeCenter, radius: holeRadius),
      );
    canvas.drawCircle(holeCenter, holeRadius - 1, holeCore);

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
        trackWidth != oldDelegate.trackWidth ||
        holeCenter != oldDelegate.holeCenter ||
        holeRadius != oldDelegate.holeRadius;
  }
}
