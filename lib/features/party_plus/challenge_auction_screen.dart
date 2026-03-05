import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/help/game_help_service.dart';
import '../../core/haptics/haptic_service.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/game_result_action_bar.dart';
import '../../shared/widgets/game_result_template_card.dart';
import '../../shared/widgets/web3_game_background.dart';
import '../../shared/services/penalty_service.dart';
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
    _ChallengeItem(textKey: 'challengeAuctionItem6', minBid: 2),
    _ChallengeItem(textKey: 'challengeAuctionItem7', minBid: 1),
    _ChallengeItem(textKey: 'challengeAuctionItem8', minBid: 1),
    _ChallengeItem(textKey: 'challengeAuctionItem9', minBid: 2),
    _ChallengeItem(textKey: 'challengeAuctionItem10', minBid: 3),
    _ChallengeItem(textKey: 'challengeAuctionItem11', minBid: 1),
    _ChallengeItem(textKey: 'challengeAuctionItem12', minBid: 2),
    _ChallengeItem(textKey: 'challengeAuctionItem13', minBid: 2),
    _ChallengeItem(textKey: 'challengeAuctionItem14', minBid: 1),
    _ChallengeItem(textKey: 'challengeAuctionItem15', minBid: 2),
  ];

  final Random _random = Random();
  final TextEditingController _bidController = TextEditingController();
  final FocusNode _bidFocusNode = FocusNode();
  final TextEditingController _minBidController =
      TextEditingController(text: '1');
  final TextEditingController _maxBidController =
      TextEditingController(text: '20');

  int _playerCount = 4;
  int _biddingPlayer = 0;
  int _currentBid = 2;
  int _configuredMinBid = 1;
  int _configuredMaxBid = 20;
  BidRange _currentBidRange = const BidRange(minBid: 1, maxBid: 20);

  _AuctionPhase _phase = _AuctionPhase.setup;
  _ChallengeItem? _challenge;
  List<int> _bids = [];
  int _winner = 0;
  String _resultText = '';
  bool _showHelpButton = false;
  DateTime? _lastBidRangeHintAt;

  @override
  void initState() {
    super.initState();
    _initGameHelp();
  }

  @override
  void dispose() {
    _bidController.dispose();
    _bidFocusNode.dispose();
    _minBidController.dispose();
    _maxBidController.dispose();
    super.dispose();
  }

  void _initGameHelp() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      await GameHelpService.ensureFirstTimeShown(
        context: context,
        gameId: 'challenge_auction',
        gameTitle: l10n.t('challengeAuction'),
        helpBody: l10n.t('helpChallengeAuctionBody'),
      );
      if (mounted) setState(() => _showHelpButton = true);
    });
  }

  void _showGameHelp() {
    final l10n = AppLocalizations.of(context);
    GameHelpService.showGameHelpDialog(
      context,
      gameTitle: l10n.t('challengeAuction'),
      helpBody: l10n.t('helpChallengeAuctionBody'),
    );
  }

  void _focusBidInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _phase != _AuctionPhase.bidding) return;
      _bidFocusNode.requestFocus();
      _bidController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _bidController.text.length,
      );
    });
  }

  void _normalizeConfiguredRangeInputs() {
    final configuredRange = normalizeBidRange(
      configuredMinBid:
          int.tryParse(_minBidController.text.trim()) ?? _configuredMinBid,
      configuredMaxBid:
          int.tryParse(_maxBidController.text.trim()) ?? _configuredMaxBid,
      challengeMinBid: 1,
    );
    setState(() {
      _configuredMinBid = configuredRange.minBid;
      _configuredMaxBid = configuredRange.maxBid;
      _minBidController.text = '$_configuredMinBid';
      _maxBidController.text = '$_configuredMaxBid';
    });
  }

  void _startRound() {
    final challenge = _challenges[_random.nextInt(_challenges.length)];
    final configuredRange = normalizeBidRange(
      configuredMinBid:
          int.tryParse(_minBidController.text.trim()) ?? _configuredMinBid,
      configuredMaxBid:
          int.tryParse(_maxBidController.text.trim()) ?? _configuredMaxBid,
      challengeMinBid: 1,
    );
    final bidRange = normalizeBidRange(
      configuredMinBid: configuredRange.minBid,
      configuredMaxBid: configuredRange.maxBid,
      challengeMinBid: challenge.minBid,
    );
    setState(() {
      _phase = _AuctionPhase.bidding;
      _challenge = challenge;
      _bids = List<int>.filled(_playerCount, 0);
      _biddingPlayer = 0;
      _configuredMinBid = configuredRange.minBid;
      _configuredMaxBid = configuredRange.maxBid;
      _minBidController.text = '$_configuredMinBid';
      _maxBidController.text = '$_configuredMaxBid';
      _currentBidRange = bidRange;
      _currentBid = bidRange.minBid;
      _bidController.text = '$_currentBid';
      _winner = 0;
      _resultText = '';
    });
    _focusBidInput();
  }

  void _submitBid() {
    final l10n = AppLocalizations.of(context);
    final parsedBid = int.tryParse(_bidController.text.trim());
    if (parsedBid == null ||
        parsedBid < _currentBidRange.minBid ||
        parsedBid > _currentBidRange.maxBid) {
      _showBidRangeHint(l10n);
      HapticService.errorVibrate();
      return;
    }

    final normalizedBid = parsedBid;
    HapticService.selectionClick();
    _bids[_biddingPlayer] = normalizedBid;
    if (_biddingPlayer < _playerCount - 1) {
      setState(() {
        _biddingPlayer += 1;
        _currentBid = _currentBidRange.minBid;
        _bidController.text = '$_currentBid';
      });
      _focusBidInput();
      return;
    }

    final resolution = resolveAuctionWinner(
      bids: _bids,
      random: _random,
    );

    setState(() {
      _currentBid = normalizedBid;
      _bidController.text = '$_currentBid';
      _winner = resolution.winnerIndex;
      _phase = _AuctionPhase.verdict;
    });
  }

  void _showBidRangeHint(AppLocalizations l10n) {
    final now = DateTime.now();
    if (_lastBidRangeHintAt != null &&
        now.difference(_lastBidRangeHintAt!) <
            const Duration(milliseconds: 700)) {
      return;
    }
    _lastBidRangeHintAt = now;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.invalidRangeHint(
            _currentBidRange.minBid,
            _currentBidRange.maxBid,
          ),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.bombRed.withAlpha(220),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _onChallengeSuccess() {
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    final l10n = AppLocalizations.of(context);
    final winner = PartyPlusStrings.player(context, _winner);
    setState(() {
      _phase = _AuctionPhase.result;
      _resultText = PenaltyService.challengeAuctionPlan(
        l10n: l10n,
        alcoholPenaltyEnabled: settings.alcoholPenaltyEnabled,
        success: true,
        player: winner,
        bid: _bids[_winner],
      ).text;
    });
  }

  void _onChallengeFail() {
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    final l10n = AppLocalizations.of(context);
    final winner = PartyPlusStrings.player(context, _winner);
    final bid = _bids[_winner];
    setState(() {
      _phase = _AuctionPhase.result;
      _resultText = PenaltyService.challengeAuctionPlan(
        l10n: l10n,
        alcoholPenaltyEnabled: settings.alcoholPenaltyEnabled,
        success: false,
        player: winner,
        bid: bid,
      ).text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final challengeText =
        _challenge == null ? '-' : l10n.t(_challenge!.textKey);
    final winnerSummary = settings.alcoholPenaltyEnabled
        ? l10n.t('challengeAuctionWinner', {
            'player': PartyPlusStrings.player(context, _winner),
            'bid': _bids.isEmpty ? '0' : '${_bids[_winner]}',
          })
        : l10n.t('challengeAuctionWinnerPure', {
            'player': PartyPlusStrings.player(context, _winner),
            'bid': _bids.isEmpty ? '0' : '${_bids[_winner]}',
          });
    final previewBid = _phase == _AuctionPhase.bidding
        ? (int.tryParse(_bidController.text.trim()) ?? _currentBid)
        : _currentBid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Web3GameBackground(
            accentColor: AppColors.wheelOrange,
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
                            color: Colors.white, size: 20),
                      ),
                      const Spacer(),
                      Text(
                        l10n.t('challengeAuction'),
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
                      onChanged: (v) =>
                          setState(() => _playerCount = v.round()),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.t('challengeAuctionBidRangeLabel'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minBidController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: l10n.t('min'),
                              labelStyle: const TextStyle(
                                  color: AppColors.textSecondary),
                              hintText: '1',
                              hintStyle: const TextStyle(
                                  color: AppColors.textSecondary),
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onSubmitted: (_) =>
                                _normalizeConfiguredRangeInputs(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _maxBidController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: l10n.t('max'),
                              labelStyle: const TextStyle(
                                  color: AppColors.textSecondary),
                              hintText: '20',
                              hintStyle: const TextStyle(
                                  color: AppColors.textSecondary),
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onSubmitted: (_) =>
                                _normalizeConfiguredRangeInputs(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('challengeAuctionBidRangeActive', {
                        'min': '$_configuredMinBid',
                        'max': '$_configuredMaxBid',
                      }),
                      style: const TextStyle(color: AppColors.textSecondary),
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
                        border: Border.all(
                            color: AppColors.wheelOrange.withAlpha(120)),
                      ),
                      child: Text(
                        challengeText,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
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
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.t('challengeAuctionBidRangeActive', {
                          'min': '${_currentBidRange.minBid}',
                          'max': '${_currentBidRange.maxBid}',
                        }),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 170,
                        child: TextField(
                          controller: _bidController,
                          focusNode: _bidFocusNode,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            TextInputFormatter.withFunction(
                              (oldValue, newValue) {
                                final parsed =
                                    int.tryParse(newValue.text.trim());
                                if (newValue.text.isEmpty || parsed == null) {
                                  return newValue;
                                }
                                if (parsed > _currentBidRange.maxBid) {
                                  _showBidRangeHint(l10n);
                                  HapticService.errorVibrate();
                                  return oldValue;
                                }
                                return newValue;
                              },
                            ),
                          ],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.t('challengeAuctionBidInputHint'),
                            hintStyle: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submitBid(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        settings.alcoholPenaltyEnabled
                            ? l10n.t('challengeAuctionBidCount', {
                                'count': '$previewBid',
                              })
                            : l10n.pointsCount(previewBid),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.t('challengeAuctionBidsProgress', {
                          'current': '${_biddingPlayer + 1}',
                          'total': '$_playerCount',
                        }),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      GameResultActionBar(
                        accentColor: AppColors.wheelOrange,
                        primaryLabel: l10n.t('challengeAuctionConfirmBid'),
                        onPrimaryTap: _submitBid,
                      ),
                    ] else if (_phase == _AuctionPhase.verdict) ...[
                      Text(
                        settings.alcoholPenaltyEnabled
                            ? l10n.t('challengeAuctionWinner', {
                                'player':
                                    PartyPlusStrings.player(context, _winner),
                                'bid': '${_bids[_winner]}',
                              })
                            : l10n.t('challengeAuctionWinnerPure', {
                                'player':
                                    PartyPlusStrings.player(context, _winner),
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
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }),
                      const Spacer(),
                      GameResultActionBar(
                        accentColor: AppColors.wheelOrange,
                        secondaryLabel: l10n.t('challengeAuctionFailed'),
                        onSecondaryTap: _onChallengeFail,
                        primaryLabel: l10n.t('challengeAuctionSucceeded'),
                        onPrimaryTap: _onChallengeSuccess,
                      ),
                    ] else ...[
                      const Spacer(),
                      GameResultTemplateCard(
                        accentColor: AppColors.wheelOrange,
                        resultTitle: l10n.t('resultSummary'),
                        resultText: winnerSummary,
                        penaltyTitle: l10n.punishment,
                        penaltyText: _resultText,
                      ),
                      const Spacer(),
                      GameResultActionBar(
                        accentColor: AppColors.wheelOrange,
                        primaryLabel: l10n.t('challengeAuctionNext'),
                        onPrimaryTap: _startRound,
                      ),
                    ],
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
