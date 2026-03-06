import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/help/game_help_service.dart';
import '../../core/haptics/haptic_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/styles/game_ui_style.dart';
import '../../shared/widgets/game_result_action_bar.dart';
import '../../shared/widgets/game_result_template_card.dart';
import '../../shared/widgets/penalty_blind_box_overlay.dart';
import '../../shared/widgets/penalty_preset_card.dart';
import '../../shared/widgets/difficulty_option_card.dart';
import '../../shared/widgets/web3_game_background.dart';
import '../../shared/services/penalty_service.dart';
import 'logic/left_right_logic.dart';
import 'party_plus_strings.dart';

enum _ReactPhase { setup, playing, result }

enum _LeftRightDifficulty { easy, medium, hard }

class _LeftRightDifficultyConfig {
  const _LeftRightDifficultyConfig({
    required this.reverseProbability,
    required this.enableVerticalSwipe,
  });

  final double reverseProbability;
  final bool enableVerticalSwipe;
}

class LeftRightReactScreen extends StatefulWidget {
  const LeftRightReactScreen({super.key});

  @override
  State<LeftRightReactScreen> createState() => _LeftRightReactScreenState();
}

class _LeftRightReactScreenState extends State<LeftRightReactScreen> {
  final Random _random = Random();

  Timer? _timer;
  int _playerCount = 4;
  int _selectedRounds = 8;
  int _round = 1;
  int _totalRounds = 8;
  int _currentPlayer = 0;
  List<int> _penalties = [];

  SwipeDirection _target = SwipeDirection.left;
  bool _isReverse = false;
  bool _awaitingSwipe = false;
  DateTime? _swipeStart;
  DateTime? _reactionDeadlineAt;
  int _activeReactionWindowMs = 0;
  int _remainingReactionMs = 0;
  String _status = '';
  _ReactPhase _phase = _ReactPhase.setup;
  _LeftRightDifficulty _difficulty = _LeftRightDifficulty.medium;
  bool _showHelpButton = false;
  PenaltyPreset _penaltyPreset = PenaltyPreset.defaults;
  PenaltyBlindBoxResult? _blindBoxResult;

  _LeftRightDifficultyConfig get _difficultyConfig {
    return switch (_difficulty) {
      _LeftRightDifficulty.easy => const _LeftRightDifficultyConfig(
          reverseProbability: 0.2,
          enableVerticalSwipe: false,
        ),
      _LeftRightDifficulty.medium => const _LeftRightDifficultyConfig(
          reverseProbability: 0.5,
          enableVerticalSwipe: false,
        ),
      _LeftRightDifficulty.hard => const _LeftRightDifficultyConfig(
          reverseProbability: 0.75,
          enableVerticalSwipe: true,
        ),
    };
  }

  double get _reverseProbability => _difficultyConfig.reverseProbability;
  bool get _enableVerticalSwipe => _difficultyConfig.enableVerticalSwipe;

  @override
  void initState() {
    super.initState();
    _initGameHelp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _totalTurns => _totalRounds * _playerCount;

  int get _currentTurnIndex =>
      ((_round - 1) * _playerCount) + _currentPlayer + 1;

  /// Compute the reaction window in milliseconds for the current turn.
  /// Starts at 2000ms for the first turn, linearly decreases to 1200ms by
  /// the final turn.
  int _reactionWindowMs() {
    if (_totalTurns <= 1) return 2000;
    final progress = (_currentTurnIndex - 1) / (_totalTurns - 1); // 0.0 .. 1.0
    return (2000 - (800 * progress)).round(); // 2000 -> 1200
  }

  void _startGame() {
    _timer?.cancel();
    setState(() {
      _phase = _ReactPhase.playing;
      _round = 1;
      _totalRounds = _selectedRounds;
      _currentPlayer = 0;
      _penalties = List<int>.filled(_playerCount, 0);
      _awaitingSwipe = false;
      _isReverse = false;
      _reactionDeadlineAt = null;
      _activeReactionWindowMs = 0;
      _remainingReactionMs = 0;
      _status = '';
      _blindBoxResult = null;
    });
    _prepareRound();
  }

  void _prepareRound() {
    setState(() {
      if (_enableVerticalSwipe) {
        _target = SwipeDirection
            .values[_random.nextInt(SwipeDirection.values.length)];
      } else {
        _target =
            _random.nextBool() ? SwipeDirection.left : SwipeDirection.right;
      }
      _isReverse = _random.nextDouble() < _reverseProbability;
      _awaitingSwipe = false;
      _reactionDeadlineAt = null;
      _activeReactionWindowMs = 0;
      _remainingReactionMs = 0;
      _status = '';
    });
    _beginSwipeWindow();
  }

  void _beginSwipeWindow() {
    _timer?.cancel();
    HapticService.lightImpact();
    final windowMs = _reactionWindowMs();
    final startedAt = DateTime.now();
    setState(() {
      _awaitingSwipe = true;
      _swipeStart = startedAt;
      _activeReactionWindowMs = windowMs;
      _remainingReactionMs = windowMs;
      _reactionDeadlineAt = startedAt.add(Duration(milliseconds: windowMs));
      _status = '';
    });

    _timer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      final deadlineAt = _reactionDeadlineAt;
      if (!mounted || !_awaitingSwipe || deadlineAt == null) {
        timer.cancel();
        return;
      }

      final remaining = deadlineAt.difference(DateTime.now()).inMilliseconds;
      if (remaining <= 0) {
        timer.cancel();
        HapticService.notificationWarning();
        final l10n = AppLocalizations.of(context);
        final resolution = timeoutReaction();
        setState(() {
          _awaitingSwipe = false;
          _remainingReactionMs = 0;
          _reactionDeadlineAt = null;
          _penalties[_currentPlayer] += resolution.penaltyDelta;
          _status = l10n.t('leftRightTimeout');
        });
        return;
      }

      setState(() {
        _remainingReactionMs = remaining;
      });
    });
  }

  void _handleSwipe(SwipeDirection dir) {
    if (!_awaitingSwipe) return;

    _timer?.cancel();
    final l10n = AppLocalizations.of(context);
    final reaction = DateTime.now().difference(_swipeStart!).inMilliseconds;

    // In reverse mode the player must swipe OPPOSITE to the shown direction.
    final effectiveTarget = _isReverse ? oppositeDirection(_target) : _target;

    final resolution = resolveReaction(target: effectiveTarget, actual: dir);

    setState(() {
      _awaitingSwipe = false;
      _remainingReactionMs = 0;
      _reactionDeadlineAt = null;

      if (resolution.success) {
        HapticService.notificationSuccess();
        _status = l10n.t('leftRightSuccessMs', {'ms': '$reaction'});
      } else if (_isReverse) {
        // Wrong direction in a reverse round is extra punishing: +2
        HapticService.errorVibrate();
        _penalties[_currentPlayer] += 2;
        _status = l10n.t('leftRightReversed');
      } else {
        HapticService.errorVibrate();
        _penalties[_currentPlayer] += resolution.penaltyDelta;
        _status = l10n.t('leftRightWrong');
      }
    });
  }

  void _nextTurn() {
    _timer?.cancel();
    final isLastTurn =
        _round >= _totalRounds && _currentPlayer >= _playerCount - 1;
    if (isLastTurn) {
      final l10n = AppLocalizations.of(context);
      _blindBoxResult = _resolveBlindBoxResult(l10n);
      setState(() => _phase = _ReactPhase.result);
      return;
    }

    setState(() {
      if (_currentPlayer >= _playerCount - 1) {
        _currentPlayer = 0;
        _round += 1;
      } else {
        _currentPlayer += 1;
      }
    });
    _prepareRound();
  }

  double get _countdownProgress {
    if (!_awaitingSwipe || _activeReactionWindowMs <= 0) return 1.0;
    return (_remainingReactionMs / _activeReactionWindowMs).clamp(0.0, 1.0);
  }

  Color _countdownBorderColor({
    required Color idleColor,
    required double progress,
  }) {
    if (!_awaitingSwipe) return idleColor;

    final base = progress > 0.5
        ? Color.lerp(
            const Color(0xFF4DFF88),
            Colors.orange,
            (1 - progress) * 2,
          )!
        : Color.lerp(
            Colors.orange,
            const Color(0xFFFF3B30),
            (0.5 - progress) * 2,
          )!;

    // Flashing alert in the final 30% of the countdown.
    if (progress < 0.3) {
      final pulse = 0.55 + (0.45 * ((sin(_remainingReactionMs / 70) + 1) / 2));
      return Color.lerp(base, Colors.white, (1 - pulse) * 0.25)!;
    }
    return base;
  }

  String _directionLabel(SwipeDirection direction, AppLocalizations l10n) {
    switch (direction) {
      case SwipeDirection.left:
        return l10n.t('directionLeft');
      case SwipeDirection.right:
        return l10n.t('directionRight');
      case SwipeDirection.up:
        return l10n.t('directionUp');
      case SwipeDirection.down:
        return l10n.t('directionDown');
    }
  }

  IconData _directionIcon(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.left:
        return Icons.arrow_back_rounded;
      case SwipeDirection.right:
        return Icons.arrow_forward_rounded;
      case SwipeDirection.up:
        return Icons.arrow_upward_rounded;
      case SwipeDirection.down:
        return Icons.arrow_downward_rounded;
    }
  }

  String _difficultyLabel(_LeftRightDifficulty level, AppLocalizations l10n) {
    return switch (level) {
      _LeftRightDifficulty.easy => l10n.t('leftRightDifficultyEasy'),
      _LeftRightDifficulty.medium => l10n.t('leftRightDifficultyMedium'),
      _LeftRightDifficulty.hard => l10n.t('leftRightDifficultyHard'),
    };
  }

  String _difficultyHint(_LeftRightDifficulty level, AppLocalizations l10n) {
    return switch (level) {
      _LeftRightDifficulty.easy => l10n.t('leftRightDifficultyEasyHint'),
      _LeftRightDifficulty.medium => l10n.t('leftRightDifficultyMediumHint'),
      _LeftRightDifficulty.hard => l10n.t('leftRightDifficultyHardHint'),
    };
  }

  Color _difficultyAccentColor(_LeftRightDifficulty level) {
    return switch (level) {
      _LeftRightDifficulty.easy => const Color(0xFF78F7DD),
      _LeftRightDifficulty.medium => const Color(0xFFFFD166),
      _LeftRightDifficulty.hard => const Color(0xFFFF6B6B),
    };
  }

  String _resultPenaltyText(AppLocalizations l10n) {
    final maxPenalty =
        _penalties.isEmpty ? 0 : _penalties.reduce((a, b) => a > b ? a : b);
    if (maxPenalty <= 0) {
      return PenaltyService.guidancePlan(
        l10n: l10n,
        guide: PenaltyGuideType.defaultGuide,
      ).text;
    }

    final losers = <String>[];
    for (int i = 0; i < _penalties.length; i++) {
      if (_penalties[i] == maxPenalty) {
        losers.add(PartyPlusStrings.player(context, i));
      }
    }
    return PenaltyService.pointsPlan(
      l10n: l10n,
      players: losers,
      points: maxPenalty,
    ).text;
  }

  PenaltyBlindBoxResult? _resolveBlindBoxResult(AppLocalizations l10n) {
    final maxPenalty =
        _penalties.isEmpty ? 0 : _penalties.reduce((a, b) => a > b ? a : b);
    if (maxPenalty <= 0) {
      return null;
    }

    final losers = <String>[];
    for (int i = 0; i < _penalties.length; i++) {
      if (_penalties[i] == maxPenalty) {
        losers.add(PartyPlusStrings.player(context, i));
      }
    }
    return PenaltyService.resolveBlindBox(
      l10n: l10n,
      random: _random,
      preset: _penaltyPreset,
      losers: losers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Visual styling that changes for reverse rounds.
    final Color roundAccent =
        _isReverse ? Colors.deepOrange : AppColors.wheelOrange;
    final Color instructionBorderColor = _isReverse
        ? Colors.deepOrange.withAlpha(200)
        : AppColors.wheelOrange.withAlpha(160);
    final Color swipeAreaBorderColor =
        _isReverse ? Colors.deepOrange : AppColors.textDim;
    final countdownProgress = _countdownProgress;
    final countdownBorderColor = _countdownBorderColor(
      idleColor: swipeAreaBorderColor,
      progress: countdownProgress,
    );
    final countdownBorderWidth =
        _awaitingSwipe ? 2 + ((1 - countdownProgress) * 2.5) : 1.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Web3GameBackground(
            accentColor: AppColors.wheelOrange,
            secondaryColor: AppColors.fingerCyan,
            overlayOpacity: 0.82,
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
                        l10n.t('leftRight'),
                        style: GameUiText.navTitle,
                      ),
                      const Spacer(),
                      const SizedBox(width: 20),
                    ],
                  ),
                  const SizedBox(height: GameUiSpacing.topGap),
                  const SizedBox(height: 22),
                  if (_phase == _ReactPhase.setup) ...[
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.playersCount(_playerCount),
                              style: GameUiText.body,
                            ),
                            Slider(
                              value: _playerCount.toDouble(),
                              min: 3,
                              max: 6,
                              divisions: 3,
                              activeColor: AppColors.wheelOrange,
                              onChanged: (v) =>
                                  setState(() => _playerCount = v.round()),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.t('leftRightRoundsSetting', {
                                'count': '$_selectedRounds',
                              }),
                              style: GameUiText.body,
                            ),
                            Slider(
                              value: _selectedRounds.toDouble(),
                              min: 4,
                              max: 12,
                              divisions: 8,
                              activeColor: AppColors.wheelOrange,
                              onChanged: (v) =>
                                  setState(() => _selectedRounds = v.round()),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.t('leftRightRule'),
                              style: GameUiText.body,
                            ),
                            const SizedBox(height: 12),
                            PenaltyPresetCard(
                              preset: _penaltyPreset,
                              accentColor: AppColors.wheelOrange,
                              onChanged: (preset) {
                                setState(() => _penaltyPreset = preset);
                              },
                            ),
                            const SizedBox(height: 14),
                            Text(
                              l10n.t('leftRightDifficultyTitle'),
                              style: GameUiText.bodyStrong,
                            ),
                            const SizedBox(height: 8),
                            ..._LeftRightDifficulty.values.map((level) {
                              final selected = _difficulty == level;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: DifficultyOptionCard(
                                  title: _difficultyLabel(level, l10n),
                                  hint: _difficultyHint(level, l10n),
                                  selected: selected,
                                  accentColor: _difficultyAccentColor(level),
                                  onTap: () =>
                                      setState(() => _difficulty = level),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.wheelOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: GameUiText.buttonLabel,
                      ),
                      child: Text(l10n.start),
                    ),
                  ] else if (_phase == _ReactPhase.playing) ...[
                    Text(
                      l10n.roundProgress(_round, _totalRounds),
                      style: GameUiText.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      PartyPlusStrings.player(context, _currentPlayer),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: instructionBorderColor),
                      ),
                      child: Text(
                        _isReverse
                            ? l10n.t('leftRightReverseSwipeTo', {
                                'direction': _directionLabel(_target, l10n),
                              })
                            : l10n.t('leftRightSwipeTo', {
                                'direction': _directionLabel(_target, l10n),
                              }),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isReverse
                              ? Colors.deepOrange.shade200
                              : Colors.white,
                          fontSize: GameUiText.bodyStrong.fontSize,
                          fontWeight:
                              _isReverse ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GestureDetector(
                        onPanEnd: (details) {
                          final velocity = details.velocity.pixelsPerSecond;
                          final dir = directionFromVelocity(
                            dx: velocity.dx,
                            dy: velocity.dy,
                          );
                          if (dir == null) return;
                          _handleSwipe(dir);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 90),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: AppColors.surfaceVariant,
                            border: Border.all(
                              color: countdownBorderColor,
                              width: countdownBorderWidth,
                            ),
                            boxShadow: _awaitingSwipe
                                ? [
                                    BoxShadow(
                                      color: countdownBorderColor.withAlpha(75),
                                      blurRadius: 14,
                                      spreadRadius: 1.5,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  _directionIcon(_target),
                                  color: roundAccent,
                                  size: 90,
                                ),
                              ),
                              if (_awaitingSwipe)
                                Positioned(
                                  right: 12,
                                  top: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(120),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color:
                                            countdownBorderColor.withAlpha(180),
                                      ),
                                    ),
                                    child: Text(
                                      '${(_remainingReactionMs / 1000).toStringAsFixed(1)}s',
                                      style: TextStyle(
                                        color: countdownBorderColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_status.isNotEmpty)
                      Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: GameUiText.bodyStrong,
                      ),
                    const SizedBox(height: 8),
                    if (_awaitingSwipe)
                      GameResultActionBar(
                        accentColor: roundAccent,
                        primaryLabel: l10n.t('leftRightWaitingSwipe'),
                        onPrimaryTap: null,
                      )
                    else if (_status.isEmpty)
                      GameResultActionBar(
                        accentColor: roundAccent,
                        primaryLabel: l10n.t('leftRightBeginReaction'),
                        onPrimaryTap: _beginSwipeWindow,
                      )
                    else
                      GameResultActionBar(
                        accentColor: AppColors.wheelOrange,
                        primaryLabel: l10n.t('nextPlayer'),
                        onPrimaryTap: _nextTurn,
                      ),
                  ] else ...[
                    Text(
                      l10n.t('leftRightFinalPenalties'),
                      textAlign: TextAlign.center,
                      style: GameUiText.sectionTitle.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_penalties.length, (i) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.surfaceVariant,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                PartyPlusStrings.player(context, i),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Text(
                              l10n.pointsCount(_penalties[i]),
                              style:
                                  const TextStyle(color: AppColors.wheelOrange),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        final penaltyText = _resultPenaltyText(l10n);
                        if (_blindBoxResult == null) {
                          return GameResultTemplateCard(
                            accentColor: AppColors.wheelOrange,
                            resultTitle: l10n.t('resultSummary'),
                            resultText: l10n.t('leftRightFinalPenalties'),
                            penaltyTitle: l10n.punishment,
                            penaltyText: penaltyText,
                          );
                        }
                        return PenaltyBlindBoxOverlay(
                          result: _blindBoxResult!,
                        );
                      },
                    ),
                    const Spacer(),
                    GameResultActionBar(
                      accentColor: AppColors.wheelOrange,
                      primaryLabel: l10n.t('playAgain'),
                      onPrimaryTap: _startGame,
                    ),
                  ],
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
        gameId: 'left_right',
        gameTitle: l10n.t('leftRight'),
        helpBody: l10n.t('helpLeftRightBody'),
      );
      if (mounted) setState(() => _showHelpButton = true);
    });
  }

  void _showGameHelp() {
    final l10n = AppLocalizations.of(context);
    GameHelpService.showGameHelpDialog(
      context,
      gameTitle: l10n.t('leftRight'),
      helpBody: l10n.t('helpLeftRightBody'),
    );
  }
}
