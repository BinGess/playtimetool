import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/help/game_help_service.dart';
import '../../core/haptics/haptic_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/game_result_action_bar.dart';
import '../../shared/widgets/difficulty_option_card.dart';
import '../../shared/widgets/game_result_template_card.dart';
import '../../shared/styles/game_ui_style.dart';
import '../../shared/widgets/web3_game_background.dart';
import '../../shared/services/penalty_service.dart';
import 'logic/truth_raise_logic.dart';
import 'party_plus_strings.dart';

enum _TruthPhase { setup, playing, result }

class TruthOrRaiseScreen extends StatefulWidget {
  const TruthOrRaiseScreen({super.key});

  @override
  State<TruthOrRaiseScreen> createState() => _TruthOrRaiseScreenState();
}

class _TruthOrRaiseScreenState extends State<TruthOrRaiseScreen> {
  final Random _random = Random();
  final Set<int> _usedQuestions = {};

  int _playerCount = 4;
  int _selectedRounds = 8;
  TruthRaiseScaleLevel _selectedScale = TruthRaiseScaleLevel.standard;
  int _currentPlayer = 0;
  int _round = 1;
  int _totalRounds = 8;
  int _raiseLevel = 0;

  String _question = '';
  String _lastAction = '';
  List<int> _penalties = [];
  _TruthPhase _phase = _TruthPhase.setup;
  bool _showHelpButton = false;

  TruthRaiseScaleConfig get _scaleConfig => configForScale(_selectedScale);

  @override
  void initState() {
    super.initState();
    _initGameHelp();
  }

  String _scaleTitle(AppLocalizations l10n, TruthRaiseScaleLevel scale) {
    switch (scale) {
      case TruthRaiseScaleLevel.gentle:
        return l10n.t('truthRaiseScaleGentle');
      case TruthRaiseScaleLevel.standard:
        return l10n.t('truthRaiseScaleStandard');
      case TruthRaiseScaleLevel.spicy:
        return l10n.t('truthRaiseScaleSpicy');
      case TruthRaiseScaleLevel.extreme:
        return l10n.t('truthRaiseScaleExtreme');
    }
  }

  Color _scaleAccentColor(TruthRaiseScaleLevel scale) {
    return switch (scale) {
      TruthRaiseScaleLevel.gentle => const Color(0xFF5CE08A),
      TruthRaiseScaleLevel.standard => AppColors.bombRed,
      TruthRaiseScaleLevel.spicy => const Color(0xFFFF8A4C),
      TruthRaiseScaleLevel.extreme => const Color(0xFFFF4D6D),
    };
  }

  void _startGame() {
    _usedQuestions.clear();
    setState(() {
      _phase = _TruthPhase.playing;
      _currentPlayer = 0;
      _round = 1;
      _totalRounds = _selectedRounds;
      _raiseLevel = 0;
      _lastAction = '';
      _penalties = List<int>.filled(_playerCount, 0);
      _question = _randomQuestion();
    });
  }

  String _randomQuestion() {
    final l10n = AppLocalizations.of(context);
    const totalQuestions = 20;
    if (_usedQuestions.length >= totalQuestions) {
      _usedQuestions.clear();
    }
    int index;
    do {
      index = _random.nextInt(totalQuestions) + 1;
    } while (_usedQuestions.contains(index));
    _usedQuestions.add(index);
    return l10n.t('truthRaiseQuestion$index');
  }

  void _answer() {
    HapticService.notificationSuccess();
    final l10n = AppLocalizations.of(context);
    final action = applyAnswerAction();
    setState(() {
      _raiseLevel = action.nextRaise;
      _lastAction = l10n.t('truthRaiseAnsweredAction', {
        'player': PartyPlusStrings.player(context, _currentPlayer),
      });
    });
    _nextTurn();
  }

  void _skipAndRaise() {
    HapticService.lightImpact();
    final l10n = AppLocalizations.of(context);
    final action = applySkipAction(
      _raiseLevel,
      maxRaise: _scaleConfig.maxRaise,
      step: _scaleConfig.step,
    );
    setState(() {
      _raiseLevel = action.nextRaise;
      _penalties[_currentPlayer] += action.penaltyDelta;
      _lastAction = l10n.t('truthRaiseSkippedAction', {
        'player': PartyPlusStrings.player(context, _currentPlayer),
        'count': '${action.nextRaise}',
      });
    });
    _nextTurn();
  }

  void _nextTurn() {
    if (_round >= _totalRounds) {
      setState(() => _phase = _TruthPhase.result);
      return;
    }

    setState(() {
      _round += 1;
      _currentPlayer = (_currentPlayer + 1) % _playerCount;
      _question = _randomQuestion();
    });
  }

  void _initGameHelp() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      await GameHelpService.ensureFirstTimeShown(
        context: context,
        gameId: 'truth_or_raise',
        gameTitle: l10n.t('truthRaise'),
        helpBody: l10n.t('helpTruthRaiseBody'),
      );
      if (mounted) setState(() => _showHelpButton = true);
    });
  }

  void _showGameHelp() {
    final l10n = AppLocalizations.of(context);
    GameHelpService.showGameHelpDialog(
      context,
      gameTitle: l10n.t('truthRaise'),
      helpBody: l10n.t('helpTruthRaiseBody'),
    );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Web3GameBackground(
            accentColor: AppColors.bombRed,
            secondaryColor: AppColors.fingerCyan,
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
                        l10n.t('truthRaise'),
                        style: GameUiText.navTitle,
                      ),
                      const Spacer(),
                      const SizedBox(width: 20),
                    ],
                  ),
                  const SizedBox(height: GameUiSpacing.topGap),
                  const SizedBox(height: 22),
                  if (_phase == _TruthPhase.setup) ...[
                    Text(
                      l10n.t('truthRaiseSetupTitle'),
                      style: GameUiText.sectionTitle,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.playersCount(_playerCount),
                      style: GameUiText.body,
                    ),
                    Slider(
                      value: _playerCount.toDouble(),
                      min: 3,
                      max: 6,
                      divisions: 3,
                      activeColor: AppColors.bombRed,
                      onChanged: (v) =>
                          setState(() => _playerCount = v.round()),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('truthRaiseRoundsSetting', {
                        'count': '$_selectedRounds',
                      }),
                      style: GameUiText.body,
                    ),
                    Slider(
                      value: _selectedRounds.toDouble(),
                      min: 4,
                      max: 12,
                      divisions: 8,
                      activeColor: AppColors.bombRed,
                      onChanged: (v) =>
                          setState(() => _selectedRounds = v.round()),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('truthRaiseScaleTitle'),
                      style: GameUiText.body,
                    ),
                    const SizedBox(height: 8),
                    ...TruthRaiseScaleLevel.values.map((scale) {
                      final isSelected = scale == _selectedScale;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DifficultyOptionCard(
                          title: _scaleTitle(l10n, scale),
                          selected: isSelected,
                          accentColor: _scaleAccentColor(scale),
                          onTap: () => setState(() => _selectedScale = scale),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('truthRaiseRule'),
                      style: GameUiText.body,
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bombRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: GameUiText.buttonLabel,
                      ),
                      child: Text(l10n.start),
                    ),
                  ] else if (_phase == _TruthPhase.playing) ...[
                    Text(
                      l10n.roundProgress(_round, _totalRounds),
                      textAlign: TextAlign.center,
                      style: GameUiText.body,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      PartyPlusStrings.player(context, _currentPlayer),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.bombRed.withAlpha(140)),
                      ),
                      child: Text(
                        _question,
                        style: GameUiText.bodyStrong,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.t('truthRaiseCurrent', {'count': '$_raiseLevel'}),
                      style: const TextStyle(color: AppColors.bombRed),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.t('truthRaiseScaleCurrent', {
                        'level': _scaleTitle(l10n, _selectedScale),
                      }),
                      style: GameUiText.body,
                      textAlign: TextAlign.center,
                    ),
                    if (_lastAction.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _lastAction,
                        textAlign: TextAlign.center,
                        style: GameUiText.body,
                      ),
                    ],
                    const Spacer(),
                    GameResultActionBar(
                      accentColor: AppColors.bombRed,
                      secondaryLabel: l10n.t('truthRaiseSkipRaise'),
                      onSecondaryTap: _skipAndRaise,
                      primaryLabel: l10n.t('truthRaiseAnswer'),
                      onPrimaryTap: _answer,
                    ),
                  ] else ...[
                    Text(
                      l10n.t('truthRaiseSettlement'),
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
                              style: const TextStyle(color: AppColors.bombRed),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    GameResultTemplateCard(
                      accentColor: AppColors.bombRed,
                      resultTitle: l10n.t('resultSummary'),
                      resultText: l10n.t('truthRaiseSettlement'),
                      penaltyTitle: l10n.punishment,
                      penaltyText: _resultPenaltyText(l10n),
                    ),
                    const Spacer(),
                    GameResultActionBar(
                      accentColor: AppColors.bombRed,
                      primaryLabel: l10n.t('truthRaiseBackToSetup'),
                      onPrimaryTap: () =>
                          setState(() => _phase = _TruthPhase.setup),
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
              top: 16,
              right: 24,
              child: SafeArea(
                child: GameHelpButton(
                  onTap: _showGameHelp,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
