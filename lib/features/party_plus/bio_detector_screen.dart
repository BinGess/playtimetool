import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/help/game_help_service.dart';
import '../../core/haptics/haptic_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/services/penalty_service.dart';
import '../../shared/styles/game_ui_style.dart';
import '../../shared/widgets/penalty_blind_box_overlay.dart';
import '../../shared/widgets/penalty_preset_card.dart';
import 'logic/bio_detector_logic.dart';

enum _BioDetectorViewState { setup, idle, running, roundResult, finalResult }

class BioDetectorScreen extends StatefulWidget {
  const BioDetectorScreen({super.key});

  @override
  State<BioDetectorScreen> createState() => _BioDetectorScreenState();
}

class _BioDetectorScreenState extends State<BioDetectorScreen>
    with TickerProviderStateMixin {
  final Random _random = Random();

  late final AnimationController _scanController;
  late final AnimationController _heartbeatBeatController;
  late final AnimationController _heartbeatSweepController;
  late final AnimationController _truthPulseController;
  late final AnimationController _lieBlinkController;

  Timer? _tickTimer;
  Timer? _warnHideTimer;
  DateTime? _startedAt;

  _BioDetectorViewState _viewState = _BioDetectorViewState.setup;
  Duration _elapsed = Duration.zero;
  int _messageIndex = 0;
  String? _warningKey;
  int _nextPulseMs = 0;
  int _nextWarnMs = 0;
  int _heartbeatPeriodMs = 1200;
  bool _showHelpButton = false;
  int _round = 1;
  int _totalRounds = 3;
  final List<BioDetectorResult> _roundResults = [];

  BioDetectorCheatOverride _cheatOverride = BioDetectorCheatOverride.none;
  BioDetectorResult? _result;
  int? _resultConfidencePercent;
  PenaltyPreset _penaltyPreset = PenaltyPreset.defaults;
  PenaltyBlindBoxResult? _blindBoxResult;

  static const List<String> _samplingMessageKeys = [
    'bioDetectorSamplingHint1',
    'bioDetectorSamplingHint2',
  ];
  static const List<String> _warningMessageKeys = [
    'bioDetectorWarnBreath',
    'bioDetectorWarnCortex',
  ];

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _heartbeatBeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _heartbeatSweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _truthPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _lieBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initGameHelp();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _warnHideTimer?.cancel();
    _scanController.dispose();
    _heartbeatBeatController.dispose();
    _heartbeatSweepController.dispose();
    _truthPulseController.dispose();
    _lieBlinkController.dispose();
    super.dispose();
  }

  Future<void> _initGameHelp() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      await GameHelpService.ensureFirstTimeShown(
        context: context,
        gameId: 'bio_detector',
        gameTitle: l10n.t('bioDetector'),
        helpBody: l10n.t('helpBioDetectorBody'),
      );
      if (mounted) {
        setState(() => _showHelpButton = true);
      }
    });
  }

  void _startDetection() {
    if (_viewState != _BioDetectorViewState.idle) return;

    final now = DateTime.now();
    _tickTimer?.cancel();
    _warnHideTimer?.cancel();
    _truthPulseController.stop();
    _lieBlinkController.stop();
    _truthPulseController.value = 0;
    _lieBlinkController.value = 0;

    setState(() {
      _viewState = _BioDetectorViewState.running;
      _startedAt = now;
      _elapsed = Duration.zero;
      _messageIndex = 0;
      _warningKey = null;
      _result = null;
      _resultConfidencePercent = null;
      _nextPulseMs = 0;
      _nextWarnMs = 650 + _random.nextInt(351);
    });
    _syncHeartbeatRhythm(
      force: true,
      phase: BioDetectorFlowPhase.initializing,
      elapsedMs: 0,
    );

    HapticService.lightImpact();
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (mounted && _viewState == _BioDetectorViewState.running) {
        HapticService.mediumImpact();
      }
    });

    _tickTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      _tick();
    });
  }

  void _tick() {
    final startedAt = _startedAt;
    if (startedAt == null || !mounted) return;

    final now = DateTime.now();
    final elapsed = now.difference(startedAt);
    final phase = flowPhaseForElapsed(elapsed);
    final elapsedMs = elapsed.inMilliseconds;

    if (phase == BioDetectorFlowPhase.result) {
      _tickTimer?.cancel();
      _warnHideTimer?.cancel();
      final decisionUnit = _random.nextDouble();
      final result = resolveBioDetectorResult(
        cheatOverride: _cheatOverride,
        randomUnit: decisionUnit,
      );
      final confidencePercent = confidencePercentFromUnit(_random.nextDouble());
      if (result == BioDetectorResult.lie) {
        HapticService.tripleHeavyImpact();
        _lieBlinkController.repeat(reverse: true);
      } else {
        HapticService.lightImpact();
        _truthPulseController.repeat(reverse: true);
      }

      setState(() {
        _elapsed = elapsed;
        _warningKey = null;
        _result = result;
        _resultConfidencePercent = confidencePercent;
        _blindBoxResult = result == BioDetectorResult.lie
            ? PenaltyService.resolveBlindBox(
                l10n: AppLocalizations.of(context),
                random: _random,
                preset: _penaltyPreset,
                losers: <String>[
                  AppLocalizations.of(context).t('penaltyCurrentPlayerLabel'),
                ],
              )
            : null;
        _roundResults.add(result);
        _viewState = _round >= _totalRounds
            ? _BioDetectorViewState.finalResult
            : _BioDetectorViewState.roundResult;
      });
      _syncHeartbeatRhythm(force: true, phase: phase, elapsedMs: elapsedMs);
      return;
    }

    _updateTickerAndWarning(phase, elapsedMs, elapsed);
    _schedulePulseForPhase(phase, elapsedMs);
    _syncHeartbeatRhythm(phase: phase, elapsedMs: elapsedMs);

    setState(() {
      _elapsed = elapsed;
    });
  }

  void _schedulePulseForPhase(BioDetectorFlowPhase phase, int elapsedMs) {
    if (elapsedMs < _nextPulseMs) return;

    if (phase == BioDetectorFlowPhase.sampling) {
      HapticService.lightImpact();
      _nextPulseMs = elapsedMs + 1000;
      return;
    }

    if (phase == BioDetectorFlowPhase.pressure) {
      final pressureElapsed = elapsedMs -
          kBioDetectorInitializingDuration.inMilliseconds -
          kBioDetectorSamplingDuration.inMilliseconds;
      final t = (pressureElapsed / kBioDetectorPressureDuration.inMilliseconds)
          .clamp(0.0, 1.0);
      final intervalMs = (1000 - (500 * t)).round();
      HapticService.mediumImpact();
      _nextPulseMs = elapsedMs + intervalMs;
    }
  }

  void _updateTickerAndWarning(
    BioDetectorFlowPhase phase,
    int elapsedMs,
    Duration elapsed,
  ) {
    final detectionElapsed = elapsed - kBioDetectorInitializingDuration;
    if (!detectionElapsed.isNegative) {
      _messageIndex = (detectionElapsed.inMilliseconds ~/ 1200) %
          _samplingMessageKeys.length;
    }

    if (phase != BioDetectorFlowPhase.pressure) {
      _warningKey = null;
      return;
    }
    if (elapsedMs < _nextWarnMs) return;

    _warningKey =
        _warningMessageKeys[_random.nextInt(_warningMessageKeys.length)];
    _nextWarnMs = elapsedMs + 600 + _random.nextInt(401);
    _warnHideTimer?.cancel();
    _warnHideTimer = Timer(const Duration(milliseconds: 280), () {
      if (!mounted || _viewState != _BioDetectorViewState.running) return;
      setState(() {
        _warningKey = null;
      });
    });
  }

  void _reset() {
    _tickTimer?.cancel();
    _warnHideTimer?.cancel();
    _truthPulseController.stop();
    _lieBlinkController.stop();
    _truthPulseController.value = 0;
    _lieBlinkController.value = 0;
    setState(() {
      _viewState = _BioDetectorViewState.setup;
      _startedAt = null;
      _elapsed = Duration.zero;
      _messageIndex = 0;
      _warningKey = null;
      _result = null;
      _resultConfidencePercent = null;
      _cheatOverride = BioDetectorCheatOverride.none;
      _round = 1;
      _roundResults.clear();
      _blindBoxResult = null;
    });
    _syncHeartbeatRhythm(force: true);
  }

  void _startSession() {
    _tickTimer?.cancel();
    _warnHideTimer?.cancel();
    _truthPulseController.stop();
    _lieBlinkController.stop();
    _truthPulseController.value = 0;
    _lieBlinkController.value = 0;
    setState(() {
      _viewState = _BioDetectorViewState.idle;
      _startedAt = null;
      _elapsed = Duration.zero;
      _messageIndex = 0;
      _warningKey = null;
      _result = null;
      _resultConfidencePercent = null;
      _round = 1;
      _roundResults.clear();
      _cheatOverride = BioDetectorCheatOverride.none;
      _blindBoxResult = null;
    });
    _syncHeartbeatRhythm(force: true);
  }

  void _nextRound() {
    if (_viewState != _BioDetectorViewState.roundResult) return;
    _tickTimer?.cancel();
    _warnHideTimer?.cancel();
    _truthPulseController.stop();
    _lieBlinkController.stop();
    _truthPulseController.value = 0;
    _lieBlinkController.value = 0;
    setState(() {
      _viewState = _BioDetectorViewState.idle;
      _startedAt = null;
      _elapsed = Duration.zero;
      _messageIndex = 0;
      _warningKey = null;
      _result = null;
      _resultConfidencePercent = null;
      _round += 1;
      _blindBoxResult = null;
    });
    _syncHeartbeatRhythm(force: true);
  }

  void _setCheatOverride(BioDetectorCheatOverride value) {
    setState(() {
      _cheatOverride = value;
    });
  }

  String _statusLine(AppLocalizations l10n) {
    if (_viewState == _BioDetectorViewState.setup) {
      return l10n.t('bioDetectorSetupHint');
    }
    if (_viewState == _BioDetectorViewState.roundResult && _result != null) {
      return _result == BioDetectorResult.truth
          ? l10n.t('bioDetectorRoundTruth')
          : l10n.t('bioDetectorRoundLie');
    }
    if (_viewState == _BioDetectorViewState.finalResult) {
      final truthCount =
          _roundResults.where((v) => v == BioDetectorResult.truth).length;
      final lieCount = _roundResults.length - truthCount;
      return l10n.t('bioDetectorFinalSummary', {
        'truth': '$truthCount',
        'lie': '$lieCount',
      });
    }
    final phase = flowPhaseForElapsed(_elapsed);
    if (_viewState == _BioDetectorViewState.idle) {
      return l10n.t('bioDetectorHoldStart');
    }
    if (phase == BioDetectorFlowPhase.initializing) {
      return 'Initializing Bio-Link...';
    }
    return l10n.t(_samplingMessageKeys[_messageIndex]);
  }

  int _heartbeatIntervalForState({
    BioDetectorFlowPhase? phase,
    int elapsedMs = 0,
  }) {
    if (_viewState == _BioDetectorViewState.setup) {
      return 0;
    }

    if (_viewState == _BioDetectorViewState.roundResult ||
        _viewState == _BioDetectorViewState.finalResult) {
      return _result == BioDetectorResult.lie ? 360 : 900;
    }

    if (_viewState == _BioDetectorViewState.idle) {
      return 1180;
    }

    final activePhase = phase ?? flowPhaseForElapsed(_elapsed);
    switch (activePhase) {
      case BioDetectorFlowPhase.initializing:
        return 1120;
      case BioDetectorFlowPhase.sampling:
        return 1000;
      case BioDetectorFlowPhase.pressure:
        final pressureElapsed = elapsedMs -
            kBioDetectorInitializingDuration.inMilliseconds -
            kBioDetectorSamplingDuration.inMilliseconds;
        final t =
            (pressureElapsed / kBioDetectorPressureDuration.inMilliseconds)
                .clamp(0.0, 1.0);
        final baseInterval = (980 - (460 * t)).round();
        if (_warningKey != null) {
          return max(360, baseInterval - 180);
        }
        return baseInterval;
      case BioDetectorFlowPhase.result:
        return _result == BioDetectorResult.lie ? 360 : 900;
    }
  }

  void _syncHeartbeatRhythm({
    bool force = false,
    BioDetectorFlowPhase? phase,
    int elapsedMs = 0,
  }) {
    final rawInterval =
        _heartbeatIntervalForState(phase: phase, elapsedMs: elapsedMs);
    if (rawInterval <= 0) {
      _heartbeatPeriodMs = 0;
      _heartbeatBeatController.stop();
      _heartbeatBeatController.value = 0;
      return;
    }

    final quantized =
        (((rawInterval / 40).round() * 40).clamp(320, 1400)).toInt();
    if (!force &&
        _heartbeatPeriodMs == quantized &&
        _heartbeatBeatController.isAnimating) {
      return;
    }

    _heartbeatPeriodMs = quantized;
    _heartbeatBeatController
      ..stop()
      ..repeat(period: Duration(milliseconds: quantized));
  }

  double get _heartbeatBeatStrength {
    final t = _heartbeatBeatController.value;
    if (t < 0.12) {
      return Curves.easeOutCubic.transform(t / 0.12);
    }
    if (t < 0.26) {
      return 1 - (Curves.easeIn.transform((t - 0.12) / 0.14) * 0.55);
    }
    if (t < 0.42) {
      return 0.45 * (1 - Curves.easeOut.transform((t - 0.26) / 0.16));
    }
    return 0;
  }

  bool _heartbeatAlert(BioDetectorFlowPhase phase) {
    if (_viewState == _BioDetectorViewState.roundResult ||
        _viewState == _BioDetectorViewState.finalResult) {
      return _result == BioDetectorResult.lie;
    }
    if (_warningKey != null) {
      return true;
    }
    return _viewState == _BioDetectorViewState.running &&
        phase == BioDetectorFlowPhase.pressure;
  }

  Widget _buildHeartbeatMonitor(
    BioDetectorFlowPhase phase, {
    bool compact = false,
  }) {
    final animation = Listenable.merge(
      <Listenable>[_heartbeatBeatController, _heartbeatSweepController],
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final beat = _heartbeatBeatStrength;
        final alert = _heartbeatAlert(phase);
        final accentColor = _result == BioDetectorResult.truth
            ? const Color(0xFF5DFFB0)
            : alert
                ? const Color(0xFFFF6565)
                : const Color(0xFFFF9B72);
        final secondaryColor =
            alert ? const Color(0xFFFFC1C1) : const Color(0xFFFFD7C4);
        final iconScale = 1 + (beat * (alert ? 0.22 : 0.16));
        final bpm =
            _heartbeatPeriodMs <= 0 ? 0 : (60000 / _heartbeatPeriodMs).round();
        final statusLabel = alert
            ? 'ANOMALY SPIKE'
            : phase == BioDetectorFlowPhase.pressure
                ? 'SYNC LOCK'
                : phase == BioDetectorFlowPhase.initializing
                    ? 'PRIMING'
                    : _viewState == _BioDetectorViewState.idle
                        ? 'STANDBY'
                        : 'TRACKING';

        return Container(
          key: const Key('bio-detector-heartbeat-monitor'),
          width: compact ? double.infinity : 290,
          constraints: BoxConstraints(maxWidth: compact ? 428 : 290),
          height: compact ? 88 : 94,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accentColor.withAlpha(alert ? 170 : 110),
              width: 1.2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF110A0A),
                alert ? const Color(0xFF180A0E) : const Color(0xFF120C0C),
                const Color(0xFF090909),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withAlpha((36 + (beat * 50)).round()),
                blurRadius: 24 + (beat * 8),
                spreadRadius: beat * 1.2,
              ),
            ],
          ),
          child: Row(
            children: [
              Transform.scale(
                scale: iconScale,
                child: Icon(
                  Icons.favorite_rounded,
                  color: accentColor,
                  size: compact ? 28 : 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomPaint(
                  painter: _HeartbeatTracePainter(
                    sweep: _heartbeatSweepController.value,
                    beat: beat,
                    alert: alert,
                    lineColor: accentColor,
                    glowColor: secondaryColor,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    bpm == 0 ? '-- BPM' : '$bpm BPM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 14 : 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phase = flowPhaseForElapsed(_elapsed);
    final inSetup = _viewState == _BioDetectorViewState.setup;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          const CustomPaint(
            painter: _BioGridPainter(),
            size: Size.infinite,
          ),
          Positioned(
            top: 0,
            left: 0,
            child: GestureDetector(
              key: const Key('bio-detector-force-truth'),
              behavior: HitTestBehavior.translucent,
              onTap: () =>
                  _setCheatOverride(BioDetectorCheatOverride.forceTruth),
              child: const SizedBox(width: 44, height: 44),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              key: const Key('bio-detector-force-lie'),
              behavior: HitTestBehavior.translucent,
              onTap: () => _setCheatOverride(BioDetectorCheatOverride.forceLie),
              child: const SizedBox(width: 44, height: 44),
            ),
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
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          l10n.t('bioDetector'),
                          textAlign: TextAlign.center,
                          style: GameUiText.navTitle,
                        ),
                      ),
                      _showHelpButton
                          ? GameHelpButton(
                              onTap: () => GameHelpService.showGameHelpDialog(
                                context,
                                gameTitle: l10n.t('bioDetector'),
                                helpBody: l10n.t('helpBioDetectorBody'),
                              ),
                            )
                          : const SizedBox(width: 32, height: 32),
                    ],
                  ),
                  const SizedBox(height: GameUiSpacing.sectionGap),
                  Expanded(
                    child: inSetup
                        ? _buildSetupView(l10n)
                        : _buildRoundView(l10n, phase),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectorZone(BioDetectorFlowPhase phase) {
    if ((_viewState == _BioDetectorViewState.roundResult ||
            _viewState == _BioDetectorViewState.finalResult) &&
        _result != null) {
      return _buildResultZone(_result!);
    }

    return GestureDetector(
      key: const Key('bio-detector-fingerprint'),
      onLongPress: _startDetection,
      child: Container(
        width: 290,
        height: 290,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0x3388FFFF), width: 1.4),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x221A3A3A),
              Color(0x113A1A1A),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final lineY = _scanController.value * (constraints.maxHeight - 8);
              return Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 156,
                      color: Color(0x88A6FFFF),
                    ),
                  ),
                  if (_viewState == _BioDetectorViewState.running &&
                      phase != BioDetectorFlowPhase.result)
                    Positioned(
                      top: lineY,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 8,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              Color(0x66CCFFFF),
                              Color(0x44CCFFFF),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResultZone(BioDetectorResult result) {
    if (result == BioDetectorResult.truth) {
      return AnimatedBuilder(
        animation: _truthPulseController,
        builder: (context, _) {
          final t = _truthPulseController.value;
          final ringScale = 1 + (0.06 * t);
          return Transform.scale(
            scale: ringScale,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF33D17A), width: 7),
              ),
              child: Center(
                child: Text(
                  'TRUTH: ${_resultConfidencePercent ?? 98}%',
                  style: const TextStyle(
                    color: Color(0xFF6BFFB1),
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _lieBlinkController,
      builder: (context, _) {
        final alpha = (180 + (_lieBlinkController.value * 75)).round();
        return Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Color.fromARGB(alpha, 255, 84, 84),
              width: 3,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.priority_high_rounded,
                  color: Color(0xFFFF5454), size: 120),
              const SizedBox(height: 8),
              const Text(
                'LIE DETECTED',
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_resultConfidencePercent ?? 98}% CONFIDENCE',
                style: const TextStyle(
                  color: Color(0xFFFFA4A4),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetupView(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSetupHeroCard(l10n),
                const SizedBox(height: 14),
                _buildSetupSectionCard(
                  title: l10n.t('bioDetectorSetupTitle'),
                  subtitle: l10n.t('bioDetectorPrepRoundsHint'),
                  trailing: _buildSetupStatusChip(
                    l10n.t('bioDetectorRoundsSetting', {
                      'count': '$_totalRounds',
                    }),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          inactiveTrackColor: Colors.white12,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
                        ),
                        child: Slider(
                          key: const Key('bio-detector-rounds-slider'),
                          value: _totalRounds.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          activeColor: const Color(0xFFFF6B6B),
                          onChanged: (v) =>
                              setState(() => _totalRounds = v.round()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PenaltyPresetCard(
                  preset: _penaltyPreset,
                  accentColor: const Color(0xFFFF5454),
                  onChanged: (preset) {
                    setState(() => _penaltyPreset = preset);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: GameUiSpacing.buttonHeight,
          child: ElevatedButton(
            key: const Key('bio-detector-start-session'),
            onPressed: _startSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D4D),
              foregroundColor: Colors.white,
              textStyle: GameUiText.buttonLabel,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(l10n.startGame),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSetupHeroCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x4DFF5A5A)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0D0D),
            Color(0xFF110909),
            Color(0xFF090909),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 26,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.t('bioDetectorPrepEyebrow'),
                style: const TextStyle(
                  color: Color(0xFFFF8D8D),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              _buildSetupStatusChip(l10n.t('bioDetectorPrepStandby')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t('bioDetectorPrepHeroBody'),
            style: GameUiText.body.copyWith(
              color: const Color(0xFFD6B8B8),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 168,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x33FFFFFF)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x1FFF6B6B),
                  Color(0x120C0C0C),
                ],
              ),
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(
                    painter: _BioGridPainter(lineColor: Color(0x14FF7A7A)),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 96,
                    color: Color(0x88FF9A9A),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  top: 68,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0x44FFB0B0),
                          Color(0x99FF5F5F),
                          Color(0x44FFB0B0),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: _buildHeroBadge(l10n.t('bioDetectorPrepSignalTag')),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: _buildHeroBadge(
                    l10n.t(
                        'bioDetectorRoundsSetting', {'count': '$_totalRounds'}),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildPrepMetricChip(
                title: l10n.t('bioDetectorPrepMetricDuration'),
                value: l10n.t('bioDetectorPrepMetricDurationValue'),
              ),
              _buildPrepMetricChip(
                title: l10n.t('bioDetectorPrepMetricTrigger'),
                value: l10n.t('bioDetectorPrepMetricTriggerValue'),
              ),
              _buildPrepMetricChip(
                title: l10n.t('bioDetectorPrepMetricPenalty'),
                value: l10n.t('bioDetectorPrepMetricPenaltyValue'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetupSectionCard({
    required String title,
    required Widget child,
    String? subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(132),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x33FF6B6B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GameUiText.sectionTitle),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(subtitle, style: GameUiText.body),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildSetupStatusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x22FF6B6B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x44FF8F8F)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFFC1C1),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildHeroBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xBB120C0C),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x40FF7575)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFFBABA),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildPrepMetricChip({
    required String title,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xAA120D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x28FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFB79696),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundView(AppLocalizations l10n, BioDetectorFlowPhase phase) {
    final isResultView = _viewState == _BioDetectorViewState.roundResult ||
        _viewState == _BioDetectorViewState.finalResult;
    if (isResultView && _result != null) {
      return _buildResultView(l10n, _result!);
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetectorZone(phase),
                  const SizedBox(height: 18),
                  _buildHeartbeatMonitor(phase),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.roundProgress(_round, _totalRounds),
          style: GameUiText.body.copyWith(letterSpacing: 0.3),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          _statusLine(l10n),
          style: GameUiText.body.copyWith(color: const Color(0xFFC6C6C6)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 24,
          child: _warningKey == null
              ? const SizedBox.shrink()
              : Text(
                  l10n.t(_warningKey!),
                  key: const Key('bio-detector-warning'),
                  style: const TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
        ),
        const SizedBox(height: 14),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildResultView(AppLocalizations l10n, BioDetectorResult result) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 720;
        final sectionGap = compact ? 14.0 : 18.0;

        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: compact ? 8 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: _buildResultHero(l10n, result, compact: compact),
              ),
              SizedBox(height: compact ? 14 : 18),
              if (_blindBoxResult != null) ...[
                PenaltyBlindBoxOverlay(result: _blindBoxResult!),
                SizedBox(height: sectionGap),
              ],
              _buildResultActionButton(l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultHero(
    AppLocalizations l10n,
    BioDetectorResult result, {
    required bool compact,
  }) {
    final confidence = _resultConfidencePercent ?? 98;
    final isTruth = result == BioDetectorResult.truth;
    final accentColor =
        isTruth ? const Color(0xFF35D07F) : const Color(0xFFFF6666);
    final bgColor = isTruth ? const Color(0xAA0A1711) : const Color(0xAA170A0C);
    final icon = isTruth ? Icons.verified_rounded : Icons.priority_high_rounded;

    return Container(
      constraints: const BoxConstraints(maxWidth: 428),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 22 : 28,
        vertical: compact ? 22 : 28,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accentColor.withAlpha(130), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 80 : 92,
            height: compact ? 80 : 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withAlpha(28),
              border: Border.all(color: accentColor.withAlpha(140), width: 1.2),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: compact ? 46 : 54,
            ),
          ),
          SizedBox(height: compact ? 16 : 18),
          Text(
            '$confidence%',
            maxLines: 1,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 38 : 46,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isTruth
                ? l10n.t('bioDetectorResultConfidence')
                : l10n.t('bioDetectorResultRisk'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accentColor.withAlpha(220),
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              height: 1.3,
            ),
          ),
          SizedBox(height: compact ? 10 : 12),
          Text(
            isTruth
                ? l10n.t('bioDetectorResultTruthBody')
                : l10n.t('bioDetectorResultLieBody'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFD8D8D8),
              fontSize: compact ? 14 : 15,
              height: 1.5,
            ),
          ),
          SizedBox(height: compact ? 16 : 18),
          _buildHeartbeatMonitor(
            BioDetectorFlowPhase.result,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildResultActionButton(AppLocalizations l10n) {
    final isFinal = _viewState == _BioDetectorViewState.finalResult;
    const actionRed = Color(0xFFD94A57);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isFinal ? _reset : _nextRound,
        style: ElevatedButton.styleFrom(
          backgroundColor: actionRed,
          foregroundColor: Colors.white,
          shadowColor: actionRed.withAlpha(110),
          elevation: 0,
          minimumSize: const Size.fromHeight(GameUiSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.white.withAlpha(28)),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(isFinal ? l10n.againRound : l10n.t('nextRound')),
      ),
    );
  }
}

class _BioGridPainter extends CustomPainter {
  const _BioGridPainter({this.lineColor = const Color(0x112D2D2D)});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 10.0;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeartbeatTracePainter extends CustomPainter {
  const _HeartbeatTracePainter({
    required this.sweep,
    required this.beat,
    required this.alert,
    required this.lineColor,
    required this.glowColor,
  });

  final double sweep;
  final double beat;
  final bool alert;
  final Color lineColor;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x18FFFFFF)
      ..strokeWidth = 1;
    const gridSpacing = 14.0;
    for (double x = 0; x <= size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final baseline = size.height * 0.58;
    final amplitude = size.height * (0.18 + (beat * 0.26));
    final segmentWidth = alert ? 84.0 : 96.0;
    final startOffset = -(segmentWidth * (1.2 + sweep));
    final tracePath = Path()..moveTo(0, baseline);

    for (double start = startOffset;
        start <= size.width + segmentWidth;
        start += segmentWidth) {
      tracePath.lineTo(
        start + (segmentWidth * 0.16),
        baseline,
      );
      tracePath.lineTo(
        start + (segmentWidth * 0.28),
        baseline - (amplitude * 0.18),
      );
      tracePath.lineTo(
        start + (segmentWidth * 0.38),
        baseline + (amplitude * 0.12),
      );
      tracePath.lineTo(
        start + (segmentWidth * 0.48),
        baseline - amplitude,
      );
      tracePath.lineTo(
        start + (segmentWidth * 0.58),
        baseline + (amplitude * 0.72),
      );
      tracePath.lineTo(
        start + (segmentWidth * 0.70),
        baseline,
      );
      tracePath.lineTo(start + segmentWidth, baseline);
    }

    final glowPaint = Paint()
      ..color = glowColor.withAlpha(alert ? 150 : 110)
      ..style = PaintingStyle.stroke
      ..strokeWidth = alert ? 4.4 : 3.8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(tracePath, glowPaint);
    canvas.drawPath(tracePath, linePaint);

    final sweepX = size.width * (0.16 + (0.68 * sweep));
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          glowColor.withAlpha(0),
          glowColor.withAlpha(alert ? 95 : 70),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(sweepX - 26, 0, 52, size.height));
    canvas.drawRect(
      Rect.fromLTWH(sweepX - 26, 0, 52, size.height),
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HeartbeatTracePainter oldDelegate) {
    return oldDelegate.sweep != sweep ||
        oldDelegate.beat != beat ||
        oldDelegate.alert != alert ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.glowColor != glowColor;
  }
}
