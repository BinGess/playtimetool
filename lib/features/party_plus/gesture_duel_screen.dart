import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/haptics/haptic_service.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';
import 'logic/gesture_duel_logic.dart';
import 'party_plus_strings.dart';

enum _DuelPhase { setup, picking, result }

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

  List<DuelGesture?> _picks = [];
  List<int> _losers = [];
  String _resultText = '';

  void _startRound() {
    setState(() {
      _phase = _DuelPhase.picking;
      _currentPlayer = 0;
      _picks = List<DuelGesture?>.filled(_playerCount, null);
      _losers = [];
      _resultText = '';
    });
  }

  void _pick(DuelGesture gesture) {
    HapticService.selectionClick();
    _picks[_currentPlayer] = gesture;

    if (_currentPlayer < _playerCount - 1) {
      setState(() => _currentPlayer += 1);
      return;
    }

    _resolveResult();
  }

  void _resolveResult() {
    final l10n = AppLocalizations.of(context);
    final settings = ref.read(settingsProvider).value ?? const AppSettings();

    final picks = _picks.whereType<DuelGesture>().toList();
    final resolution = resolveGestureDuel(
      picks: picks,
      minorityLoses: _minorityLoses,
    );

    setState(() {
      _phase = _DuelPhase.result;
      _losers = resolution.losers;
      if (resolution.isDraw && resolution.losers.isEmpty) {
        _resultText = l10n.t('gestureSameDraw');
      } else if (resolution.isDraw &&
          resolution.losers.length == _playerCount) {
        _resultText = l10n.t('gestureEveryoneHitDraw');
      } else if (resolution.losers.isEmpty) {
        _resultText = l10n.t('gestureNoLoserDraw');
      } else {
        final names = resolution.losers
            .map((i) => PartyPlusStrings.player(context, i))
            .join('、');
        final penalty = PartyPlusStrings.randomPenalty(
          context,
          _random,
          alcoholPenaltyEnabled: settings.alcoholPenaltyEnabled,
        );
        _resultText = l10n.t('gesturePenaltyResult', {
          'players': names,
          'penalty': penalty,
        });
      }
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
      body: SafeArea(
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
                    l10n.t('gestureDuel'),
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
              const SizedBox(height: 24),
              if (_phase == _DuelPhase.setup) ...[
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
                  onChanged: (v) => setState(() => _playerCount = v.round()),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text(
                    _minorityLoses
                        ? l10n.t('gestureModeMinority')
                        : l10n.t('gestureModeMajority'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: _minorityLoses,
                  onChanged: (v) => setState(() => _minorityLoses = v),
                  activeColor: AppColors.fingerCyan,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _startRound,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fingerCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.t('gestureStartDuel')),
                ),
              ] else if (_phase == _DuelPhase.picking) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.fingerCyan.withAlpha(120)),
                  ),
                  child: Text(
                    l10n.t('gesturePassToPick', {
                      'player':
                          PartyPlusStrings.player(context, _currentPlayer),
                    }),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: DuelGesture.values.map((g) {
                    return SizedBox(
                      width: (MediaQuery.sizeOf(context).width - 72) / 2,
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(g),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.fingerCyan.withAlpha(170),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: Icon(_icon(g), color: AppColors.fingerCyan),
                        label: Text(
                          _label(g, context),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Spacer(),
                Text(
                  l10n.doneProgress(_currentPlayer, _playerCount),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ] else ...[
                Text(
                  l10n.t('gestureRoundResult'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
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
                            color:
                                hit ? AppColors.bombRed : AppColors.fingerCyan,
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
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _startRound,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fingerCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.t('nextRound')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
