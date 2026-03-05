import 'dart:math';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/services/penalty_service.dart';

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
    return PenaltyService.randomPlan(
      l10n: l10n,
      random: random,
      alcoholPenaltyEnabled: alcoholPenaltyEnabled,
    ).text;
  }
}
