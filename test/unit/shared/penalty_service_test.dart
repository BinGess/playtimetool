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

  group('PenaltyService.resolveBlindBox', () {
    test('draws three unique home cards for preset', () {
      final l10n = AppLocalizations(const Locale('zh'));
      final result = PenaltyService.resolveBlindBox(
        l10n: l10n,
        random: Random(1),
        preset: const PenaltyPreset(
          scene: PenaltyScene.home,
          intensity: PenaltyIntensity.wild,
        ),
        losers: const ['玩家1'],
      );

      expect(result.cards, hasLength(3));
      expect(result.cards.map((card) => card.entry.id).toSet().length, 3);
      expect(result.losers, const ['玩家1']);
    });

    test('mild preset only draws level1 cards', () {
      final l10n = AppLocalizations(const Locale('zh'));
      final result = PenaltyService.resolveBlindBox(
        l10n: l10n,
        random: Random(2),
        preset: const PenaltyPreset(
          scene: PenaltyScene.bar,
          intensity: PenaltyIntensity.mild,
        ),
        losers: const ['玩家1'],
      );

      expect(
        result.cards.every((card) => card.entry.level == PenaltyLevel.level1),
        isTrue,
      );
    });

    test('prefers different categories when generating three cards', () {
      final l10n = AppLocalizations(const Locale('zh'));
      final result = PenaltyService.resolveBlindBox(
        l10n: l10n,
        random: Random(3),
        preset: const PenaltyPreset(
          scene: PenaltyScene.home,
          intensity: PenaltyIntensity.xtreme,
        ),
        losers: const ['玩家1', '玩家2'],
      );

      expect(
        result.cards.map((card) => card.entry.category).toSet().length,
        greaterThanOrEqualTo(2),
      );
    });
  });
}
