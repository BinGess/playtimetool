import 'dart:math';
import '../../l10n/app_localizations.dart';

enum PenaltyGuideType { defaultGuide, party, wheel }

enum _PenaltyMethodType { random, score, rule, guide }

class PenaltyPlan {
  const PenaltyPlan({
    required this.id,
    required this.text,
    required this.method,
  });

  final String id;
  final String text;
  final String method;

  String get displayText => '$method · $text';
}

class _PenaltyItem {
  const _PenaltyItem({
    required this.id,
    required this.textKey,
  });

  final String id;
  final String textKey;
}

abstract final class PenaltyService {
  static const List<_PenaltyItem> _alcoholItems = <_PenaltyItem>[
    _PenaltyItem(id: 'alcohol_sip_one', textKey: 'penaltySipOne'),
    _PenaltyItem(id: 'alcohol_sip_two', textKey: 'penaltySipTwo'),
    _PenaltyItem(id: 'alcohol_cheers_right', textKey: 'penaltyCheersRight'),
    _PenaltyItem(id: 'alcohol_truth_one', textKey: 'penaltyTruthOne'),
    _PenaltyItem(id: 'alcohol_mini_shot', textKey: 'penaltyMiniShot'),
    _PenaltyItem(
        id: 'alcohol_open_drink_mouth', textKey: 'penaltyOpenDrinkMouth'),
  ];

  static const List<_PenaltyItem> _pureItems = <_PenaltyItem>[
    _PenaltyItem(id: 'pure_squat_eight', textKey: 'penaltySquatEight'),
    _PenaltyItem(id: 'pure_tongue_twister', textKey: 'penaltyTongueTwister'),
    _PenaltyItem(id: 'pure_compliment_left', textKey: 'penaltyComplimentLeft'),
    _PenaltyItem(id: 'pure_plank_ten', textKey: 'penaltyPlankTen'),
    _PenaltyItem(id: 'pure_clap_beat', textKey: 'penaltyClapBeat'),
    _PenaltyItem(id: 'pure_carry_loop', textKey: 'penaltyCarryLoop'),
    _PenaltyItem(id: 'pure_bark_three', textKey: 'penaltyBarkThree'),
    _PenaltyItem(id: 'pure_bow_all', textKey: 'penaltyBowAll'),
    _PenaltyItem(id: 'pure_perform_talent', textKey: 'penaltyPerformTalent'),
    _PenaltyItem(id: 'pure_write_name_foot', textKey: 'penaltyWriteNameFoot'),
    _PenaltyItem(id: 'pure_ugly_selfie', textKey: 'penaltyUglySelfie'),
    _PenaltyItem(id: 'pure_forehead_flick', textKey: 'penaltyForeheadFlick'),
    _PenaltyItem(id: 'pure_send_love_msg', textKey: 'penaltySendLoveMsg'),
    _PenaltyItem(id: 'pure_sing_chorus', textKey: 'penaltySingChorus'),
    _PenaltyItem(id: 'pure_one_leg_thirty', textKey: 'penaltyOneLegThirty'),
    _PenaltyItem(id: 'pure_mimic_walk', textKey: 'penaltyMimicWalk'),
    _PenaltyItem(
        id: 'pure_tongue_twister_breath',
        textKey: 'penaltyTongueTwisterBreath'),
  ];

  static PenaltyPlan randomPlan({
    required AppLocalizations l10n,
    required Random random,
    required bool alcoholPenaltyEnabled,
  }) {
    final pool = alcoholPenaltyEnabled ? _alcoholItems : _pureItems;
    final picked = pool[random.nextInt(pool.length)];
    return PenaltyPlan(
      id: picked.id,
      text: l10n.t(picked.textKey),
      method: _methodLabel(l10n, _PenaltyMethodType.random),
    );
  }

  static PenaltyPlan pointsPlan({
    required AppLocalizations l10n,
    required List<String> players,
    required int points,
  }) {
    return PenaltyPlan(
      id: 'rule_points_penalty',
      text: l10n.t('penaltyResult', {
        'player': players.join('、'),
        'penalty': l10n.pointsCount(points),
      }),
      method: _methodLabel(l10n, _PenaltyMethodType.score),
    );
  }

  static PenaltyPlan actionPlan({
    required AppLocalizations l10n,
    required List<String> players,
    required String actionText,
  }) {
    return PenaltyPlan(
      id: 'rule_action_penalty',
      text: l10n.t('penaltyResult', {
        'player': players.join('、'),
        'penalty': actionText,
      }),
      method: _methodLabel(l10n, _PenaltyMethodType.rule),
    );
  }

  static PenaltyPlan guidancePlan({
    required AppLocalizations l10n,
    required PenaltyGuideType guide,
  }) {
    final key = switch (guide) {
      PenaltyGuideType.defaultGuide => 'penaltyGuideDefault',
      PenaltyGuideType.party => 'penaltyGuideParty',
      PenaltyGuideType.wheel => 'penaltyGuideWheel',
    };
    return PenaltyPlan(
      id: 'guide_${guide.name}',
      text: l10n.t(key),
      method: _methodLabel(l10n, _PenaltyMethodType.guide),
    );
  }

  static PenaltyPlan challengeAuctionPlan({
    required AppLocalizations l10n,
    required bool alcoholPenaltyEnabled,
    required bool success,
    required String player,
    required int bid,
  }) {
    if (success) {
      return PenaltyPlan(
        id: alcoholPenaltyEnabled
            ? 'rule_challenge_success_alcohol'
            : 'rule_challenge_success_pure',
        text: alcoholPenaltyEnabled
            ? l10n.t('challengeAuctionResultSuccessAlcohol', {
                'player': player,
              })
            : l10n.t('challengeAuctionResultSuccessPure', {
                'player': player,
              }),
        method: _methodLabel(l10n, _PenaltyMethodType.rule),
      );
    }

    return PenaltyPlan(
      id: alcoholPenaltyEnabled
          ? 'rule_challenge_fail_alcohol'
          : 'rule_challenge_fail_pure',
      text: alcoholPenaltyEnabled
          ? l10n.t('challengeAuctionResultFailAlcohol', {
              'player': player,
              'count': '${bid + 1}',
            })
          : l10n.t('challengeAuctionResultFailPure', {
              'player': player,
              'count': '${bid + 1}',
            }),
      method: _methodLabel(l10n, _PenaltyMethodType.rule),
    );
  }

  static String _methodLabel(AppLocalizations l10n, _PenaltyMethodType method) {
    return switch (method) {
      _PenaltyMethodType.random => l10n.t('penaltyMethodRandom'),
      _PenaltyMethodType.score => l10n.t('penaltyMethodScore'),
      _PenaltyMethodType.rule => l10n.t('penaltyMethodRule'),
      _PenaltyMethodType.guide => l10n.t('penaltyMethodGuide'),
    };
  }
}
