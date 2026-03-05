enum PenaltyCountry {
  cn,
  us,
}

enum PenaltyDifficulty {
  easy,
  normal,
  hard,
}

enum PenaltyScale {
  light,
  medium,
  wild,
}

enum PenaltySelectionMode {
  manual,
  random,
}

enum PenaltyKind {
  alcohol,
  clean,
  mixed,
}

class PenaltyItem {
  const PenaltyItem({
    required this.id,
    required this.country,
    required this.difficulty,
    required this.scale,
    required this.kind,
    required this.textKey,
    this.tags = const [],
  });

  final String id;
  final PenaltyCountry country;
  final PenaltyDifficulty difficulty;
  final PenaltyScale scale;
  final PenaltyKind kind;
  final String textKey;
  final List<String> tags;
}
