import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/help/game_help_service.dart';
import '../../core/haptics/haptic_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/game_result_action_bar.dart';
import '../../shared/widgets/game_result_template_card.dart';
import '../../shared/widgets/game_stage_stepper.dart';
import '../../shared/widgets/web3_game_background.dart';
import 'logic/left_right_logic.dart';
import 'party_plus_strings.dart';

enum _ReactPhase { setup, playing, result }

class LeftRightReactScreen extends StatefulWidget {
  const LeftRightReactScreen({super.key});

  @override
  State<LeftRightReactScreen> createState() => _LeftRightReactScreenState();
}

class _LeftRightReactScreenState extends State<LeftRightReactScreen> {
  final Random _random = Random();

  Timer? _timer;
  int _playerCount = 4;
  int _round = 1;
  int _totalRounds = 8;
  int _currentPlayer = 0;
  List<int> _penalties = [];

  SwipeDirection _target = SwipeDirection.left;
  bool _isReverse = false;
  bool _awaitingSwipe = false;
  DateTime? _swipeStart;
  String _status = '';
  _ReactPhase _phase = _ReactPhase.setup;
  bool _showHelpButton = false;
  double _reverseProbability = 0.5;
  bool _enableVerticalSwipe = false;

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

  /// Compute the reaction window in milliseconds for the current round.
  /// Starts at 2000ms for round 1, linearly decreases to 1200ms by the last
  /// round.  For a single-round game the full 2000ms is used.
  int _reactionWindowMs() {
    if (_totalRounds <= 1) return 2000;
    final progress = (_round - 1) / (_totalRounds - 1); // 0.0 .. 1.0
    return (2000 - (800 * progress)).round(); // 2000 -> 1200
  }

  void _startGame() {
    _timer?.cancel();
    setState(() {
      _phase = _ReactPhase.playing;
      _round = 1;
      _totalRounds = _playerCount * 2;
      _currentPlayer = 0;
      _penalties = List<int>.filled(_playerCount, 0);
      _awaitingSwipe = false;
      _isReverse = false;
      _status = '';
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
      _status = '';
    });
  }

  void _beginSwipeWindow() {
    _timer?.cancel();
    HapticService.lightImpact();
    final windowMs = _reactionWindowMs();
    setState(() {
      _awaitingSwipe = true;
      _swipeStart = DateTime.now();
      _status = '';
    });

    _timer = Timer(Duration(milliseconds: windowMs), () {
      if (!mounted || !_awaitingSwipe) return;
      HapticService.notificationWarning();
      final l10n = AppLocalizations.of(context);
      final resolution = timeoutReaction();
      setState(() {
        _awaitingSwipe = false;
        _penalties[_currentPlayer] += resolution.penaltyDelta;
        _status = l10n.t('leftRightTimeout');
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
    if (_round >= _totalRounds) {
      setState(() => _phase = _ReactPhase.result);
      return;
    }

    setState(() {
      _round += 1;
      _currentPlayer = (_currentPlayer + 1) % _playerCount;
    });
    _prepareRound();
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

  String _resultPenaltyText(AppLocalizations l10n) {
    final maxPenalty =
        _penalties.isEmpty ? 0 : _penalties.reduce((a, b) => a > b ? a : b);
    if (maxPenalty <= 0) return l10n.t('penaltyGuideDefault');

    final losers = <String>[];
    for (int i = 0; i < _penalties.length; i++) {
      if (_penalties[i] == maxPenalty) {
        losers.add(PartyPlusStrings.player(context, i));
      }
    }
    return l10n.t('penaltyResult', {
      'player': losers.join('、'),
      'penalty': l10n.pointsCount(maxPenalty),
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stage = switch (_phase) {
      _ReactPhase.setup => GameStage.prepare,
      _ReactPhase.playing => GameStage.playing,
      _ReactPhase.result => GameStage.result,
    };

    // Visual styling that changes for reverse rounds.
    final Color roundAccent =
        _isReverse ? Colors.deepOrange : AppColors.wheelOrange;
    final Color instructionBorderColor = _isReverse
        ? Colors.deepOrange.withAlpha(200)
        : AppColors.wheelOrange.withAlpha(160);
    final Color swipeAreaBorderColor =
        _isReverse ? Colors.deepOrange : AppColors.textDim;

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                  const SizedBox(height: 10),
                  Center(
                    child: GameStageStepper(
                      stage: stage,
                      accentColor: AppColors.wheelOrange,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_phase == _ReactPhase.setup) ...[
                    Text(
                      l10n.playersCount(_playerCount),
                      style: const TextStyle(color: AppColors.textSecondary),
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
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('leftRightRule'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.surfaceVariant,
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.t('leftRightReverseChance')}: '
                            '${(_reverseProbability * 100).round()}%',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Slider(
                            value: _reverseProbability,
                            min: 0.1,
                            max: 0.9,
                            divisions: 8,
                            activeColor: AppColors.wheelOrange,
                            onChanged: (value) {
                              setState(() => _reverseProbability = value);
                            },
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.t('leftRightEnableVerticalSwipe'),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${l10n.t('leftRightDirectionMode')}: '
                                      '${_enableVerticalSwipe ? l10n.t('leftRightDirectionModeAll') : l10n.t('leftRightDirectionModeHorizontal')}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _enableVerticalSwipe,
                                onChanged: (value) {
                                  setState(() => _enableVerticalSwipe = value);
                                },
                                activeThumbColor: AppColors.wheelOrange,
                                activeTrackColor:
                                    AppColors.wheelOrange.withAlpha(120),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.wheelOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.start),
                    ),
                  ] else if (_phase == _ReactPhase.playing) ...[
                    Text(
                      l10n.roundProgress(_round, _totalRounds),
                      style: const TextStyle(color: AppColors.textSecondary),
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
                          fontSize: 16,
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
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: AppColors.surfaceVariant,
                            border: Border.all(color: swipeAreaBorderColor),
                          ),
                          child: Center(
                            child: Icon(
                              _directionIcon(_target),
                              color: roundAccent,
                              size: 90,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_status.isNotEmpty)
                      Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
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
                    GameResultTemplateCard(
                      accentColor: AppColors.wheelOrange,
                      resultTitle: l10n.t('resultSummary'),
                      resultText: l10n.t('leftRightFinalPenalties'),
                      penaltyTitle: l10n.punishment,
                      penaltyText: _resultPenaltyText(l10n),
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
