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
  late final AnimationController _truthPulseController;
  late final AnimationController _lieBlinkController;

  Timer? _tickTimer;
  Timer? _warnHideTimer;
  DateTime? _startedAt;
  DateTime? _lastWaveTickAt;
  double _heartbeatTurns = 0;

  _BioDetectorViewState _viewState = _BioDetectorViewState.setup;
  Duration _elapsed = Duration.zero;
  int _messageIndex = 0;
  String? _warningKey;
  int _nextPulseMs = 0;
  int _nextWarnMs = 0;
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
      _lastWaveTickAt = now;
      _heartbeatTurns = 0;
      _elapsed = Duration.zero;
      _messageIndex = 0;
      _warningKey = null;
      _result = null;
      _resultConfidencePercent = null;
      _nextPulseMs = 0;
      _nextWarnMs = 650 + _random.nextInt(351);
    });

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
    _advanceHeartbeatClock(now, phase);

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
      return;
    }

    final elapsedMs = elapsed.inMilliseconds;
    _schedulePulseForPhase(phase, elapsedMs);
    _updateTickerAndWarning(phase, elapsedMs, elapsed);

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
      final detectionElapsed =
          elapsedMs - kBioDetectorInitializingDuration.inMilliseconds;
      final pressureElapsed = max(
        0,
        detectionElapsed - kBioDetectorSamplingDuration.inMilliseconds,
      );
      final pressureTotal = kBioDetectorPressureDuration.inMilliseconds;
      final t = (pressureElapsed / pressureTotal).clamp(0.0, 1.0);
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

  void _advanceHeartbeatClock(DateTime now, BioDetectorFlowPhase phase) {
    final lastTickAt = _lastWaveTickAt;
    _lastWaveTickAt = now;
    if (lastTickAt == null) return;
    final dtSeconds = now.difference(lastTickAt).inMicroseconds / 1000000.0;
    if (dtSeconds <= 0) return;
    final bpm = _waveBpmForPhase(phase);
    _heartbeatTurns += dtSeconds * (bpm / 60.0);
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
      _lastWaveTickAt = null;
      _heartbeatTurns = 0;
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
      _lastWaveTickAt = null;
      _heartbeatTurns = 0;
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
      _lastWaveTickAt = null;
      _heartbeatTurns = 0;
      _elapsed = Duration.zero;
      _messageIndex = 0;
      _warningKey = null;
      _result = null;
      _resultConfidencePercent = null;
      _round += 1;
      _blindBoxResult = null;
    });
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

  double _waveBpmForPhase(BioDetectorFlowPhase phase) {
    if (phase == BioDetectorFlowPhase.pressure) {
      final elapsedMs = _elapsed.inMilliseconds;
      final detectionElapsed =
          elapsedMs - kBioDetectorInitializingDuration.inMilliseconds;
      final pressureElapsed = max(
        0,
        detectionElapsed - kBioDetectorSamplingDuration.inMilliseconds,
      );
      final pressureTotal = kBioDetectorPressureDuration.inMilliseconds;
      final t = (pressureElapsed / pressureTotal).clamp(0.0, 1.0);
      return 60 + (60 * t);
    }
    if (phase == BioDetectorFlowPhase.sampling) {
      return 60;
    }
    if ((_viewState == _BioDetectorViewState.roundResult ||
            _viewState == _BioDetectorViewState.finalResult) &&
        _result == BioDetectorResult.lie) {
      return 108;
    }
    return 72;
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
                      Row(
                        children: [
                          Container(
                            width: 88,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0x4DFF6B6B),
                              ),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0x33FF5B5B),
                                  Color(0x14110B0B),
                                ],
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$_totalRounds',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.t('bioDetectorPrepRoundsUnit'),
                                  style: const TextStyle(
                                    color: Color(0xFFFFB0B0),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t('bioDetectorPrepRoundsLabel'),
                                  style: GameUiText.bodyStrong,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.t('bioDetectorSetupHint'),
                                  style: GameUiText.body,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
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
                _buildSetupSectionCard(
                  title: l10n.t('bioDetectorPrepPenaltyTitle'),
                  subtitle: l10n.t('bioDetectorPrepPenaltyHint'),
                  child: PenaltyPresetCard(
                    preset: _penaltyPreset,
                    accentColor: const Color(0xFFFF5454),
                    onChanged: (preset) {
                      setState(() => _penaltyPreset = preset);
                    },
                  ),
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
          const SizedBox(height: 12),
          Text(
            l10n.t('bioDetectorPrepHeroTitle'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
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
                    l10n.t('bioDetectorRoundsSetting', {'count': '$_totalRounds'}),
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
    return Column(
      children: [
        Expanded(
          child: Center(
            child: _buildDetectorZone(phase),
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
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(120),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33FF5252)),
          ),
          child: CustomPaint(
            painter: _PulseWavePainter(
              runtimeSeconds: _elapsed.inMilliseconds / 1000,
              heartbeatTurns: _heartbeatTurns,
              bpm: _waveBpmForPhase(phase),
            ),
            size: Size.infinite,
          ),
        ),
        if (_blindBoxResult != null) ...[
          const SizedBox(height: 14),
          PenaltyBlindBoxOverlay(result: _blindBoxResult!),
        ],
        const SizedBox(height: 14),
        if (_viewState == _BioDetectorViewState.roundResult)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextRound,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.t('nextRound')),
            ),
          )
        else if (_viewState == _BioDetectorViewState.finalResult)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.againRound),
            ),
          )
        else
          const SizedBox(height: 40),
      ],
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

class _PulseWavePainter extends CustomPainter {
  _PulseWavePainter({
    required this.runtimeSeconds,
    required this.heartbeatTurns,
    required this.bpm,
  });

  final double runtimeSeconds;
  final double heartbeatTurns;
  final double bpm;

  @override
  void paint(Canvas canvas, Size size) {
    final beatSpeed = bpm / 60.0;
    final midY = size.height * 0.56;
    final amplitude = size.height * 0.26;
    const dx = 1.4;
    const pixelsPerSecond = 145.0;
    final path = Path();

    final baseline = Paint()
      ..color = const Color(0x22FF6B6B)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset.zero.translate(0, midY), Offset(size.width, midY), baseline);

    bool first = true;
    for (double x = 0; x <= size.width; x += dx) {
      final ageSeconds = (size.width - x) / pixelsPerSecond;
      final sampleTurns = heartbeatTurns - (ageSeconds * beatSpeed);
      final beatPhase = _fractional(sampleTurns);
      final sampleTime = runtimeSeconds - ageSeconds;
      final wave = _ecgSample(beatPhase, sampleTime);
      final y = midY - (wave * amplitude);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    final glow = Paint()
      ..color = const Color(0x44FF3B3B)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5);
    final line = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0x44FF4D4D),
          Color(0xAAFF5E5E),
          Color(0xFFFF7777),
        ],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);

    final currentPhase = _fractional(heartbeatTurns);
    final headWave = _ecgSample(currentPhase, runtimeSeconds);
    final headY = midY - (headWave * amplitude);
    final headGlow = Paint()
      ..color = const Color(0x88FF8A8A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final headDot = Paint()..color = const Color(0xFFFF9A9A);
    canvas.drawCircle(Offset(size.width, headY), 4.8, headGlow);
    canvas.drawCircle(Offset(size.width, headY), 2.5, headDot);
  }

  @override
  bool shouldRepaint(covariant _PulseWavePainter oldDelegate) {
    return oldDelegate.runtimeSeconds != runtimeSeconds ||
        oldDelegate.heartbeatTurns != heartbeatTurns ||
        oldDelegate.bpm != bpm;
  }

  double _fractional(double value) {
    return value - value.floorToDouble();
  }

  double _ecgSample(double beatPhase, double timeSeconds) {
    double gaussian(double x, double center, double width) {
      final z = (x - center) / width;
      return exp(-(z * z) * 0.5);
    }

    double smoothStep(double x) => 1 / (1 + exp(-x));
    double plateau(double x, double start, double end, double softness) {
      return smoothStep((x - start) / softness) -
          smoothStep((x - end) / softness);
    }

    final rScale = 1 + (0.06 * sin(2 * pi * 0.08 * timeSeconds));
    final pWave = 0.11 * gaussian(beatPhase, 0.18, 0.028);
    final qWave = -0.14 * gaussian(beatPhase, 0.357, 0.009);
    final rWave = 1.08 * rScale * gaussian(beatPhase, 0.382, 0.0055);
    final sWave = -0.28 * gaussian(beatPhase, 0.404, 0.01);
    final stWave = 0.018 * plateau(beatPhase, 0.44, 0.56, 0.012);
    final tWave = 0.30 * gaussian(beatPhase, 0.64, 0.065);
    final uWave = 0.035 * gaussian(beatPhase, 0.79, 0.03);
    final baselineWander = 0.018 * sin(2 * pi * 0.28 * timeSeconds);
    final microNoise = (0.004 * sin(2 * pi * 29 * timeSeconds)) +
        (0.0025 * sin((2 * pi * 53 * timeSeconds) + 1.1));

    return pWave +
        qWave +
        rWave +
        sWave +
        stWave +
        tWave +
        uWave +
        baselineWander +
        microNoise;
  }
}
