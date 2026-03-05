import '../domain/penalty_models.dart';
import '../domain/penalty_plugin.dart';

class CnPenaltyPlugin implements PenaltyPlugin {
  @override
  PenaltyCountry get country => PenaltyCountry.cn;

  @override
  List<PenaltyItem> get items => const [
        PenaltyItem(
          id: 'cn_alcohol_light_toast',
          country: PenaltyCountry.cn,
          difficulty: PenaltyDifficulty.easy,
          scale: PenaltyScale.light,
          kind: PenaltyKind.alcohol,
          textKey: 'penaltyCnAlcoholLightToast',
          tags: ['social'],
        ),
        PenaltyItem(
          id: 'cn_alcohol_medium_double_sip',
          country: PenaltyCountry.cn,
          difficulty: PenaltyDifficulty.normal,
          scale: PenaltyScale.medium,
          kind: PenaltyKind.alcohol,
          textKey: 'penaltyCnAlcoholMediumDoubleSip',
          tags: ['drink'],
        ),
        PenaltyItem(
          id: 'cn_alcohol_wild_bottoms_up',
          country: PenaltyCountry.cn,
          difficulty: PenaltyDifficulty.hard,
          scale: PenaltyScale.wild,
          kind: PenaltyKind.alcohol,
          textKey: 'penaltyCnAlcoholWildBottomsUp',
          tags: ['drink'],
        ),
        PenaltyItem(
          id: 'cn_clean_light_countdown',
          country: PenaltyCountry.cn,
          difficulty: PenaltyDifficulty.easy,
          scale: PenaltyScale.light,
          kind: PenaltyKind.clean,
          textKey: 'penaltyCnCleanLightCountdown',
          tags: ['speak'],
        ),
        PenaltyItem(
          id: 'cn_clean_medium_squat',
          country: PenaltyCountry.cn,
          difficulty: PenaltyDifficulty.normal,
          scale: PenaltyScale.medium,
          kind: PenaltyKind.clean,
          textKey: 'penaltyCnCleanMediumSquat',
          tags: ['fitness'],
        ),
        PenaltyItem(
          id: 'cn_clean_wild_acting',
          country: PenaltyCountry.cn,
          difficulty: PenaltyDifficulty.hard,
          scale: PenaltyScale.wild,
          kind: PenaltyKind.clean,
          textKey: 'penaltyCnCleanWildActing',
          tags: ['perform'],
        ),
      ];
}
