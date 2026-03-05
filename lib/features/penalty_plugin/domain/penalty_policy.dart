import 'penalty_models.dart';

class PenaltyPolicy {
  const PenaltyPolicy({
    required this.country,
    required this.difficulty,
    required this.scale,
    required this.selectionMode,
    required this.alcoholEnabled,
  });

  final PenaltyCountry country;
  final PenaltyDifficulty difficulty;
  final PenaltyScale scale;
  final PenaltySelectionMode selectionMode;
  final bool alcoholEnabled;
}

class PenaltyContext {
  const PenaltyContext({
    required this.gameId,
    required this.loserCount,
    required this.round,
    this.extra = const {},
  });

  final String gameId;
  final int loserCount;
  final int round;
  final Map<String, Object?> extra;
}
