import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
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
  Timer? _hapticTimer;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

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
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _initGameHelp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hapticTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// Intensity 0.0 → 1.0 based on how close to explosion
  double get _intensity => _roundSeconds == 0
      ? 0.0
      : (1.0 - _remainingMs / (_roundSeconds * 1000)).clamp(0.0, 1.0);

  void _startRound() {
    _timer?.cancel();
    _hapticTimer?.cancel();
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
    _pulseCtrl.duration = const Duration(milliseconds: 800);

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;

      final next = _remainingMs - 100;
      if (next <= 0) {
        timer.cancel();
        _hapticTimer?.cancel();
        HapticService.tripleHeavyImpact();
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
            (800 - (600 * newIntensity)).round().clamp(200, 800);
        if ((_pulseCtrl.duration?.inMilliseconds ?? 800) != newDuration) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Dynamic background color based on intensity
    final bgColor = Color.lerp(
      AppColors.bombBlueDark,
      AppColors.bombRedDark,
      _running ? _intensity : (_exploded ? 1.0 : 0.0),
    )!;

    // Dynamic bomb size based on intensity
    final bombSize = 200.0 + (_running ? _intensity * 40 : 0);
    final glowAlpha =
        _running ? (80 + 180 * _intensity).round() : (_exploded ? 220 : 60);
    final bombAlpha =
        _running ? (120 + 135 * _intensity).round() : (_exploded ? 255 : 80);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          const Web3GameBackground(
            accentColor: AppColors.bombRed,
            secondaryColor: AppColors.fingerCyan,
            overlayOpacity: 0.45,
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
                  if (!_running && !_exploded) ...[
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
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          color: Color.lerp(
                            AppColors.textDim,
                            AppColors.bombRed,
                            _intensity,
                          ),
                          fontSize: 13 + _intensity * 4,
                          letterSpacing: 2,
                        ),
                        child: Text(l10n.t('passBombDanger')),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _running ? _pulseAnim.value : 1.0,
                          child: child,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: bombSize,
                          height: bombSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.bombRed.withAlpha(bombAlpha),
                                AppColors.bombRedDark,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.bombRed.withAlpha(glowAlpha),
                                blurRadius:
                                    12 + (_running ? _intensity * 30 : 0),
                                spreadRadius: _running ? _intensity * 8 : 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _exploded
                                      ? l10n.t('passBombBoom')
                                      : (_running
                                          ? l10n.t('passBombCurrentHolder')
                                          : l10n.t('passBombReady')),
                                  style: TextStyle(
                                    color: _exploded
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    letterSpacing: 1,
                                    fontSize: _exploded ? 16 : 14,
                                    fontWeight: _exploded
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  PartyPlusStrings.player(
                                      context, _holderIndex),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_exploded)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GameResultTemplateCard(
                        accentColor: AppColors.bombRed,
                        resultTitle: l10n.t('resultSummary'),
                        resultText:
                            '${PartyPlusStrings.player(context, _holderIndex)} ${l10n.t('passBombBoom')}',
                        penaltyTitle: l10n.punishment,
                        penaltyText: l10n.t('penaltyBlindBoxTitle'),
                      ),
                    ),
                  if (_exploded && _blindBoxResult != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: PenaltyBlindBoxOverlay(result: _blindBoxResult!),
                    ),
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
