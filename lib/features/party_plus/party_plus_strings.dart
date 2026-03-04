import 'dart:math';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

abstract final class PartyPlusStrings {
  static String player(BuildContext context, int index) {
    return AppLocalizations.of(context).playerLabel(index + 1);
  }

  static String randomPenalty(
    BuildContext context,
    Random random, {
    required bool alcoholPenaltyEnabled,
  }) {
    final l10n = AppLocalizations.of(context);
    final items = alcoholPenaltyEnabled
        ? <String>[
            l10n.t('penaltySipOne'),
            l10n.t('penaltySipTwo'),
            l10n.t('penaltyCheersRight'),
            l10n.t('penaltyTruthOne'),
            l10n.t('penaltyMiniShot'),
          ]
        : <String>[
            l10n.t('penaltySquatEight'),
            l10n.t('penaltyTongueTwister'),
            l10n.t('penaltyComplimentLeft'),
            l10n.t('penaltyPlankTen'),
            l10n.t('penaltyClapBeat'),
          ];
    return items[random.nextInt(items.length)];
  }
}
