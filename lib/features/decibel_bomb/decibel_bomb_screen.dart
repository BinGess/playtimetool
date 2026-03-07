import 'dart:async';
import 'dart:math';

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
import '../../shared/services/penalty_service.dart';
import '../../shared/styles/game_ui_style.dart';
import '../../shared/widgets/game_result_action_bar.dart';
import '../../shared/widgets/game_result_template_card.dart';
import '../../shared/widgets/game_top_bar.dart';
import '../../shared/widgets/penalty_blind_box_overlay.dart';
import '../../shared/widgets/penalty_preset_card.dart';
import '../../shared/widgets/web3_game_background.dart';
import 'logic/decibel_bomb_logic.dart';
import 'logic/decibel_bomb_permission_logic.dart';

enum _DecibelBombPhase {
  setup,
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
  static const Duration _holdHapticInterval = Duration(milliseconds: 420);

  final Random _random = Random();
  final NoiseMeter _noiseMeter = NoiseMeter();

  StreamSubscription<NoiseReading>? _noiseSub;
  DateTime? _lastSampleAt;
  Timer? _calibrationTimer;
  Timer? _flashTimer;
  Timer? _holdHapticTimer;
  bool _isPermissionRequesting = false;

  late final AnimationController _ringController;
  late final AnimationController _explosionController;
  late final AnimationController _holdPulseController;

  _DecibelBombPhase _phase = _DecibelBombPhase.setup;
  bool _showHelpButton = false;
  bool _showFlash = false;

  int _playerCount = 4;
  int _holderIndex = 0;
  bool _isHoldingSpeak = false;
  bool _awaitingNextPlayer = false;
  PermissionStatus? _permissionStatus;
  PenaltyPreset _penaltyPreset = PenaltyPreset.defaults;
  PenaltyBlindBoxResult? _blindBoxResult;

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
    _holdPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _initGameHelp();
  }

  @override
  void dispose() {
    _stopHoldFeedback();
    _stopNoiseTracking();
    _ringController.dispose();
    _explosionController.dispose();
    _holdPulseController.dispose();
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
    _stopHoldFeedback();
    _isHoldingSpeak = false;
    _holderIndex = 0;

    setState(() {
      _phase = _DecibelBombPhase.calibrating;
      _bombState = DecibelBombState(
        maxEnergy: DecibelBombRules.randomCapacity(_random).toDouble(),
        baselineDb: _bombState.baselineDb,
      );
      _explosionController.reset();
      _blindBoxResult = null;
      _showFlash = false;
      _awaitingNextPlayer = false;
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

    _stopHoldFeedback();
    _isHoldingSpeak = false;
    _awaitingNextPlayer = false;
    _showFlash = true;
    _phase = _DecibelBombPhase.exploded;
    _blindBoxResult = PenaltyService.resolveBlindBox(
      l10n: AppLocalizations.of(context),
      random: _random,
      preset: _penaltyPreset,
      losers: <String>[
        AppLocalizations.of(context).playerLabel(_holderIndex + 1)
      ],
    );

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
    if (speaking) {
      if (_isHoldingSpeak) return;
      HapticService.mediumImpact();
      _startHoldFeedback();
      setState(() {
        _isHoldingSpeak = true;
      });
      return;
    }
    if (!_isHoldingSpeak) return;
    _stopHoldFeedback();
    setState(() {
      _isHoldingSpeak = false;
      _awaitingNextPlayer = true;
    });
  }

  void _nextPlayer() {
    if (_phase != _DecibelBombPhase.ready) return;
    _stopHoldFeedback();
    HapticService.selectionClick();
    setState(() {
      _isHoldingSpeak = false;
      _awaitingNextPlayer = false;
      _holderIndex = (_holderIndex + 1) % _playerCount;
      _bombState = DecibelBombRules.startHandoffSensitiveWindow(_bombState);
    });
  }

  void _stopNoiseTracking() {
    _stopHoldFeedback();
    _noiseSub?.cancel();
    _noiseSub = null;
    _calibrationTimer?.cancel();
    _flashTimer?.cancel();
    _lastSampleAt = null;
  }

  void _startHoldFeedback() {
    _holdPulseController.repeat(reverse: true);
    _holdHapticTimer?.cancel();
    _holdHapticTimer = Timer.periodic(_holdHapticInterval, (_) {
      if (!mounted || !_isHoldingSpeak || _phase != _DecibelBombPhase.ready) {
        return;
      }
      HapticService.lightImpact();
    });
  }

  void _stopHoldFeedback() {
    _holdHapticTimer?.cancel();
    _holdHapticTimer = null;
    if (_holdPulseController.isAnimating || _holdPulseController.value != 0) {
      _holdPulseController
        ..stop()
        ..reset();
    }
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
      case _DecibelBombPhase.setup:
        return l10n.t('decibelBombPrepHint');
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
            child: _phase == _DecibelBombPhase.setup
                ? _buildSetupView(l10n)
                : _buildGameView(
                    l10n,
                    loudness: loudness,
                    energyRatio: energyRatio,
                    shouldOpenSettingsFirst: shouldOpenSettingsFirst,
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

  Widget _buildSetupView(AppLocalizations l10n) {
    return Padding(
      padding: GameUiSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameTopBar(
            title: l10n.t('decibelBomb'),
            onBack: () => context.pop(),
            accentColor: AppColors.fingerCyan,
          ),
          const SizedBox(height: GameUiSpacing.blockGap),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroCard(l10n),
                  const SizedBox(height: 14),
                  _buildSetupSectionCard(
                    title: l10n.t('decibelBombPrepPlayersTitle'),
                    subtitle: l10n.t('decibelBombPrepPlayersHint'),
                    trailing: _buildSetupStatusChip(
                      l10n.playersCount(_playerCount),
                    ),
                    child: SliderTheme(
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
                        key: const Key('decibel-bomb-player-slider'),
                        value: _playerCount.toDouble(),
                        min: 3,
                        max: 8,
                        divisions: 5,
                        activeColor: AppColors.fingerCyan,
                        onChanged: (value) =>
                            setState(() => _playerCount = value.round()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PenaltyPresetCard(
                    preset: _penaltyPreset,
                    accentColor: AppColors.fingerCyan,
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
            child: ElevatedButton.icon(
              key: const Key('decibel-bomb-start-button'),
              onPressed: _requestMicrophonePermissionAndStart,
              style: GameUiSurface.primaryButton(AppColors.fingerCyan),
              icon: const Icon(Icons.mic_rounded),
              label: Text(
                l10n.startGame,
                style: GameUiText.buttonLabel.copyWith(
                  color: GameUiSurface.foregroundOn(AppColors.fingerCyan),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildGameView(
    AppLocalizations l10n, {
    required double loudness,
    required double energyRatio,
    required bool shouldOpenSettingsFirst,
  }) {
    return Padding(
      padding: GameUiSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameTopBar(
            title: l10n.t('decibelBomb'),
            onBack: () => context.pop(),
            accentColor: AppColors.fingerCyan,
          ),
          const SizedBox(height: GameUiSpacing.blockGap),
          Text(
            _statusLine(l10n),
            textAlign: TextAlign.center,
            style: GameUiText.body.copyWith(letterSpacing: 0.6),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSetupStatusChip(l10n.playersCount(_playerCount)),
              _buildSetupStatusChip(
                l10n.t('decibelBombCurrentPlayer', {
                  'player': l10n.playerLabel(_holderIndex + 1),
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                penaltyTitle: l10n.punishment,
                penaltyText: l10n.t('penaltyBlindBoxTitle'),
              ),
            ),
          if (_phase == _DecibelBombPhase.exploded && _blindBoxResult != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: PenaltyBlindBoxOverlay(result: _blindBoxResult!),
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
            SizedBox(
              height: 56,
              width: double.infinity,
              child: _awaitingNextPlayer
                  ? ElevatedButton(
                      key: const Key('decibel-bomb-next-button'),
                      onPressed: _nextPlayer,
                      style: GameUiSurface.primaryButton(AppColors.bombRed),
                      child: Text(l10n.t('nextPlayer')),
                    )
                  : _DecibelHoldButton(
                      key: const Key('decibel-bomb-scream-button'),
                      label: l10n.t('decibelBombSpeakHold'),
                      isHolding: _isHoldingSpeak,
                      pulseAnimation: _holdPulseController,
                      onHoldStart: () => _setHoldingSpeak(true),
                      onHoldEnd: () => _setHoldingSpeak(false),
                    ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeroCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: GameUiSurface.heroPanel(
        accentColor: AppColors.fingerCyan,
        secondaryColor: AppColors.wheelOrange,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.t('decibelBombSub'),
                style: const TextStyle(
                  color: Color(0xFF8CF4FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              _buildSetupStatusChip(l10n.playersCount(_playerCount)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.t('decibelBombPrepGuideHint'),
            style: GameUiText.body.copyWith(
              color: const Color(0xFFD0E3E8),
            ),
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
      decoration: GameUiSurface.panel(accentColor: AppColors.fingerCyan),
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
        color: AppColors.fingerCyan.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.fingerCyan.withAlpha(70)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFBEFBF9),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
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
            style: GameUiText.body,
          ),
          const Spacer(),
          Text(
            value,
            style: GameUiText.bodyStrong,
          ),
        ],
      ),
    );
  }
}

class _DecibelHoldButton extends StatelessWidget {
  const _DecibelHoldButton({
    super.key,
    required this.label,
    required this.isHolding,
    required this.pulseAnimation,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  final String label;
  final bool isHolding;
  final Animation<double> pulseAnimation;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFFF6D3A);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onHoldStart(),
      onTapUp: (_) => onHoldEnd(),
      onTapCancel: onHoldEnd,
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, _) {
          final pulse = isHolding ? pulseAnimation.value : 0.0;
          final glowScale = 1 + pulse * 0.16;
          final outerOpacity = isHolding ? 0.42 + pulse * 0.28 : 0.18;
          final innerOpacity = isHolding ? 0.34 + pulse * 0.22 : 0.12;
          final buttonScale = isHolding ? 0.985 + pulse * 0.025 : 1.0;
          final borderColor =
              isHolding ? const Color(0xFFFFF2B8) : const Color(0xFFFFA16B);
          final labelColor = isHolding ? Colors.black : Colors.white;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              IgnorePointer(
                child: Opacity(
                  opacity: outerOpacity,
                  child: Transform.scale(
                    scale: glowScale,
                    child: Container(
                      key: const Key('decibel-bomb-scream-glow'),
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: RadialGradient(
                          colors: [
                            AppColors.bombRed.withAlpha(185),
                            baseColor.withAlpha(120),
                            Colors.transparent,
                          ],
                          stops: const [0.15, 0.58, 1],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.bombRed.withAlpha(
                              isHolding ? 135 : 70,
                            ),
                            blurRadius: isHolding ? 28 : 16,
                            spreadRadius: isHolding ? 6 : 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Opacity(
                  opacity: innerOpacity,
                  child: Container(
                    key: isHolding
                        ? const Key('decibel-bomb-scream-active-ring')
                        : null,
                    width: double.infinity,
                    height: 72,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: borderColor.withAlpha(isHolding ? 220 : 90),
                        width: isHolding ? 1.8 : 1,
                      ),
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: buttonScale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isHolding
                          ? const [
                              Color(0xFFFFF6C9),
                              Color(0xFFFFD86B),
                              Color(0xFFFF9548),
                            ]
                          : const [
                              Color(0xFFFF5B37),
                              Color(0xFFFF2F54),
                              Color(0xFF8A1022),
                            ],
                    ),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.bombRed.withAlpha(isHolding ? 130 : 75),
                        blurRadius: isHolding ? 22 : 12,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_rounded,
                          color: labelColor,
                          size: isHolding ? 22 : 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: GameUiText.buttonLabel.copyWith(
                            color: labelColor,
                            letterSpacing: isHolding ? 0.7 : 0.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
        (140 + 110 * (0.2 + loudness + explosion)).clamp(0, 255).toInt(),
      );

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
