import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/audio/audio_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sounds.dart';
import '../../core/help/game_help_service.dart';
import '../../core/haptics/haptic_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/services/penalty_service.dart';
import '../../shared/widgets/game_result_action_bar.dart';
import '../../shared/widgets/game_result_template_card.dart';
import '../../shared/widgets/penalty_blind_box_overlay.dart';
import '../../shared/widgets/penalty_preset_card.dart';
import '../../shared/styles/game_ui_style.dart';
import '../../shared/widgets/web3_game_background.dart';
import 'logic/timed_round_logic.dart';
import 'party_plus_strings.dart';

class BombPassScreen extends ConsumerStatefulWidget {
  const BombPassScreen({super.key});

  @override
  ConsumerState<BombPassScreen> createState() => _BombPassScreenState();
}

class _BombPassScreenState extends ConsumerState<BombPassScreen>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  Timer? _timer;
  Timer? _dangerAudioTimer;

  late final AnimationController _pulseCtrl;

  int _playerCount = 4;
  int _holderIndex = 0;
  int _roundSeconds = 10;
  int _remainingMs = 0;
  bool _running = false;
  bool _exploded = false;
  bool _showHelpButton = false;
  PenaltyPreset _penaltyPreset = PenaltyPreset.defaults;
  PenaltyBlindBoxResult? _blindBoxResult;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _initGameHelp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dangerAudioTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// Intensity 0.0 → 1.0 based on how close to explosion
  double get _intensity => _roundSeconds == 0
      ? 0.0
      : (1.0 - _remainingMs / (_roundSeconds * 1000)).clamp(0.0, 1.0);

  double get _dangerProgress {
    if (_exploded) return 1.0;
    if (!_running) return 0.0;
    return Curves.easeInCubic.transform(_intensity);
  }

  void _startRound() {
    _timer?.cancel();
    _dangerAudioTimer?.cancel();
    final round = createTimedHolderRound(
      playerCount: _playerCount,
      minDuration: 6,
      maxDuration: 14,
      random: _random,
    );

    setState(() {
      _roundSeconds = round.durationSeconds;
      _remainingMs = round.durationSeconds * 1000;
      _holderIndex = round.holderIndex;
      _running = true;
      _exploded = false;
      _blindBoxResult = null;
    });

    // Pulse speed increases as timer nears end
    _pulseCtrl.duration = const Duration(milliseconds: 900);
    _queueDangerCue(playNow: true);

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;

      final next = _remainingMs - 100;
      if (next <= 0) {
        timer.cancel();
        _dangerAudioTimer?.cancel();
        HapticService.tripleHeavyImpact();
        AudioService.play(AppSounds.bombExplosion, volume: 1.0);
        final loser = PartyPlusStrings.player(context, _holderIndex);
        final l10n = AppLocalizations.of(context);
        setState(() {
          _remainingMs = 0;
          _running = false;
          _exploded = true;
          _blindBoxResult = PenaltyService.resolveBlindBox(
            l10n: l10n,
            random: _random,
            preset: _penaltyPreset,
            losers: <String>[loser],
          );
        });
      } else {
        // Escalate haptic feedback as danger increases
        final newIntensity =
            (1.0 - next / (_roundSeconds * 1000)).clamp(0.0, 1.0);
        if (newIntensity > 0.7) {
          // Last 30% - frequent haptics
          if (next % 400 < 100) HapticService.lightImpact();
        } else if (newIntensity > 0.4) {
          // Middle zone - occasional haptics
          if (next % 1500 < 100) HapticService.selectionClick();
        }

        // Animate pulse speed based on intensity
        final newDuration =
            (900 - (760 * Curves.easeInCubic.transform(newIntensity)))
                .round()
                .clamp(140, 900);
        if ((_pulseCtrl.duration?.inMilliseconds ?? 900) != newDuration) {
          _pulseCtrl.duration = Duration(milliseconds: newDuration);
        }

        setState(() => _remainingMs = next);
      }
    });
  }

  void _passBomb() {
    if (!_running) return;
    HapticService.selectionClick();
    setState(() {
      _holderIndex = (_holderIndex + 1) % _playerCount;
    });
  }

  void _queueDangerCue({bool playNow = false}) {
    _dangerAudioTimer?.cancel();
    if (!_running || _exploded) return;

    if (playNow) {
      _playDangerCue();
    }

    _dangerAudioTimer = Timer(_dangerCueInterval(_dangerProgress), () {
      if (!mounted || !_running || _exploded) return;
      _playDangerCue();
      _queueDangerCue();
    });
  }

  Duration _dangerCueInterval(double progress) {
    final ms = (1500 - (1000 * progress)).round().clamp(260, 1500);
    return Duration(milliseconds: ms);
  }

  void _playDangerCue() {
    final volume = 0.18 + (_dangerProgress * 0.72);
    AudioService.play(AppSounds.bombBeep, volume: volume.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final atmosphere = _dangerProgress;
    final backdropTop = Color.lerp(
      const Color(0xFF060A1A),
      const Color(0xFF2D0408),
      atmosphere,
    )!;
    final backdropBottom = Color.lerp(
      const Color(0xFF020306),
      const Color(0xFF120103),
      atmosphere,
    )!;
    final overlayRed = Color.lerp(
      AppColors.fingerCyan.withAlpha(22),
      AppColors.bombRed.withAlpha(110),
      atmosphere,
    )!;
    final bombSize = 196.0 + (atmosphere * 58);
    final glowAlpha = (72 + 180 * atmosphere).round();
    final bombAlpha = (124 + 128 * atmosphere).round();
    final dangerTrackWidth = 108.0 + atmosphere * 92;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    backdropTop,
                    Color.lerp(backdropTop, backdropBottom, 0.45)!,
                    backdropBottom,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 240),
                opacity: 0.12 + atmosphere * 0.48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.1),
                      radius: 1.05,
                      colors: [
                        overlayRed,
                        AppColors.bombRedDark.withAlpha(
                          (60 + atmosphere * 100).round(),
                        ),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Web3GameBackground(
            accentColor: Color.lerp(
              AppColors.fingerCyan,
              AppColors.bombRed,
              0.3 + atmosphere * 0.7,
            )!,
            secondaryColor: Color.lerp(
              AppColors.fingerCyanDark,
              AppColors.wheelOrange,
              atmosphere,
            )!,
            overlayOpacity: 0.32 + atmosphere * 0.34,
          ),
          Positioned(
            top: -80,
            right: -60,
            child: _DangerGlowBlob(
              size: 220 + atmosphere * 70,
              color:
                  AppColors.bombRed.withAlpha((22 + atmosphere * 80).round()),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -40,
            child: _DangerGlowBlob(
              size: 260 + atmosphere * 90,
              color:
                  AppColors.bombRed.withAlpha((14 + atmosphere * 68).round()),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: GameUiSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back_ios,
                            color: Colors.white, size: 20),
                      ),
                      const Spacer(),
                      Text(
                        l10n.t('passBomb'),
                        style: GameUiText.navTitle,
                      ),
                      const Spacer(),
                      const SizedBox(width: 20),
                    ],
                  ),
                  const SizedBox(height: GameUiSpacing.topGap),
                  const SizedBox(height: 18),
                  if (!_exploded) ...[
                    Text(
                      l10n.playersCount(_playerCount),
                      style: GameUiText.body,
                    ),
                    Slider(
                      value: _playerCount.toDouble(),
                      min: 3,
                      max: 6,
                      divisions: 3,
                      label: '$_playerCount',
                      activeColor: AppColors.bombRed,
                      onChanged: _running
                          ? null
                          : (v) => setState(() => _playerCount = v.round()),
                    ),
                    if (!_running) ...[
                      const SizedBox(height: 12),
                      PenaltyPresetCard(
                        preset: _penaltyPreset,
                        accentColor: AppColors.bombRed,
                        onChanged: (preset) {
                          setState(() => _penaltyPreset = preset);
                        },
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Hidden timer: only show a danger hint, no exact time
                    if (_running)
                      Center(
                        child: Column(
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              style: TextStyle(
                                color: Color.lerp(
                                  AppColors.textDim,
                                  AppColors.bombRed,
                                  atmosphere,
                                ),
                                fontSize: 13 + atmosphere * 5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2 + atmosphere * 1.5,
                              ),
                              child: Text(l10n.t('passBombDanger')),
                            ),
                            const SizedBox(height: 10),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: dangerTrackWidth,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withAlpha(16),
                                border: Border.all(
                                  color: AppColors.bombRed.withAlpha(
                                    (30 + atmosphere * 80).round(),
                                  ),
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: atmosphere.clamp(0.06, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.wheelOrange.withAlpha(210),
                                          AppColors.bombRed.withAlpha(245),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.bombRed.withAlpha(
                                            (30 + atmosphere * 90).round(),
                                          ),
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, child) {
                            final pulse =
                                Curves.easeInOut.transform(_pulseCtrl.value);
                            final scale = _running
                                ? (0.96 + pulse * (0.08 + atmosphere * 0.2))
                                : 1.0;
                            final rotation = _running
                                ? sin(_pulseCtrl.value * pi * 2) *
                                    (0.01 + atmosphere * 0.05)
                                : 0.0;
                            return Transform.rotate(
                              angle: rotation,
                              child: Transform.scale(
                                scale: scale,
                                child: child,
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: bombSize,
                            height: bombSize,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                for (var index = 0; index < 3; index++)
                                  _DangerPulseRing(
                                    size: bombSize,
                                    progress:
                                        (_pulseCtrl.value + index * 0.22) % 1.0,
                                    intensity: atmosphere,
                                  ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withAlpha(
                                          (26 + atmosphere * 40).round(),
                                        ),
                                        AppColors.bombRed.withAlpha(bombAlpha),
                                        AppColors.bombRedDark,
                                      ],
                                      stops: const [0.0, 0.42, 1.0],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.bombRed.withAlpha(
                                          glowAlpha,
                                        ),
                                        blurRadius: 16 + atmosphere * 36,
                                        spreadRadius: atmosphere * 10,
                                      ),
                                    ],
                                  ),
                                  child: SizedBox(
                                    width: bombSize,
                                    height: bombSize,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _running
                                                ? l10n
                                                    .t('passBombCurrentHolder')
                                                : l10n.t('passBombReady'),
                                            style: TextStyle(
                                              color: Color.lerp(
                                                AppColors.textSecondary,
                                                Colors.white,
                                                0.2 + atmosphere * 0.45,
                                              ),
                                              letterSpacing: 1.1,
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            PartyPlusStrings.player(
                                                context, _holderIndex),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 30 + atmosphere * 4,
                                              fontWeight: FontWeight.w700,
                                              shadows: [
                                                Shadow(
                                                  color: AppColors.bombRed
                                                      .withAlpha(
                                                    (50 + atmosphere * 110)
                                                        .round(),
                                                  ),
                                                  blurRadius:
                                                      10 + atmosphere * 12,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GameResultTemplateCard(
                                accentColor: AppColors.bombRed,
                                resultTitle: l10n.t('resultSummary'),
                                resultText:
                                    '${PartyPlusStrings.player(context, _holderIndex)} ${l10n.t('passBombBoom')}',
                                penaltyTitle: l10n.punishment,
                                penaltyText: l10n.t('penaltyBlindBoxTitle'),
                              ),
                              if (_blindBoxResult != null) ...[
                                const SizedBox(height: 12),
                                PenaltyBlindBoxOverlay(
                                  result: _blindBoxResult!,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_exploded)
                    GameResultActionBar(
                      accentColor: AppColors.bombRed,
                      primaryLabel: l10n.t('nextRound'),
                      onPrimaryTap: _startRound,
                    )
                  else
                    GameResultActionBar(
                      accentColor: AppColors.bombRed,
                      primaryLabel: l10n.t('passBombPassButton'),
                      onPrimaryTap: () {
                        if (_running) {
                          _passBomb();
                          return;
                        }
                        // No separate "start countdown" button:
                        // first tap on primary button starts the round.
                        _startRound();
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Back edge swipe
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
        gameId: 'pass_bomb',
        gameTitle: l10n.t('passBomb'),
        helpBody: l10n.t('helpPassBombBody'),
      );
      if (mounted) setState(() => _showHelpButton = true);
    });
  }

  void _showGameHelp() {
    final l10n = AppLocalizations.of(context);
    GameHelpService.showGameHelpDialog(
      context,
      gameTitle: l10n.t('passBomb'),
      helpBody: l10n.t('helpPassBombBody'),
    );
  }
}

class _DangerGlowBlob extends StatelessWidget {
  const _DangerGlowBlob({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.38,
              spreadRadius: size * 0.08,
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerPulseRing extends StatelessWidget {
  const _DangerPulseRing({
    required this.size,
    required this.progress,
    required this.intensity,
  });

  final double size;
  final double progress;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final ringScale = 1.0 + progress * (0.22 + intensity * 0.42);
    final opacity = ((1 - progress) * (0.16 + intensity * 0.2)).clamp(0.0, 1.0);

    return Transform.scale(
      scale: ringScale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.bombRed.withValues(alpha: opacity),
            width: 1.4 + intensity * 1.6,
          ),
        ),
      ),
    );
  }
}
