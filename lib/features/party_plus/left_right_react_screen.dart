import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/haptics/haptic_service.dart';
import '../../l10n/app_localizations.dart';
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
  bool _awaitingSwipe = false;
  DateTime? _swipeStart;
  String _status = '';
  _ReactPhase _phase = _ReactPhase.setup;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
      _status = '';
    });
    _prepareRound();
  }

  void _prepareRound() {
    setState(() {
      _target = _random.nextBool() ? SwipeDirection.left : SwipeDirection.right;
      _awaitingSwipe = false;
      _status = '';
    });
  }

  void _beginSwipeWindow() {
    _timer?.cancel();
    HapticService.lightImpact();
    setState(() {
      _awaitingSwipe = true;
      _swipeStart = DateTime.now();
      _status = '';
    });

    _timer = Timer(const Duration(milliseconds: 1800), () {
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
    final resolution = resolveReaction(target: _target, actual: dir);

    setState(() {
      _awaitingSwipe = false;
      _penalties[_currentPlayer] += resolution.penaltyDelta;
      if (resolution.success) {
        HapticService.notificationSuccess();
        _status = l10n.t('leftRightSuccessMs', {'ms': '$reaction'});
      } else {
        HapticService.errorVibrate();
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
                    l10n.t('leftRight'),
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
                  onChanged: (v) => setState(() => _playerCount = v.round()),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.t('leftRightRule'),
                  style: const TextStyle(color: AppColors.textSecondary),
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
                    border:
                        Border.all(color: AppColors.wheelOrange.withAlpha(160)),
                  ),
                  child: Text(
                    l10n.t('leftRightSwipeTo', {
                      'direction': _target == SwipeDirection.left
                          ? l10n.t('directionLeft')
                          : l10n.t('directionRight'),
                    }),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity.abs() < 120) return;
                      _handleSwipe(
                        velocity > 0
                            ? SwipeDirection.right
                            : SwipeDirection.left,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: AppColors.surfaceVariant,
                        border: Border.all(color: AppColors.textDim),
                      ),
                      child: Center(
                        child: Icon(
                          _target == SwipeDirection.left
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          color: AppColors.wheelOrange,
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
                  OutlinedButton(
                    onPressed: null,
                    child: Text(l10n.t('leftRightWaitingSwipe')),
                  )
                else if (_status.isEmpty)
                  ElevatedButton(
                    onPressed: _beginSwipeWindow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.wheelOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.t('leftRightBeginReaction')),
                  )
                else
                  ElevatedButton(
                    onPressed: _nextTurn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.wheelOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.t('nextPlayer')),
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
                          style: const TextStyle(color: AppColors.wheelOrange),
                        ),
                      ],
                    ),
                  );
                }),
                const Spacer(),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.wheelOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.t('playAgain')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
