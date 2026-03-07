import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/haptics/haptic_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/services/penalty_service.dart';
import '../../shared/styles/game_ui_style.dart';
import '../../shared/widgets/difficulty_option_card.dart';
import '../../shared/widgets/game_top_bar.dart';
import '../../shared/widgets/penalty_preset_card.dart';
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
  PenaltyPreset _penaltyPreset = PenaltyPreset.defaults;

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
                  GameTopBar(
                    title: l10n.t('gravityBalance'),
                    onBack: () => context.pop(),
                    accentColor: const Color(0xFF4DFFD8),
                  ),
                  const SizedBox(height: GameUiSpacing.blockGap),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: GameUiSurface.heroPanel(
                              accentColor: const Color(0xFF4DFFD8),
                              secondaryColor: const Color(0xFFFF6B6B),
                            ),
                            child: Text(
                              l10n.t('gravityBalancePrepHint'),
                              textAlign: TextAlign.center,
                              style: GameUiText.body.copyWith(
                                color: const Color(0xFFD6FFF7),
                              ),
                            ),
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
                          const SizedBox(height: 14),
                          PenaltyPresetCard(
                            preset: _penaltyPreset,
                            accentColor: const Color(0xFF4DFFD8),
                            onChanged: (preset) {
                              setState(() => _penaltyPreset = preset);
                            },
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
                      style: GameUiSurface.primaryButton(
                        const Color(0xFF4DFFD8),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        l10n.t('gravityBalanceStartChallenge'),
                        style: GameUiText.buttonLabel.copyWith(
                          color: GameUiSurface.foregroundOn(
                            const Color(0xFF4DFFD8),
                          ),
                        ),
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
    final penaltyScene = penaltySceneId(_penaltyPreset.scene);
    final penaltyIntensity = penaltyIntensityId(_penaltyPreset.intensity);
    context.push(
      '/games/gravity-balance/play?difficulty=$difficultyId&players=$_participantCount&penaltyScene=$penaltyScene&penaltyIntensity=$penaltyIntensity',
    );
  }
}
