import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/help/game_help_service.dart';
import '../../core/haptics/haptic_service.dart';
import '../../l10n/app_localizations.dart';
import 'logic/bio_detector_logic.dart';

enum _BioDetectorViewState { idle, running, result }

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

  _BioDetectorViewState _viewState = _BioDetectorViewState.idle;
  Duration _elapsed = Duration.zero;
  int _messageIndex = 0;
  String? _warningKey;
  int _nextPulseMs = 0;
  int _nextWarnMs = 0;
  bool _showHelpButton = false;

  BioDetectorCheatOverride _cheatOverride = BioDetectorCheatOverride.none;
  BioDetectorResult? _result;
  int? _resultConfidencePercent;

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
    if (_viewState == _BioDetectorViewState.running) return;

    _tickTimer?.cancel();
    _warnHideTimer?.cancel();
    _truthPulseController.stop();
    _lieBlinkController.stop();
    _truthPulseController.value = 0;
    _lieBlinkController.value = 0;

    setState(() {
      _viewState = _BioDetectorViewState.running;
      _startedAt = DateTime.now();
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

    _tickTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _tick();
    });
  }

  void _tick() {
    final startedAt = _startedAt;
    if (startedAt == null || !mounted) return;

    final elapsed = DateTime.now().difference(startedAt);
    final phase = flowPhaseForElapsed(elapsed);

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
        _viewState = _BioDetectorViewState.result;
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

  void _reset() {
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
      _cheatOverride = BioDetectorCheatOverride.none;
    });
  }

  void _setCheatOverride(BioDetectorCheatOverride value) {
    setState(() {
      _cheatOverride = value;
    });
  }

  String _statusLine(AppLocalizations l10n) {
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
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
                  const SizedBox(height: 24),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: _buildDetectorZone(phase),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _statusLine(l10n),
                          style: const TextStyle(
                            color: Color(0xFFC6C6C6),
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
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
                              timeSeconds: _elapsed.inMilliseconds / 1000,
                              bpm: _waveBpmForPhase(phase),
                            ),
                            size: Size.infinite,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_viewState == _BioDetectorViewState.result)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _reset,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A1A1A),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(l10n.t('bioDetectorRetry')),
                            ),
                          )
                        else
                          const SizedBox(height: 40),
                      ],
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

  Widget _buildDetectorZone(BioDetectorFlowPhase phase) {
    if (_viewState == _BioDetectorViewState.result && _result != null) {
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
    if (_viewState == _BioDetectorViewState.result &&
        _result == BioDetectorResult.lie) {
      return 108;
    }
    return 72;
  }
}

class _BioGridPainter extends CustomPainter {
  const _BioGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 10.0;
    final paint = Paint()
      ..color = const Color(0x112D2D2D)
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
    required this.timeSeconds,
    required this.bpm,
  });

  final double timeSeconds;
  final double bpm;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final midY = size.height / 2;
    const dx = 2.0;
    const pixelsPerSecond = 130.0;
    final amplitude = size.height * 0.33;
    bool first = true;
    for (double x = 0; x <= size.width; x += dx) {
      final sampleTime = timeSeconds + (x / pixelsPerSecond);
      final wave = _ecgSample(sampleTime, bpm);
      final y = midY - (wave * amplitude);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    final glow = Paint()
      ..color = const Color(0x66FF3B3B)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final line = Paint()
      ..color = const Color(0xFFFF4D4D)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _PulseWavePainter oldDelegate) {
    return oldDelegate.timeSeconds != timeSeconds || oldDelegate.bpm != bpm;
  }

  double _ecgSample(double time, double bpm) {
    final periodSeconds = 60 / max(1, bpm);
    final beatPhase = ((time % periodSeconds) / periodSeconds)
        .clamp(0.0, 1.0)
        .toDouble();

    double gaussian(double x, double center, double width) {
      final z = (x - center) / width;
      return exp(-(z * z) * 0.5);
    }

    final pWave = 0.12 * gaussian(beatPhase, 0.18, 0.038);
    final qWave = -0.20 * gaussian(beatPhase, 0.37, 0.014);
    final rWave = 1.05 * gaussian(beatPhase, 0.40, 0.007);
    final sWave = -0.33 * gaussian(beatPhase, 0.43, 0.013);
    final tWave = 0.28 * gaussian(beatPhase, 0.66, 0.058);
    final noise = (sin(time * 21) * 0.015) + (sin(time * 47) * 0.008);

    return pWave + qWave + rWave + sWave + tWave + noise;
  }
}
