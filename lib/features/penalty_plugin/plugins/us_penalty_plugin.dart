import '../domain/penalty_models.dart';
import '../domain/penalty_plugin.dart';

class UsPenaltyPlugin implements PenaltyPlugin {
  @override
  PenaltyCountry get country => PenaltyCountry.us;

  @override
  List<PenaltyItem> get items => const [
        PenaltyItem(
          id: 'us_alcohol_light_cheers',
          country: PenaltyCountry.us,
          difficulty: PenaltyDifficulty.easy,
          scale: PenaltyScale.light,
          kind: PenaltyKind.alcohol,
          textKey: 'penaltyUsAlcoholLightCheers',
          tags: ['social'],
        ),
        PenaltyItem(
          id: 'us_alcohol_medium_two_sips',
          country: PenaltyCountry.us,
          difficulty: PenaltyDifficulty.normal,
          scale: PenaltyScale.medium,
          kind: PenaltyKind.alcohol,
          textKey: 'penaltyUsAlcoholMediumTwoSips',
          tags: ['drink'],
        ),
        PenaltyItem(
          id: 'us_alcohol_wild_shot',
          country: PenaltyCountry.us,
          difficulty: PenaltyDifficulty.hard,
          scale: PenaltyScale.wild,
          kind: PenaltyKind.alcohol,
          textKey: 'penaltyUsAlcoholWildShot',
          tags: ['drink'],
        ),
        PenaltyItem(
          id: 'us_clean_light_alphabet',
          country: PenaltyCountry.us,
          difficulty: PenaltyDifficulty.easy,
          scale: PenaltyScale.light,
          kind: PenaltyKind.clean,
          textKey: 'penaltyUsCleanLightAlphabet',
          tags: ['speak'],
        ),
        PenaltyItem(
          id: 'us_clean_medium_pushup',
          country: PenaltyCountry.us,
          difficulty: PenaltyDifficulty.normal,
          scale: PenaltyScale.medium,
          kind: PenaltyKind.clean,
          textKey: 'penaltyUsCleanMediumPushup',
          tags: ['fitness'],
        ),
        PenaltyItem(
          id: 'us_clean_wild_freestyle',
          country: PenaltyCountry.us,
          difficulty: PenaltyDifficulty.hard,
          scale: PenaltyScale.wild,
          kind: PenaltyKind.clean,
          textKey: 'penaltyUsCleanWildFreestyle',
          tags: ['perform'],
        ),
      ];
}
