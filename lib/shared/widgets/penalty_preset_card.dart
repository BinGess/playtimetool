import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/haptics/haptic_service.dart';
import '../../l10n/app_localizations.dart';
import '../services/penalty_service.dart';
import '../styles/game_ui_style.dart';

class PenaltyPresetCard extends StatelessWidget {
  const PenaltyPresetCard({
    super.key,
    required this.preset,
    required this.onChanged,
    this.accentColor = AppColors.fingerCyan,
  });

  final PenaltyPreset preset;
  final ValueChanged<PenaltyPreset> onChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      key: const Key('penalty-preset-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: GameUiSurface.panel(
        accentColor: accentColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('penaltyPresetTitle'),
            style: GameUiText.sectionTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.t('penaltyPresetHint'),
            style: GameUiText.caption.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 14),
          _SectionLabel(label: l10n.t('penaltySceneTitle')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PresetChip(
                label: l10n.t('penaltySceneHome'),
                selected: preset.scene == PenaltyScene.home,
                accentColor: accentColor,
                onTap: () {
                  HapticService.selectionClick();
                  onChanged(preset.copyWith(scene: PenaltyScene.home));
                },
              ),
              _PresetChip(
                label: l10n.t('penaltySceneBar'),
                selected: preset.scene == PenaltyScene.bar,
                accentColor: accentColor,
                onTap: () {
                  HapticService.selectionClick();
                  onChanged(preset.copyWith(scene: PenaltyScene.bar));
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionLabel(label: l10n.t('penaltyIntensityTitle')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PresetChip(
                label: l10n.t('penaltyIntensityMild'),
                selected: preset.intensity == PenaltyIntensity.mild,
                accentColor: accentColor,
                onTap: () {
                  HapticService.selectionClick();
                  onChanged(
                    preset.copyWith(intensity: PenaltyIntensity.mild),
                  );
                },
              ),
              _PresetChip(
                label: l10n.t('penaltyIntensityWild'),
                selected: preset.intensity == PenaltyIntensity.wild,
                accentColor: accentColor,
                onTap: () {
                  HapticService.selectionClick();
                  onChanged(
                    preset.copyWith(intensity: PenaltyIntensity.wild),
                  );
                },
              ),
              _PresetChip(
                label: l10n.t('penaltyIntensityXtreme'),
                selected: preset.intensity == PenaltyIntensity.xtreme,
                accentColor: accentColor,
                onTap: () {
                  HapticService.selectionClick();
                  onChanged(
                    preset.copyWith(intensity: PenaltyIntensity.xtreme),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GameUiText.eyebrow,
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected ? accentColor.withAlpha(28) : Colors.white12,
            border: Border.all(
              color: selected ? accentColor.withAlpha(190) : Colors.white24,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accentColor.withAlpha(25),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
