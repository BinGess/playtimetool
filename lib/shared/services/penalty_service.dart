import 'dart:math';

import '../../l10n/app_localizations.dart';

enum PenaltyGuideType { defaultGuide, party, wheel }

enum PenaltyScene { home, bar }

enum PenaltyIntensity { mild, wild, xtreme }

enum PenaltyCategory { physical, social, truth }

enum PenaltyLevel { level1, level2, level3 }

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

class PenaltyPreset {
  const PenaltyPreset({
    required this.scene,
    required this.intensity,
  });

  final PenaltyScene scene;
  final PenaltyIntensity intensity;

  static const PenaltyPreset defaults = PenaltyPreset(
    scene: PenaltyScene.home,
    intensity: PenaltyIntensity.mild,
  );

  PenaltyPreset copyWith({
    PenaltyScene? scene,
    PenaltyIntensity? intensity,
  }) {
    return PenaltyPreset(
      scene: scene ?? this.scene,
      intensity: intensity ?? this.intensity,
    );
  }
}

class PenaltyEntry {
  const PenaltyEntry({
    required this.id,
    required this.scene,
    required this.level,
    required this.category,
    required this.text,
  });

  final String id;
  final PenaltyScene scene;
  final PenaltyLevel level;
  final PenaltyCategory category;
  final String text;
}

class PenaltyBlindBoxCard {
  const PenaltyBlindBoxCard({
    required this.entry,
  });

  final PenaltyEntry entry;
}

class PenaltyBlindBoxResult {
  const PenaltyBlindBoxResult({
    required this.losers,
    required this.cards,
  });

  final List<String> losers;
  final List<PenaltyBlindBoxCard> cards;
}

class _PenaltyItem {
  const _PenaltyItem({
    required this.id,
    required this.textKey,
  });

  final String id;
  final String textKey;
}

class _BlindBoxSeed {
  const _BlindBoxSeed({
    required this.id,
    required this.scene,
    required this.level,
    required this.category,
    required this.textKey,
  });

  final String id;
  final PenaltyScene scene;
  final PenaltyLevel level;
  final PenaltyCategory category;
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
      id: 'alcohol_open_drink_mouth',
      textKey: 'penaltyOpenDrinkMouth',
    ),
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
      textKey: 'penaltyTongueTwisterBreath',
    ),
  ];

  static const List<_BlindBoxSeed> _blindBoxSeeds = <_BlindBoxSeed>[
    _BlindBoxSeed(
      id: 'bar_l1_deep_bomb',
      scene: PenaltyScene.bar,
      level: PenaltyLevel.level1,
      category: PenaltyCategory.physical,
      textKey: 'blindBoxBarLevel1DeepBomb',
    ),
    _BlindBoxSeed(
      id: 'bar_l1_cheers_messenger',
      scene: PenaltyScene.bar,
      level: PenaltyLevel.level1,
      category: PenaltyCategory.social,
      textKey: 'blindBoxBarLevel1CheersMessenger',
    ),
    _BlindBoxSeed(
      id: 'bar_l1_song_privilege',
      scene: PenaltyScene.bar,
      level: PenaltyLevel.level1,
      category: PenaltyCategory.truth,
      textKey: 'blindBoxBarLevel1SongPrivilege',
    ),
    _BlindBoxSeed(
      id: 'bar_l1_single_ear',
      scene: PenaltyScene.bar,
      level: PenaltyLevel.level1,
      category: PenaltyCategory.physical,
      textKey: 'blindBoxBarLevel1SingleEar',
    ),
    _BlindBoxSeed(
      id: 'bar_l2_dark_drink',
      scene: PenaltyScene.bar,
      level: PenaltyLevel.level2,
      category: PenaltyCategory.physical,
      textKey: 'blindBoxBarLevel2DarkDrink',
    ),
    _BlindBoxSeed(
      id: 'bar_l2_truth_body',
      scene: PenaltyScene.bar,
      level: PenaltyLevel.level2,
      category: PenaltyCategory.truth,
      textKey: 'blindBoxBarLevel2TruthBody',
    ),
    _BlindBoxSeed(
      id: 'bar_l2_shout_hero',
      scene: PenaltyScene.bar,
      level: PenaltyLevel.level2,
      category: PenaltyCategory.social,
      textKey: 'blindBoxBarLevel2ShoutHero',
    ),
    _BlindBoxSeed(
      id: 'bar_l2_recent_calls',
      scene: PenaltyScene.bar,
      level: PenaltyLevel.level2,
      category: PenaltyCategory.truth,
      textKey: 'blindBoxBarLevel2RecentCalls',
    ),
    _BlindBoxSeed(
      id: 'bar_l3_single_post',
      scene: PenaltyScene.bar,
      level: PenaltyLevel.level3,
      category: PenaltyCategory.social,
      textKey: 'blindBoxBarLevel3SinglePost',
    ),
    _BlindBoxSeed(
      id: 'bar_l3_stranger_tissue',
      scene: PenaltyScene.bar,
      level: PenaltyLevel.level3,
      category: PenaltyCategory.social,
      textKey: 'blindBoxBarLevel3StrangerTissue',
    ),
    _BlindBoxSeed(
      id: 'bar_l3_voice_confession',
      scene: PenaltyScene.bar,
      level: PenaltyLevel.level3,
      category: PenaltyCategory.truth,
      textKey: 'blindBoxBarLevel3VoiceConfession',
    ),
    _BlindBoxSeed(
      id: 'bar_l3_blind_feed',
      scene: PenaltyScene.bar,
      level: PenaltyLevel.level3,
      category: PenaltyCategory.physical,
      textKey: 'blindBoxBarLevel3BlindFeed',
    ),
    _BlindBoxSeed(
      id: 'home_l1_balance_master',
      scene: PenaltyScene.home,
      level: PenaltyLevel.level1,
      category: PenaltyCategory.physical,
      textKey: 'blindBoxHomeLevel1BalanceMaster',
    ),
    _BlindBoxSeed(
      id: 'home_l1_wall_squat',
      scene: PenaltyScene.home,
      level: PenaltyLevel.level1,
      category: PenaltyCategory.physical,
      textKey: 'blindBoxHomeLevel1WallSquat',
    ),
    _BlindBoxSeed(
      id: 'home_l1_emoji_copy',
      scene: PenaltyScene.home,
      level: PenaltyLevel.level1,
      category: PenaltyCategory.social,
      textKey: 'blindBoxHomeLevel1EmojiCopy',
    ),
    _BlindBoxSeed(
      id: 'home_l1_silent_gold',
      scene: PenaltyScene.home,
      level: PenaltyLevel.level1,
      category: PenaltyCategory.truth,
      textKey: 'blindBoxHomeLevel1SilentGold',
    ),
    _BlindBoxSeed(
      id: 'home_l2_secret_story',
      scene: PenaltyScene.home,
      level: PenaltyLevel.level2,
      category: PenaltyCategory.truth,
      textKey: 'blindBoxHomeLevel2SecretStory',
    ),
    _BlindBoxSeed(
      id: 'home_l2_photo_explain',
      scene: PenaltyScene.home,
      level: PenaltyLevel.level2,
      category: PenaltyCategory.truth,
      textKey: 'blindBoxHomeLevel2PhotoExplain',
    ),
    _BlindBoxSeed(
      id: 'home_l2_siri_confession',
      scene: PenaltyScene.home,
      level: PenaltyLevel.level2,
      category: PenaltyCategory.social,
      textKey: 'blindBoxHomeLevel2SiriConfession',
    ),
    _BlindBoxSeed(
      id: 'home_l2_chores_today',
      scene: PenaltyScene.home,
      level: PenaltyLevel.level2,
      category: PenaltyCategory.physical,
      textKey: 'blindBoxHomeLevel2ChoresToday',
    ),
    _BlindBoxSeed(
      id: 'home_l3_group_blast',
      scene: PenaltyScene.home,
      level: PenaltyLevel.level3,
      category: PenaltyCategory.truth,
      textKey: 'blindBoxHomeLevel3GroupBlast',
    ),
    _BlindBoxSeed(
      id: 'home_l3_avatar_swap',
      scene: PenaltyScene.home,
      level: PenaltyLevel.level3,
      category: PenaltyCategory.social,
      textKey: 'blindBoxHomeLevel3AvatarSwap',
    ),
    _BlindBoxSeed(
      id: 'home_l3_live_show',
      scene: PenaltyScene.home,
      level: PenaltyLevel.level3,
      category: PenaltyCategory.social,
      textKey: 'blindBoxHomeLevel3LiveShow',
    ),
    _BlindBoxSeed(
      id: 'home_l3_role_play',
      scene: PenaltyScene.home,
      level: PenaltyLevel.level3,
      category: PenaltyCategory.physical,
      textKey: 'blindBoxHomeLevel3RolePlay',
    ),
  ];

  static const List<_BlindBoxSeed> _fallbackBlindBoxSeeds = <_BlindBoxSeed>[
    _BlindBoxSeed(
      id: 'fallback_quick_squat',
      scene: PenaltyScene.home,
      level: PenaltyLevel.level1,
      category: PenaltyCategory.physical,
      textKey: 'blindBoxFallbackQuickSquat',
    ),
    _BlindBoxSeed(
      id: 'fallback_quick_truth',
      scene: PenaltyScene.home,
      level: PenaltyLevel.level1,
      category: PenaltyCategory.truth,
      textKey: 'blindBoxFallbackQuickTruth',
    ),
    _BlindBoxSeed(
      id: 'fallback_quick_song',
      scene: PenaltyScene.home,
      level: PenaltyLevel.level1,
      category: PenaltyCategory.social,
      textKey: 'blindBoxFallbackQuickSong',
    ),
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

  static PenaltyBlindBoxResult resolveBlindBox({
    required AppLocalizations l10n,
    required Random random,
    required PenaltyPreset preset,
    required List<String> losers,
  }) {
    final targetLevel = _pickLevel(preset.intensity, random);
    final cards = _selectBlindBoxSeeds(
      random: random,
      scene: preset.scene,
      targetLevel: targetLevel,
    ).map((seed) {
      return PenaltyBlindBoxCard(
        entry: PenaltyEntry(
          id: seed.id,
          scene: seed.scene,
          level: seed.level,
          category: seed.category,
          text: l10n.t(seed.textKey),
        ),
      );
    }).toList(growable: false);

    return PenaltyBlindBoxResult(
      losers: List<String>.unmodifiable(losers),
      cards: List<PenaltyBlindBoxCard>.unmodifiable(cards),
    );
  }

  static PenaltyLevel _pickLevel(PenaltyIntensity intensity, Random random) {
    final roll = random.nextDouble();
    return switch (intensity) {
      PenaltyIntensity.mild => PenaltyLevel.level1,
      PenaltyIntensity.wild =>
        roll < 0.7 ? PenaltyLevel.level2 : PenaltyLevel.level1,
      PenaltyIntensity.xtreme => roll < 0.6
          ? PenaltyLevel.level3
          : roll < 0.9
              ? PenaltyLevel.level2
              : PenaltyLevel.level1,
    };
  }

  static List<_BlindBoxSeed> _selectBlindBoxSeeds({
    required Random random,
    required PenaltyScene scene,
    required PenaltyLevel targetLevel,
  }) {
    final selected = <_BlindBoxSeed>[];
    final usedIds = <String>{};
    final usedCategories = <PenaltyCategory>{};

    final exact = _blindBoxSeeds.where((seed) {
      return seed.scene == scene && seed.level == targetLevel;
    }).toList();
    _pickSeeds(
      random: random,
      candidates: exact,
      selected: selected,
      usedIds: usedIds,
      usedCategories: usedCategories,
      targetCount: 3,
      preferNewCategories: true,
    );
    _pickSeeds(
      random: random,
      candidates: exact,
      selected: selected,
      usedIds: usedIds,
      usedCategories: usedCategories,
      targetCount: 3,
      preferNewCategories: false,
    );

    final orderedLevels = PenaltyLevel.values.toList()
      ..sort((a, b) => (_levelDistance(a, targetLevel))
          .compareTo(_levelDistance(b, targetLevel)));
    for (final level in orderedLevels) {
      if (level == targetLevel || selected.length >= 3) continue;
      final pool = _blindBoxSeeds.where((seed) {
        return seed.scene == scene && seed.level == level;
      }).toList();
      _pickSeeds(
        random: random,
        candidates: pool,
        selected: selected,
        usedIds: usedIds,
        usedCategories: usedCategories,
        targetCount: 3,
        preferNewCategories: true,
      );
      _pickSeeds(
        random: random,
        candidates: pool,
        selected: selected,
        usedIds: usedIds,
        usedCategories: usedCategories,
        targetCount: 3,
        preferNewCategories: false,
      );
    }

    if (selected.length < 3) {
      _pickSeeds(
        random: random,
        candidates: _fallbackBlindBoxSeeds,
        selected: selected,
        usedIds: usedIds,
        usedCategories: usedCategories,
        targetCount: 3,
        preferNewCategories: true,
      );
      _pickSeeds(
        random: random,
        candidates: _fallbackBlindBoxSeeds,
        selected: selected,
        usedIds: usedIds,
        usedCategories: usedCategories,
        targetCount: 3,
        preferNewCategories: false,
      );
    }

    return selected.take(3).toList(growable: false);
  }

  static void _pickSeeds({
    required Random random,
    required List<_BlindBoxSeed> candidates,
    required List<_BlindBoxSeed> selected,
    required Set<String> usedIds,
    required Set<PenaltyCategory> usedCategories,
    required int targetCount,
    required bool preferNewCategories,
  }) {
    final available = candidates.where((seed) {
      if (usedIds.contains(seed.id)) {
        return false;
      }
      if (preferNewCategories && usedCategories.contains(seed.category)) {
        return false;
      }
      return true;
    }).toList()
      ..shuffle(random);

    for (final seed in available) {
      if (selected.length >= targetCount) {
        return;
      }
      selected.add(seed);
      usedIds.add(seed.id);
      usedCategories.add(seed.category);
    }
  }

  static int _levelDistance(PenaltyLevel a, PenaltyLevel b) {
    return (PenaltyLevel.values.indexOf(a) - PenaltyLevel.values.indexOf(b))
        .abs();
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
