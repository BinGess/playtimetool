import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/help/game_help_service.dart';
import '../../core/haptics/haptic_service.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/game_result_action_bar.dart';
import '../../shared/widgets/game_result_template_card.dart';
import '../../shared/widgets/game_stage_stepper.dart';
import '../../shared/widgets/web3_game_background.dart';
import 'logic/timed_round_logic.dart';
import 'party_plus_strings.dart';

class _WordCategory {
  const _WordCategory({
    required this.nameKey,
    required this.wordsKey,
  });

  final String nameKey;
  final String wordsKey;
}

class WordChainBombScreen extends ConsumerStatefulWidget {
  const WordChainBombScreen({super.key});

  @override
  ConsumerState<WordChainBombScreen> createState() =>
      _WordChainBombScreenState();
}

class _WordChainBombScreenState extends ConsumerState<WordChainBombScreen> {
  static const _categories = <_WordCategory>[
    _WordCategory(
      nameKey: 'wordBombCategoryFood',
      wordsKey: 'wordBombFoodWords',
    ),
    _WordCategory(
      nameKey: 'wordBombCategoryMovie',
      wordsKey: 'wordBombMovieWords',
    ),
    _WordCategory(
      nameKey: 'wordBombCategoryTravel',
      wordsKey: 'wordBombTravelWords',
    ),
    _WordCategory(
      nameKey: 'wordBombCategoryAnimal',
      wordsKey: 'wordBombAnimalWords',
    ),
    _WordCategory(
      nameKey: 'wordBombCategorySport',
      wordsKey: 'wordBombSportWords',
    ),
  ];

  final Random _random = Random();
  Timer? _timer;

  int _playerCount = 4;
  int _holderIndex = 0;
  int _categoryIndex = 0;
  int _roundSeconds = 15;
  int _remainingMs = 0;
  bool _running = false;
  bool _exploded = false;
  String _starterWord = '';
  String _penalty = '';
  bool _showHelpButton = false;

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

  void _startRound() {
    _timer?.cancel();
    final l10n = AppLocalizations.of(context);
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    final category = _categories[_categoryIndex];
    final starters = l10n.t(category.wordsKey).split('|');
    final round = createTimedHolderRound(
      playerCount: _playerCount,
      minDuration: 12,
      maxDuration: 20,
      random: _random,
    );

    setState(() {
      _roundSeconds = round.durationSeconds;
      _remainingMs = round.durationSeconds * 1000;
      _holderIndex = round.holderIndex;
      _starterWord = pickRandomWord(starters, _random);
      _penalty = PartyPlusStrings.randomPenalty(
        context,
        _random,
        alcoholPenaltyEnabled: settings.alcoholPenaltyEnabled,
      );
      _running = true;
      _exploded = false;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      final next = _remainingMs - 100;
      if (next <= 0) {
        timer.cancel();
        HapticService.tripleHeavyImpact();
        setState(() {
          _remainingMs = 0;
          _running = false;
          _exploded = true;
        });
      } else {
        setState(() => _remainingMs = next);
      }
    });
  }

  void _nextPlayer() {
    if (!_running) return;
    setState(() => _holderIndex = (_holderIndex + 1) % _playerCount);
    HapticService.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stage = _running
        ? GameStage.playing
        : (_exploded ? GameStage.result : GameStage.prepare);
    final category = _categories[_categoryIndex];
    final categoryName = l10n.t(category.nameKey);
    final progress = _roundSeconds == 0
        ? 0.0
        : (_remainingMs / (_roundSeconds * 1000)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Web3GameBackground(
            accentColor: AppColors.fingerCyan,
            secondaryColor: AppColors.bombRed,
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
                            color: AppColors.textDim, size: 20),
                      ),
                      const Spacer(),
                      Text(
                        l10n.t('wordBomb'),
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
                      accentColor: AppColors.fingerCyan,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.playersCount(_playerCount),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  Slider(
                    value: _playerCount.toDouble(),
                    min: 3,
                    max: 6,
                    divisions: 3,
                    activeColor: AppColors.fingerCyan,
                    onChanged: _running
                        ? null
                        : (v) => setState(() => _playerCount = v.round()),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _categoryIndex,
                    dropdownColor: AppColors.surface,
                    decoration: InputDecoration(
                      labelText: l10n.t('wordBombCategory'),
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.textDim),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.fingerCyan),
                      ),
                    ),
                    items: List.generate(_categories.length, (i) {
                      final c = _categories[i];
                      return DropdownMenuItem(
                        value: i,
                        child: Text(
                          l10n.t(c.nameKey),
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }),
                    onChanged: _running
                        ? null
                        : (v) => setState(() => _categoryIndex = v ?? 0),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.surfaceVariant,
                      border: Border.all(
                          color: AppColors.fingerCyan.withAlpha(120)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.t('wordBombCategoryLine',
                              {'category': categoryName}),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _starterWord.isEmpty
                              ? l10n.t('wordBombStarterPending')
                              : l10n.t('wordBombStarterLine', {
                                  'word': _starterWord,
                                }),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.fingerCyan,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_running)
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.fingerCyan),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: _exploded
                          ? GameResultTemplateCard(
                              accentColor: AppColors.fingerCyan,
                              resultTitle: l10n.t('resultSummary'),
                              resultText: l10n.t('wordBombExploded', {
                                'player': PartyPlusStrings.player(
                                    context, _holderIndex),
                                'penalty': _penalty,
                              }),
                              penaltyTitle: l10n.punishment,
                              penaltyText: _penalty,
                            )
                          : Text(
                              PartyPlusStrings.player(context, _holderIndex),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  if (_exploded)
                    GameResultActionBar(
                      accentColor: AppColors.fingerCyan,
                      primaryLabel: l10n.t('wordBombNext'),
                      onPrimaryTap: _startRound,
                    )
                  else
                    GameResultActionBar(
                      accentColor: AppColors.fingerCyan,
                      primaryLabel: _running
                          ? l10n.t('wordBombNext')
                          : l10n.t('startGame'),
                      onPrimaryTap: _running ? _nextPlayer : _startRound,
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
        gameId: 'word_bomb',
        gameTitle: l10n.t('wordBomb'),
        helpBody: l10n.t('helpWordBombBody'),
      );
      if (mounted) setState(() => _showHelpButton = true);
    });
  }

  void _showGameHelp() {
    final l10n = AppLocalizations.of(context);
    GameHelpService.showGameHelpDialog(
      context,
      gameTitle: l10n.t('wordBomb'),
      helpBody: l10n.t('helpWordBombBody'),
    );
  }
}
