import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:playtimetool/shared/services/penalty_service.dart';

void main() {
  group('PenaltyService.randomPlan', () {
    test('returns alcohol pool item when alcohol mode is enabled', () {
      final l10n = AppLocalizations(const Locale('zh'));
      final plan = PenaltyService.randomPlan(
        l10n: l10n,
        random: Random(1),
        alcoholPenaltyEnabled: true,
      );

      expect(plan.id.startsWith('alcohol_'), true);
    });

    test('returns pure pool item when alcohol mode is disabled', () {
      final l10n = AppLocalizations(const Locale('zh'));
      final plan = PenaltyService.randomPlan(
        l10n: l10n,
        random: Random(2),
        alcoholPenaltyEnabled: false,
      );

      expect(plan.id.startsWith('pure_'), true);
    });
  });

  group('PenaltyService.structuredPlan', () {
    test('builds points-based penalty text', () {
      final l10n = AppLocalizations(const Locale('zh'));
      final plan = PenaltyService.pointsPlan(
        l10n: l10n,
        players: const ['玩家1'],
        points: 3,
      );

      expect(
        plan.text,
        l10n.t('penaltyResult', {
          'player': '玩家1',
          'penalty': l10n.pointsCount(3),
        }),
      );
    });

    test('builds guidance penalty text from shared key', () {
      final l10n = AppLocalizations(const Locale('zh'));
      final plan = PenaltyService.guidancePlan(
        l10n: l10n,
        guide: PenaltyGuideType.wheel,
      );

      expect(plan.text, l10n.t('penaltyGuideWheel'));
    });
  });
}
