import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/haptics/haptic_service.dart';
import '../../l10n/app_localizations.dart';
import '../services/penalty_service.dart';

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(84),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('penaltyPresetTitle'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.t('penaltyPresetHint'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _SectionLabel(label: l10n.t('penaltySceneTitle')),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
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
          const SizedBox(height: 10),
          _SectionLabel(label: l10n.t('penaltyIntensityTitle')),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
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
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? accentColor.withAlpha(30) : Colors.white12,
          border: Border.all(
            color: selected ? accentColor : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
