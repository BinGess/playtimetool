import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/haptics/haptic_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/styles/game_ui_style.dart';
import '../../shared/widgets/difficulty_option_card.dart';
import '../../shared/widgets/web3_game_background.dart';
import 'logic/gravity_balance_logic.dart';

class GravityBalancePrepScreen extends StatefulWidget {
  const GravityBalancePrepScreen({super.key});

  @override
  State<GravityBalancePrepScreen> createState() =>
      _GravityBalancePrepScreenState();
}

class _GravityBalancePrepScreenState extends State<GravityBalancePrepScreen> {
  GravityBalanceDifficulty _selected = GravityBalanceDifficulty.medium;
  int _participantCount = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Web3GameBackground(
            accentColor: Color(0xFF4DFFD8),
            secondaryColor: Color(0xFFFF6B6B),
          ),
          SafeArea(
            child: Padding(
              padding: GameUiSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        color: Colors.white,
                      ),
                      Expanded(
                        child: Text(
                          l10n.t('gravityBalance'),
                          textAlign: TextAlign.center,
                          style: GameUiText.navTitle,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: GameUiSpacing.blockGap),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.t('gravityBalancePrepTitle'),
                            textAlign: TextAlign.center,
                            style: GameUiText.sectionTitle.copyWith(
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.t('gravityBalancePrepHint'),
                            textAlign: TextAlign.center,
                            style: GameUiText.body,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.t('gravityBalancePlayersSetting', {
                              'count': '$_participantCount',
                            }),
                            style: GameUiText.body,
                          ),
                          Slider(
                            value: _participantCount.toDouble(),
                            min: 1,
                            max: 8,
                            divisions: 7,
                            activeColor: const Color(0xFF4DFFD8),
                            onChanged: (v) =>
                                setState(() => _participantCount = v.round()),
                          ),
                          const SizedBox(height: 10),
                          DifficultyOptionCard(
                            title: l10n.t('leftRightDifficultyEasy'),
                            hint: l10n.t('gravityBalanceDifficultyEasyHint'),
                            selected:
                                _selected == GravityBalanceDifficulty.easy,
                            accentColor: const Color(0xFF78F7DD),
                            onTap: () => _select(GravityBalanceDifficulty.easy),
                          ),
                          const SizedBox(height: 10),
                          DifficultyOptionCard(
                            title: l10n.t('leftRightDifficultyMedium'),
                            hint: l10n.t('gravityBalanceDifficultyMediumHint'),
                            selected:
                                _selected == GravityBalanceDifficulty.medium,
                            accentColor: const Color(0xFFFFD166),
                            onTap: () =>
                                _select(GravityBalanceDifficulty.medium),
                          ),
                          const SizedBox(height: 10),
                          DifficultyOptionCard(
                            title: l10n.t('leftRightDifficultyHard'),
                            hint: l10n.t('gravityBalanceDifficultyHardHint'),
                            selected:
                                _selected == GravityBalanceDifficulty.hard,
                            accentColor: const Color(0xFFFF6B6B),
                            onTap: () => _select(GravityBalanceDifficulty.hard),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: GameUiSpacing.buttonHeight,
                    child: ElevatedButton.icon(
                      onPressed: _start,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4DFFD8),
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        l10n.t('gravityBalanceStartChallenge'),
                        style: GameUiText.buttonLabel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _select(GravityBalanceDifficulty difficulty) {
    HapticService.lightImpact();
    setState(() {
      _selected = difficulty;
    });
  }

  void _start() {
    HapticService.mediumImpact();
    final difficultyId = gravityBalanceDifficultyId(_selected);
    context.push(
      '/games/gravity-balance/play?difficulty=$difficultyId&players=$_participantCount',
    );
  }
}
