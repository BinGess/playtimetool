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

class BombPassScreen extends ConsumerStatefulWidget {
  const BombPassScreen({super.key});

  @override
  ConsumerState<BombPassScreen> createState() => _BombPassScreenState();
}

class _BombPassScreenState extends ConsumerState<BombPassScreen> {
  final Random _random = Random();
  Timer? _timer;

  int _playerCount = 4;
  int _holderIndex = 0;
  int _roundSeconds = 10;
  int _remainingMs = 0;
  bool _running = false;
  bool _exploded = false;
  String _penalty = '';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRound() {
    _timer?.cancel();
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
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
    final progress = _roundSeconds == 0
        ? 0.0
        : (_remainingMs / (_roundSeconds * 1000)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.bombBlueDark,
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
                    l10n.t('passBomb'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                l10n.playersCount(_playerCount),
                style: const TextStyle(color: AppColors.textSecondary),
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
              const SizedBox(height: 8),
              if (_running)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t(
                        'passBombSecondsLeft',
                        {'seconds': '${(progress * _roundSeconds).ceil()}'},
                      ),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      minHeight: 8,
                      value: progress,
                      borderRadius: BorderRadius.circular(6),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.bombRed),
                      backgroundColor: AppColors.surfaceVariant,
                    ),
                  ],
                ),
              const SizedBox(height: 28),
              Expanded(
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.bombRed.withAlpha(_running ? 220 : 100),
                          AppColors.bombRedDark,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.bombRed.withAlpha(_running ? 160 : 80),
                          blurRadius: _running ? 26 : 12,
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
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            PartyPlusStrings.player(context, _holderIndex),
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
              if (_exploded)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.bombRed.withAlpha(160)),
                  ),
                  child: Text(
                    l10n.t('penaltyResult', {
                      'player': PartyPlusStrings.player(context, _holderIndex),
                      'penalty': _penalty,
                    }),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _running ? null : _startRound,
                      style: OutlinedButton.styleFrom(
                        side:
                            BorderSide(color: AppColors.bombRed.withAlpha(180)),
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
                      onPressed: _running ? _passBomb : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bombRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.t('passBombPassButton')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
