import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/haptics/haptic_service.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';
import 'logic/challenge_auction_logic.dart';
import 'party_plus_strings.dart';

class _ChallengeItem {
  const _ChallengeItem({
    required this.textKey,
    required this.minBid,
  });

  final String textKey;
  final int minBid;
}

enum _AuctionPhase { setup, bidding, verdict, result }

class ChallengeAuctionScreen extends ConsumerStatefulWidget {
  const ChallengeAuctionScreen({super.key});

  @override
  ConsumerState<ChallengeAuctionScreen> createState() =>
      _ChallengeAuctionScreenState();
}

class _ChallengeAuctionScreenState
    extends ConsumerState<ChallengeAuctionScreen> {
  static const _challenges = <_ChallengeItem>[
    _ChallengeItem(textKey: 'challengeAuctionItem1', minBid: 1),
    _ChallengeItem(textKey: 'challengeAuctionItem2', minBid: 2),
    _ChallengeItem(textKey: 'challengeAuctionItem3', minBid: 2),
    _ChallengeItem(textKey: 'challengeAuctionItem4', minBid: 1),
    _ChallengeItem(textKey: 'challengeAuctionItem5', minBid: 3),
  ];

  final Random _random = Random();

  int _playerCount = 4;
  int _biddingPlayer = 0;
  int _currentBid = 2;

  _AuctionPhase _phase = _AuctionPhase.setup;
  _ChallengeItem? _challenge;
  List<int> _bids = [];
  int _winner = 0;
  String _resultText = '';

  void _startRound() {
    final challenge = _challenges[_random.nextInt(_challenges.length)];
    setState(() {
      _phase = _AuctionPhase.bidding;
      _challenge = challenge;
      _bids = List<int>.filled(_playerCount, 0);
      _biddingPlayer = 0;
      _currentBid = challenge.minBid;
      _winner = 0;
      _resultText = '';
    });
  }

  void _submitBid() {
    HapticService.selectionClick();
    _bids[_biddingPlayer] = _currentBid;
    if (_biddingPlayer < _playerCount - 1) {
      setState(() {
        _biddingPlayer += 1;
        _currentBid = _challenge?.minBid ?? 1;
      });
      return;
    }

    final resolution = resolveAuctionWinner(
      bids: _bids,
      random: _random,
    );

    setState(() {
      _winner = resolution.winnerIndex;
      _phase = _AuctionPhase.verdict;
    });
  }

  void _onChallengeSuccess() {
    final l10n = AppLocalizations.of(context);
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    setState(() {
      _phase = _AuctionPhase.result;
      _resultText = settings.alcoholPenaltyEnabled
          ? l10n.t('challengeAuctionResultSuccessAlcohol', {
              'player': PartyPlusStrings.player(context, _winner),
            })
          : l10n.t('challengeAuctionResultSuccessPure', {
              'player': PartyPlusStrings.player(context, _winner),
            });
    });
  }

  void _onChallengeFail() {
    final l10n = AppLocalizations.of(context);
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    final bid = _bids[_winner];
    setState(() {
      _phase = _AuctionPhase.result;
      _resultText = settings.alcoholPenaltyEnabled
          ? l10n.t('challengeAuctionResultFailAlcohol', {
              'player': PartyPlusStrings.player(context, _winner),
              'count': '${bid + 1}',
            })
          : l10n.t('challengeAuctionResultFailPure', {
              'player': PartyPlusStrings.player(context, _winner),
              'count': '${bid + 1}',
            });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final challengeText =
        _challenge == null ? '-' : l10n.t(_challenge!.textKey);

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
                    l10n.t('challengeAuction'),
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
              if (_phase == _AuctionPhase.setup) ...[
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
                const SizedBox(height: 6),
                Text(
                  settings.alcoholPenaltyEnabled
                      ? l10n.t('challengeAuctionRule')
                      : l10n.t('challengeAuctionRulePure'),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _startRound,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.wheelOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.t('challengeAuctionStart')),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.wheelOrange.withAlpha(120)),
                  ),
                  child: Text(
                    challengeText,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                if (_phase == _AuctionPhase.bidding) ...[
                  Text(
                    l10n.t('challengeAuctionBidPrompt', {
                      'player':
                          PartyPlusStrings.player(context, _biddingPlayer),
                    }),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => setState(
                            () => _currentBid = max(1, _currentBid - 1)),
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppColors.wheelOrange),
                      ),
                      Text(
                        settings.alcoholPenaltyEnabled
                            ? l10n.t('challengeAuctionBidCount', {
                                'count': '$_currentBid',
                              })
                            : l10n.pointsCount(_currentBid),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(
                            () => _currentBid = min(8, _currentBid + 1)),
                        icon: const Icon(Icons.add_circle_outline,
                            color: AppColors.wheelOrange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.t('challengeAuctionBidsProgress', {
                      'current': '$_biddingPlayer',
                      'total': '$_playerCount',
                    }),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _submitBid,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.wheelOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.t('challengeAuctionConfirmBid')),
                  ),
                ] else if (_phase == _AuctionPhase.verdict) ...[
                  Text(
                    settings.alcoholPenaltyEnabled
                        ? l10n.t('challengeAuctionWinner', {
                            'player': PartyPlusStrings.player(context, _winner),
                            'bid': '${_bids[_winner]}',
                          })
                        : l10n.t('challengeAuctionWinnerPure', {
                            'player': PartyPlusStrings.player(context, _winner),
                            'bid': '${_bids[_winner]}',
                          }),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_bids.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${PartyPlusStrings.player(context, i)}: ${_bids[i]}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _onChallengeFail,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: AppColors.bombRed.withAlpha(180)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            l10n.t('challengeAuctionFailed'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _onChallengeSuccess,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.wheelOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(l10n.t('challengeAuctionSucceeded')),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Spacer(),
                  Text(
                    _resultText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _startRound,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.wheelOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.t('challengeAuctionNext')),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
