import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/help/game_help_service.dart';
import '../../core/haptics/haptic_service.dart';
import '../../features/penalty_plugin/application/penalty_resolver.dart';
import '../../features/penalty_plugin/application/penalty_runtime.dart';
import '../../features/penalty_plugin/domain/penalty_models.dart';
import '../../features/penalty_plugin/domain/penalty_policy.dart';
import '../../features/penalty_plugin/presentation/penalty_picker_sheet.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';
import 'logic/truth_raise_logic.dart';
import 'party_plus_strings.dart';

enum _TruthPhase { setup, playing, result }

class TruthOrRaiseScreen extends ConsumerStatefulWidget {
  const TruthOrRaiseScreen({super.key});

  @override
  ConsumerState<TruthOrRaiseScreen> createState() => _TruthOrRaiseScreenState();
}

class _TruthOrRaiseScreenState extends ConsumerState<TruthOrRaiseScreen> {
  final Random _random = Random();
  final Set<int> _usedQuestions = {};

  int _playerCount = 4;
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
  PenaltyResolution? _penaltyResolution;
  PenaltyItem? _selectedPenalty;
  String _resultPenaltyText = '';
  List<int> _resultLosers = const [];

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

  void _startGame() {
    _usedQuestions.clear();
    setState(() {
      _phase = _TruthPhase.playing;
      _currentPlayer = 0;
      _round = 1;
      _totalRounds = _playerCount * 2;
      _raiseLevel = 0;
      _lastAction = '';
      _penalties = List<int>.filled(_playerCount, 0);
      _question = _randomQuestion();
      _penaltyResolution = null;
      _selectedPenalty = null;
      _resultPenaltyText = '';
      _resultLosers = const [];
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
      _prepareResultPenalty();
      setState(() => _phase = _TruthPhase.result);
      return;
    }

    setState(() {
      _round += 1;
      _currentPlayer = (_currentPlayer + 1) % _playerCount;
      _question = _randomQuestion();
    });
  }

  void _prepareResultPenalty() {
    final l10n = AppLocalizations.of(context);
    final maxPenalty = _penalties.isEmpty ? 0 : _penalties.reduce(max);
    if (maxPenalty <= 0) {
      _penaltyResolution = null;
      _selectedPenalty = null;
      _resultPenaltyText = '';
      _resultLosers = const [];
      return;
    }

    final losers = <int>[];
    for (int i = 0; i < _penalties.length; i++) {
      if (_penalties[i] == maxPenalty) losers.add(i);
    }

    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    final names =
        losers.map((i) => PartyPlusStrings.player(context, i)).join('、');
    final resolution = defaultPenaltyResolver.resolve(
      policy: penaltyPolicyFromSettings(settings),
      context: PenaltyContext(
        gameId: 'truth_raise',
        loserCount: losers.length,
        round: _round,
      ),
      random: _random,
    );
    _penaltyResolution = resolution;
    _selectedPenalty = resolution.selected;
    _resultPenaltyText = l10n.t('gesturePenaltyResult', {
      'players': names,
      'penalty': l10n.t(resolution.selected.textKey),
    });
    _resultLosers = losers;
  }

  Future<void> _openPenaltyPicker() async {
    if (_penaltyResolution == null || _selectedPenalty == null) return;
    final l10n = AppLocalizations.of(context);
    final selected = await showPenaltyPickerSheet(
      context,
      candidates: _penaltyResolution!.candidates,
      selected: _selectedPenalty!,
      labelBuilder: (item) => l10n.t(item.textKey),
    );
    if (selected == null || !mounted) return;
    final names =
        _resultLosers.map((i) => PartyPlusStrings.player(context, i)).join('、');
    setState(() {
      _selectedPenalty = selected;
      _resultPenaltyText = l10n.t('gesturePenaltyResult', {
        'players': names,
        'penalty': l10n.t(selected.textKey),
      });
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scaleConfig = _scaleConfig;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
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
                            color: AppColors.textDim, size: 20),
                      ),
                      const Spacer(),
                      Text(
                        l10n.t('truthRaise'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 20),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (_phase == _TruthPhase.setup) ...[
                    Text(
                      l10n.t('truthRaiseSetupTitle'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.playersCount(_playerCount),
                      style: const TextStyle(color: AppColors.textSecondary),
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
                      l10n.t('truthRaiseScaleTitle'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TruthRaiseScaleLevel.values.map((scale) {
                        final isSelected = scale == _selectedScale;
                        return ChoiceChip(
                          label: Text(_scaleTitle(l10n, scale)),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedScale = scale),
                          selectedColor: AppColors.bombRed,
                          backgroundColor: AppColors.surfaceVariant,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.bombRed
                                : AppColors.textSecondary.withAlpha(100),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.t('truthRaiseScaleHint', {
                        'step': '${scaleConfig.step}',
                        'max': '${scaleConfig.maxRaise}',
                      }),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('truthRaiseRule'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bombRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.start),
                    ),
                  ] else if (_phase == _TruthPhase.playing) ...[
                    Text(
                      l10n.roundProgress(_round, _totalRounds),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
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
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
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
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    if (_lastAction.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _lastAction,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _skipAndRaise,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: AppColors.bombRed.withAlpha(180)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              l10n.t('truthRaiseSkipRaise'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _answer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bombRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(l10n.t('truthRaiseAnswer')),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      l10n.t('truthRaiseSettlement'),
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
                              style: const TextStyle(color: AppColors.bombRed),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_resultPenaltyText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _resultPenaltyText,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      if (_penaltyResolution != null &&
                          _selectedPenalty != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton(
                            key: const Key('open-penalty-picker'),
                            onPressed: _openPenaltyPicker,
                            child: Text(l10n.t('penaltyChoose')),
                          ),
                        ),
                    ],
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () =>
                          setState(() => _phase = _TruthPhase.setup),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bombRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.t('truthRaiseBackToSetup')),
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
