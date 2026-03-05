import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/haptics/haptic_service.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';
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
    final category = _categories[_categoryIndex];
    final categoryName = l10n.t(category.nameKey);
    final progress = _roundSeconds == 0
        ? 0.0
        : (_remainingMs / (_roundSeconds * 1000)).clamp(0.0, 1.0);

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
                    l10n.t('wordBomb'),
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
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
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
                  border:
                      Border.all(color: AppColors.fingerCyan.withAlpha(120)),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.t(
                          'wordBombCategoryLine', {'category': categoryName}),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _starterWord.isEmpty
                          ? l10n.t('wordBombStarterPending')
                          : l10n.t('wordBombStarterLine', {
                              'word': _starterWord,
                            }),
                      style: const TextStyle(color: AppColors.fingerCyan),
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
                  child: Text(
                    _exploded
                        ? l10n.t('wordBombExploded', {
                            'player':
                                PartyPlusStrings.player(context, _holderIndex),
                            'penalty': _penalty,
                          })
                        : PartyPlusStrings.player(context, _holderIndex),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _exploded ? AppColors.bombRed : Colors.white,
                      fontSize: _exploded ? 22 : 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _running ? null : _startRound,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.fingerCyan.withAlpha(160)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        _exploded ? l10n.t('nextRound') : l10n.t('startTimer'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _running ? _nextPlayer : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.fingerCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.t('wordBombNext')),
                    ),
                  ),
                ],
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
        ],
      ),
    );
  }
}
