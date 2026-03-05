import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/audio/audio_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sounds.dart';
import '../../core/haptics/haptic_service.dart';
import '../../core/help/game_help_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/game_result_action_bar.dart';
import '../../shared/widgets/game_result_template_card.dart';
import '../../shared/widgets/web3_game_background.dart';
import 'logic/decibel_bomb_logic.dart';
import 'logic/decibel_bomb_permission_logic.dart';

enum _DecibelBombPhase {
  requestingPermission,
  permissionDenied,
  calibrating,
  ready,
  exploded,
}

class DecibelBombScreen extends StatefulWidget {
  const DecibelBombScreen({super.key});

  @override
  State<DecibelBombScreen> createState() => _DecibelBombScreenState();
}

class _DecibelBombScreenState extends State<DecibelBombScreen>
    with TickerProviderStateMixin {
  static const Duration _sampleInterval = Duration(milliseconds: 100);
  static const Duration _calibrationDuration = Duration(seconds: 2);

  final Random _random = Random();
  final NoiseMeter _noiseMeter = NoiseMeter();

  StreamSubscription<NoiseReading>? _noiseSub;
  DateTime? _lastSampleAt;
  Timer? _calibrationTimer;
  Timer? _flashTimer;
  bool _isPermissionRequesting = false;

  late final AnimationController _ringController;
  late final AnimationController _explosionController;

  _DecibelBombPhase _phase = _DecibelBombPhase.requestingPermission;
  bool _showHelpButton = false;
  bool _showFlash = false;

  int _playerCount = 4;
  int _holderIndex = 0;
  bool _isHoldingSpeak = false;
  PermissionStatus? _permissionStatus;

  double _currentDb = 0;
  final List<double> _calibrationSamples = [];

  DecibelBombState _bombState = const DecibelBombState(
    maxEnergy: 1800,
    baselineDb: 42,
  );

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _explosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final delay = defaultTargetPlatform == TargetPlatform.iOS
          ? const Duration(milliseconds: 350)
          : Duration.zero;
      Future<void>.delayed(delay, () {
        if (!mounted) return;
        _requestMicrophonePermissionAndStart();
      });
    });
    _initGameHelp();
  }

  @override
  void dispose() {
    _noiseSub?.cancel();
    _calibrationTimer?.cancel();
    _flashTimer?.cancel();
    _ringController.dispose();
    _explosionController.dispose();
    super.dispose();
  }

  Future<void> _requestMicrophonePermissionAndStart() async {
    if (_isPermissionRequesting) return;
    _isPermissionRequesting = true;
    setState(() => _phase = _DecibelBombPhase.requestingPermission);
    final currentStatus = await Permission.microphone.status;
    if (!mounted) {
      _isPermissionRequesting = false;
      return;
    }
    _permissionStatus = currentStatus;
    var action = resolveMicrophoneAction(currentStatus);

    if (action == MicrophoneAction.requestPermission) {
      final requestedStatus = await Permission.microphone.request();
      if (!mounted) {
        _isPermissionRequesting = false;
        return;
      }
      _permissionStatus = requestedStatus;
      action = resolveMicrophoneAction(requestedStatus);
    }

    switch (action) {
      case MicrophoneAction.startGame:
        _startNoiseStream();
        _startCalibration();
        break;
      case MicrophoneAction.requestPermission:
      case MicrophoneAction.openSettings:
        setState(() => _phase = _DecibelBombPhase.permissionDenied);
        break;
    }
    _isPermissionRequesting = false;
  }

  void _startNoiseStream() {
    _noiseSub?.cancel();
    _noiseSub = _noiseMeter.noise.listen(
      _onNoiseReading,
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _phase = _DecibelBombPhase.permissionDenied;
          _permissionStatus = PermissionStatus.denied;
        });
      },
      cancelOnError: false,
    );
  }

  void _startCalibration() {
    _calibrationTimer?.cancel();
    _calibrationSamples.clear();
    _isHoldingSpeak = false;
    _holderIndex = 0;

    setState(() {
      _phase = _DecibelBombPhase.calibrating;
      _bombState = DecibelBombState(
        maxEnergy: DecibelBombRules.randomCapacity(_random).toDouble(),
        baselineDb: _bombState.baselineDb,
      );
      _explosionController.reset();
    });

    _calibrationTimer = Timer(_calibrationDuration, _finishCalibration);
  }

  void _finishCalibration() {
    if (!mounted || _phase != _DecibelBombPhase.calibrating) return;

    final baseline = _calibrationSamples.isEmpty
        ? max(35, _currentDb).toDouble()
        : _calibrationSamples.reduce((a, b) => a + b) /
            _calibrationSamples.length;

    setState(() {
      _bombState = DecibelBombState(
        maxEnergy: _bombState.maxEnergy,
        baselineDb: baseline,
      );
      _phase = _DecibelBombPhase.ready;
    });
  }

  void _onNoiseReading(NoiseReading reading) {
    final now = DateTime.now();
    final last = _lastSampleAt;
    if (last != null && now.difference(last) < _sampleInterval) {
      return;
    }
    _lastSampleAt = now;

    final db = reading.meanDecibel;
    if (!db.isFinite || db.isNaN) return;

    if (!mounted) return;

    setState(() {
      _currentDb = db;

      if (_phase == _DecibelBombPhase.calibrating) {
        _calibrationSamples.add(db);
        return;
      }

      if (_phase != _DecibelBombPhase.ready) {
        return;
      }

      _bombState = DecibelBombRules.applySample(
        _bombState,
        currentDb: db,
        deltaSeconds: 0.1,
        speaking: _isHoldingSpeak,
      );

      if (_bombState.exploded) {
        _triggerExplosion();
      }
    });
  }

  void _triggerExplosion() {
    if (_phase == _DecibelBombPhase.exploded) return;

    AudioService.play(AppSounds.bombBeep, volume: 1.0);
    AudioService.play(AppSounds.bombExplosion, volume: 1.0);
    HapticService.tripleHeavyImpact();

    _isHoldingSpeak = false;
    _showFlash = true;
    _phase = _DecibelBombPhase.exploded;

    _explosionController
      ..reset()
      ..forward();

    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _showFlash = false);
    });
  }

  void _setHoldingSpeak(bool speaking) {
    if (_phase != _DecibelBombPhase.ready) return;
    setState(() => _isHoldingSpeak = speaking);
  }

  void _nextPlayer() {
    if (_phase != _DecibelBombPhase.ready) return;
    HapticService.selectionClick();
    setState(() {
      _isHoldingSpeak = false;
      _holderIndex = (_holderIndex + 1) % _playerCount;
      _bombState = DecibelBombRules.startHandoffSensitiveWindow(_bombState);
    });
  }

  String _explosionSummary(AppLocalizations l10n) {
    final reason = _bombState.explosionReason;
    if (reason == ExplosionReason.handoffSpike) {
      return l10n.t('decibelBombExplodedByHandoff', {
        'player': l10n.playerLabel(_holderIndex + 1),
      });
    }
    return l10n.t('decibelBombExplodedByEnergy', {
      'player': l10n.playerLabel(_holderIndex + 1),
    });
  }

  String _statusLine(AppLocalizations l10n) {
    switch (_phase) {
      case _DecibelBombPhase.requestingPermission:
        return l10n.t('decibelBombRequestingPermission');
      case _DecibelBombPhase.permissionDenied:
        if (_permissionStatus?.isPermanentlyDenied ?? false) {
          return l10n.t('decibelBombPermissionPermanentlyDenied');
        }
        if (_permissionStatus?.isRestricted ?? false) {
          return l10n.t('decibelBombPermissionRestricted');
        }
        return l10n.t('decibelBombPermissionDenied');
      case _DecibelBombPhase.calibrating:
        return l10n.t('decibelBombCalibrating');
      case _DecibelBombPhase.ready:
        return _isHoldingSpeak
            ? l10n.t('decibelBombSpeaking')
            : l10n.t('decibelBombReadyHint');
      case _DecibelBombPhase.exploded:
        return l10n.t('decibelBombExploded');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deltaDb = max(0, _currentDb - _bombState.baselineDb);
    final loudness = (deltaDb / 40).clamp(0.0, 1.0);
    final energyRatio =
        (_bombState.energy / _bombState.maxEnergy).clamp(0.0, 1.0);
    final shouldOpenSettingsFirst =
        (_permissionStatus?.isPermanentlyDenied ?? false) ||
            (_permissionStatus?.isRestricted ?? false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Web3GameBackground(
            accentColor: AppColors.fingerCyan,
            secondaryColor: AppColors.bombRed,
            overlayOpacity: 0.72,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.t('decibelBomb'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 20),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _statusLine(l10n),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.playersCount(_playerCount),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  Slider(
                    value: _playerCount.toDouble(),
                    min: 3,
                    max: 8,
                    divisions: 5,
                    label: '$_playerCount',
                    activeColor: AppColors.fingerCyan,
                    onChanged: _phase == _DecibelBombPhase.ready
                        ? (v) => setState(() {
                              _playerCount = v.round();
                              _holderIndex = _holderIndex % _playerCount;
                            })
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _ringController,
                          _explosionController,
                        ]),
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size.square(320),
                            painter: _DecibelRingPainter(
                              time: _ringController.value,
                              loudness: loudness,
                              energyRatio: energyRatio,
                              explosion: _explosionController.value,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  _MetricLine(
                    label: l10n.t('decibelBombCurrentDb'),
                    value: '${_currentDb.toStringAsFixed(1)} dB',
                  ),
                  _MetricLine(
                    label: l10n.t('decibelBombBaseline'),
                    value: '${_bombState.baselineDb.toStringAsFixed(1)} dB',
                  ),
                  _MetricLine(
                    label: l10n.t('decibelBombSensitivity'),
                    value: _bombState.sensitivity.toStringAsFixed(1),
                  ),
                  _MetricLine(
                    label: l10n.t('decibelBombEnergy'),
                    value:
                        '${_bombState.energy.toStringAsFixed(0)} / ${_bombState.maxEnergy.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 10),
                  if (_phase == _DecibelBombPhase.exploded)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GameResultTemplateCard(
                        accentColor: AppColors.bombRed,
                        resultTitle: l10n.t('resultSummary'),
                        resultText: _explosionSummary(l10n),
                        penaltyTitle: l10n.t('decibelBombExplosionReason'),
                        penaltyText: _bombState.explosionReason ==
                                ExplosionReason.handoffSpike
                            ? l10n.t('decibelBombHandoffPenalty')
                            : l10n.t('decibelBombLoudPenalty'),
                      ),
                    ),
                  if (_phase == _DecibelBombPhase.exploded)
                    GameResultActionBar(
                      accentColor: AppColors.bombRed,
                      primaryLabel: l10n.t('decibelBombRecalibrate'),
                      onPrimaryTap: _startCalibration,
                    )
                  else if (_phase == _DecibelBombPhase.permissionDenied)
                    GameResultActionBar(
                      accentColor: AppColors.wheelOrange,
                      primaryLabel: shouldOpenSettingsFirst
                          ? l10n.t('decibelBombOpenSettings')
                          : l10n.t('decibelBombGrantPermission'),
                      onPrimaryTap: shouldOpenSettingsFirst
                          ? openAppSettings
                          : _requestMicrophonePermissionAndStart,
                      secondaryLabel: shouldOpenSettingsFirst
                          ? l10n.t('decibelBombGrantPermission')
                          : l10n.t('decibelBombOpenSettings'),
                      onSecondaryTap: shouldOpenSettingsFirst
                          ? _requestMicrophonePermissionAndStart
                          : openAppSettings,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: GestureDetector(
                              onTapDown: (_) => _setHoldingSpeak(true),
                              onTapUp: (_) => _setHoldingSpeak(false),
                              onTapCancel: () => _setHoldingSpeak(false),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: _isHoldingSpeak
                                      ? AppColors.fingerCyan
                                      : AppColors.surfaceVariant,
                                  border: Border.all(
                                    color: _isHoldingSpeak
                                        ? AppColors.fingerCyan
                                        : AppColors.textDim,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    l10n.t('decibelBombSpeakHold'),
                                    style: TextStyle(
                                      color: _isHoldingSpeak
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _phase == _DecibelBombPhase.ready
                                  ? _nextPlayer
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.bombRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(l10n.t('nextPlayer')),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (_showFlash)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: Colors.white),
              ),
            ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 20,
            child: GestureDetector(
              onHorizontalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) > 200) context.pop();
              },
            ),
          ),
          if (_showHelpButton)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: GameHelpButton(
                onTap: _showGameHelp,
                iconColor: AppColors.textSecondary,
                borderColor: AppColors.textDim,
              ),
            ),
        ],
      ),
    );
  }

  void _initGameHelp() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      await GameHelpService.ensureFirstTimeShown(
        context: context,
        gameId: 'decibel_bomb',
        gameTitle: l10n.t('decibelBomb'),
        helpBody: l10n.t('helpDecibelBombBody'),
      );
      if (mounted) setState(() => _showHelpButton = true);
    });
  }

  void _showGameHelp() {
    final l10n = AppLocalizations.of(context);
    GameHelpService.showGameHelpDialog(
      context,
      gameTitle: l10n.t('decibelBomb'),
      helpBody: l10n.t('helpDecibelBombBody'),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecibelRingPainter extends CustomPainter {
  _DecibelRingPainter({
    required this.time,
    required this.loudness,
    required this.energyRatio,
    required this.explosion,
  });

  final double time;
  final double loudness;
  final double energyRatio;
  final double explosion;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.shortestSide * 0.26;

    final ringPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 360; i++) {
      final angle = (i / 360) * pi * 2;

      final wave = sin(angle * 8 + time * pi * 2) * (3 + 8 * loudness);
      final scatter = loudness *
          loudness *
          26 *
          (0.55 + 0.45 * sin(angle * 11 + time * pi * 4).abs());
      final blast = explosion *
          size.shortestSide *
          0.62 *
          (0.6 + 0.4 * sin(angle * 7 + time * pi * 3).abs());

      final radius = baseRadius + wave + scatter + blast;
      final point = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      final colorT = (loudness * 0.78 + explosion * 0.9).clamp(0.0, 1.0);
      ringPaint.color = Color.lerp(
        const Color(0xFF00FFFF),
        const Color(0xFFFF0000),
        colorT,
      )!
          .withAlpha(
              (140 + 110 * (0.2 + loudness + explosion)).clamp(0, 255).toInt());

      canvas.drawCircle(point, 1.4 + 1.5 * loudness + explosion, ringPaint);
    }

    final gaugeBg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = const Color(0x22FFFFFF);
    final gaugeFg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10
      ..color = Color.lerp(
        const Color(0xFF00FFFF),
        const Color(0xFFFF0000),
        energyRatio,
      )!;

    final arcRect = Rect.fromCircle(center: center, radius: baseRadius * 0.78);
    canvas.drawArc(arcRect, -pi / 2, pi * 2, false, gaugeBg);
    canvas.drawArc(arcRect, -pi / 2, pi * 2 * energyRatio, false, gaugeFg);
  }

  @override
  bool shouldRepaint(covariant _DecibelRingPainter oldDelegate) {
    return time != oldDelegate.time ||
        loudness != oldDelegate.loudness ||
        explosion != oldDelegate.explosion ||
        energyRatio != oldDelegate.energyRatio;
  }
}
