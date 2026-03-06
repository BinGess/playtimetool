import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/help/game_help_service.dart';
import '../../core/haptics/haptic_service.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/services/penalty_service.dart';
import '../../shared/widgets/penalty_blind_box_overlay.dart';
import '../../shared/widgets/penalty_preset_card.dart';
import '../../shared/widgets/game_result_action_bar.dart';
import '../../shared/widgets/game_result_template_card.dart';
import '../../shared/styles/game_ui_style.dart';
import '../../shared/widgets/web3_game_background.dart';
import 'logic/gesture_duel_logic.dart';
import 'party_plus_strings.dart';

enum _DuelPhase { setup, picking, roundResult, finalResult }

class GestureDuelScreen extends ConsumerStatefulWidget {
  const GestureDuelScreen({super.key});

  @override
  ConsumerState<GestureDuelScreen> createState() => _GestureDuelScreenState();
}

class _GestureDuelScreenState extends ConsumerState<GestureDuelScreen> {
  final Random _random = Random();

  int _playerCount = 4;
  int _currentPlayer = 0;
  bool _minorityLoses = true;
  _DuelPhase _phase = _DuelPhase.setup;

  int _totalRounds = 4;
  int _round = 0;
  List<int> _scores = [];

  List<DuelGesture?> _picks = [];
  List<int> _losers = [];
  String _resultText = '';
  bool _showHelpButton = false;
  bool _isPickFeedbackActive = false;
  DuelGesture? _tappedGesture;
  PenaltyPreset _penaltyPreset = PenaltyPreset.defaults;
  PenaltyBlindBoxResult? _blindBoxResult;

  @override
  void initState() {
    super.initState();
    _initGameHelp();
  }

  void _startGame() {
    setState(() {
      _round = 0;
      _scores = List<int>.filled(_playerCount, 0);
      _blindBoxResult = null;
    });
    _startRound();
  }

  void _startRound() {
    setState(() {
      _phase = _DuelPhase.picking;
      _round += 1;
      _currentPlayer = 0;
      _picks = List<DuelGesture?>.filled(_playerCount, null);
      _losers = [];
      _resultText = '';
      _isPickFeedbackActive = false;
      _tappedGesture = null;
    });
  }

  Future<void> _pick(DuelGesture gesture) async {
    if (_isPickFeedbackActive) return;
    HapticService.selectionClick();
    setState(() {
      _isPickFeedbackActive = true;
      _tappedGesture = gesture;
    });

    await Future<void>.delayed(const Duration(milliseconds: 110));
    if (!mounted) return;

    _picks[_currentPlayer] = gesture;

    if (_currentPlayer < _playerCount - 1) {
      setState(() {
        _currentPlayer += 1;
        _isPickFeedbackActive = false;
        _tappedGesture = null;
      });
      return;
    }

    setState(() {
      _isPickFeedbackActive = false;
      _tappedGesture = null;
    });
    _resolveRound();
  }

  void _resolveRound() {
    final l10n = AppLocalizations.of(context);

    final picks = _picks.whereType<DuelGesture>().toList();
    final resolution = resolveGestureDuel(
      picks: picks,
      minorityLoses: _minorityLoses,
    );

    _losers = resolution.losers;

    // Award +1 to each loser (unless draw with no real losers)
    if (!resolution.isDraw && _losers.isNotEmpty) {
      for (final i in _losers) {
        _scores[i] += 1;
      }
      final names =
          _losers.map((i) => PartyPlusStrings.player(context, i)).join('、');
      _resultText = l10n.t('gestureRoundScore', {'players': names});
    } else if (resolution.isDraw && resolution.losers.isEmpty) {
      _resultText = l10n.t('gestureSameDraw');
    } else if (resolution.isDraw && resolution.losers.length == _playerCount) {
      _resultText = l10n.t('gestureEveryoneHitDraw');
    } else {
      _resultText = l10n.t('gestureNoLoserDraw');
    }

    setState(() {
      _phase = _DuelPhase.roundResult;
    });
  }

  void _proceedAfterRound() {
    if (_round >= _totalRounds) {
      _showFinalResult();
    } else {
      _startRound();
    }
  }

  void _showFinalResult() {
    final l10n = AppLocalizations.of(context);
    final settings = ref.read(settingsProvider).value ?? const AppSettings();

    final maxScore = _scores.reduce(max);
    final losers = <int>[];
    for (int i = 0; i < _playerCount; i++) {
      if (_scores[i] == maxScore && maxScore > 0) {
        losers.add(i);
      }
    }

    _losers = losers;

    if (losers.isEmpty) {
      _blindBoxResult = null;
      _resultText = PenaltyService.guidancePlan(
        l10n: l10n,
        guide: PenaltyGuideType.defaultGuide,
      ).text;
    } else {
      final names = losers.map((i) => PartyPlusStrings.player(context, i));
      _blindBoxResult = PenaltyService.resolveBlindBox(
        l10n: l10n,
        random: _random,
        preset: _penaltyPreset,
        losers: names.toList(),
      );
      final penalty = PartyPlusStrings.randomPenalty(
        context,
        _random,
        alcoholPenaltyEnabled: settings.alcoholPenaltyEnabled,
      );
      _resultText = PenaltyService.actionPlan(
        l10n: l10n,
        players: names.toList(),
        actionText: penalty,
      ).text;
    }

    setState(() {
      _phase = _DuelPhase.finalResult;
    });
  }

  String _label(DuelGesture gesture, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (gesture) {
      case DuelGesture.rock:
        return l10n.t('gestureRock');
      case DuelGesture.paper:
        return l10n.t('gesturePaper');
      case DuelGesture.scissors:
        return l10n.t('gestureScissors');
    }
  }

  IconData _icon(DuelGesture gesture) {
    switch (gesture) {
      case DuelGesture.rock:
        return Icons.circle;
      case DuelGesture.paper:
        return Icons.crop_5_4;
      case DuelGesture.scissors:
        return Icons.content_cut;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Web3GameBackground(
            accentColor: AppColors.fingerCyan,
            secondaryColor: AppColors.wheelOrange,
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
                        l10n.t('gestureDuel'),
                        style: GameUiText.navTitle,
                      ),
                      const Spacer(),
                      const SizedBox(width: 20),
                    ],
                  ),
                  const SizedBox(height: GameUiSpacing.topGap),
                  const SizedBox(height: GameUiSpacing.sectionGap),
                  if (_phase == _DuelPhase.setup) ...[
                    Text(
                      l10n.playersCount(_playerCount),
                      style: GameUiText.body,
                    ),
                    Slider(
                      value: _playerCount.toDouble(),
                      min: 3,
                      max: 6,
                      divisions: 3,
                      activeColor: AppColors.fingerCyan,
                      onChanged: (v) =>
                          setState(() => _playerCount = v.round()),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.t('gestureRoundsSetting', {
                        'count': '$_totalRounds',
                      }),
                      style: GameUiText.body,
                    ),
                    Slider(
                      value: _totalRounds.toDouble(),
                      min: 1,
                      max: 12,
                      divisions: 11,
                      activeColor: AppColors.fingerCyan,
                      onChanged: (v) =>
                          setState(() => _totalRounds = v.round()),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text(
                        _minorityLoses
                            ? l10n.t('gestureModeMinority')
                            : l10n.t('gestureModeMajority'),
                        style: GameUiText.bodyStrong,
                      ),
                      value: _minorityLoses,
                      onChanged: (v) => setState(() => _minorityLoses = v),
                      activeTrackColor: AppColors.fingerCyan,
                      thumbColor: WidgetStateProperty.all(AppColors.fingerCyan),
                    ),
                    const SizedBox(height: 12),
                    PenaltyPresetCard(
                      preset: _penaltyPreset,
                      accentColor: AppColors.fingerCyan,
                      onChanged: (preset) {
                        setState(() => _penaltyPreset = preset);
                      },
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.fingerCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: GameUiText.buttonLabel,
                      ),
                      child: Text(l10n.t('gestureStartDuel')),
                    ),
                  ] else if (_phase == _DuelPhase.picking) ...[
                    Text(
                      l10n.t('gestureRoundOf', {
                        'current': '$_round',
                        'total': '$_totalRounds',
                      }),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.fingerCyan,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.fingerCyan.withAlpha(120)),
                      ),
                      child: Text(
                        l10n.t('gesturePassToPick', {
                          'player':
                              PartyPlusStrings.player(context, _currentPlayer),
                        }),
                        style: GameUiText.bodyStrong,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...DuelGesture.values.map((g) {
                      final isTapped = _tappedGesture == g;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _pick(g),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(68),
                              alignment: Alignment.centerLeft,
                              backgroundColor: isTapped
                                  ? AppColors.fingerCyan.withAlpha(46)
                                  : AppColors.surfaceVariant.withAlpha(24),
                              overlayColor: AppColors.fingerCyan.withAlpha(28),
                              side: BorderSide(
                                color: isTapped
                                    ? AppColors.fingerCyan
                                    : AppColors.fingerCyan.withAlpha(170),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 18,
                              ),
                            ),
                            icon: Icon(_icon(g), color: AppColors.fingerCyan),
                            label: Text(
                              _label(g, context),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const Spacer(),
                    Text(
                      l10n.doneProgress(_currentPlayer, _playerCount),
                      textAlign: TextAlign.center,
                      style: GameUiText.body,
                    ),
                  ] else if (_phase == _DuelPhase.roundResult) ...[
                    Text(
                      l10n.t('gestureRoundOf', {
                        'current': '$_round',
                        'total': '$_totalRounds',
                      }),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.fingerCyan,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('gestureRoundResult'),
                      textAlign: TextAlign.center,
                      style: GameUiText.sectionTitle,
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_picks.length, (i) {
                      final pick = _picks[i];
                      final hit = _losers.contains(i);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: hit
                              ? AppColors.bombRed.withAlpha(30)
                              : AppColors.surfaceVariant,
                          border: Border.all(
                            color: hit ? AppColors.bombRed : AppColors.textDim,
                          ),
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
                              pick == null ? '-' : _label(pick, context),
                              style: TextStyle(
                                color: hit
                                    ? AppColors.bombRed
                                    : AppColors.fingerCyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_scores[i]}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    Text(
                      _resultText,
                      textAlign: TextAlign.center,
                      style: GameUiText.bodyStrong.copyWith(fontSize: 15),
                    ),
                    const Spacer(),
                    GameResultActionBar(
                      accentColor: AppColors.fingerCyan,
                      primaryLabel: _round >= _totalRounds
                          ? l10n.t('gestureFinalResult')
                          : l10n.t('nextRound'),
                      onPrimaryTap: _proceedAfterRound,
                    ),
                  ] else ...[
                    // finalResult phase
                    Text(
                      l10n.t('gestureFinalResult'),
                      textAlign: TextAlign.center,
                      style: GameUiText.sectionTitle,
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_playerCount, (i) {
                      final hit = _losers.contains(i);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: hit
                              ? AppColors.bombRed.withAlpha(30)
                              : AppColors.surfaceVariant,
                          border: Border.all(
                            color: hit ? AppColors.bombRed : AppColors.textDim,
                          ),
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
                              '${_scores[i]}',
                              style: TextStyle(
                                color: hit
                                    ? AppColors.bombRed
                                    : AppColors.fingerCyan,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    if (_blindBoxResult == null)
                      GameResultTemplateCard(
                        accentColor: AppColors.fingerCyan,
                        resultTitle: l10n.t('resultSummary'),
                        resultText: l10n.t('gestureFinalResult'),
                        penaltyTitle: l10n.punishment,
                        penaltyText: _resultText,
                      )
                    else
                      PenaltyBlindBoxOverlay(result: _blindBoxResult!),
                    const Spacer(),
                    GameResultActionBar(
                      accentColor: AppColors.fingerCyan,
                      primaryLabel: l10n.t('gestureStartDuel'),
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
        gameId: 'gesture_duel',
        gameTitle: l10n.t('gestureDuel'),
        helpBody: l10n.t('helpGestureDuelBody'),
      );
      if (mounted) setState(() => _showHelpButton = true);
    });
  }

  void _showGameHelp() {
    final l10n = AppLocalizations.of(context);
    GameHelpService.showGameHelpDialog(
      context,
      gameTitle: l10n.t('gestureDuel'),
      helpBody: l10n.t('helpGestureDuelBody'),
    );
  }
}
