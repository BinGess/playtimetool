enum DuelGesture { rock, paper, scissors }

class DuelResolution {
  const DuelResolution({
    required this.losers,
    required this.isDraw,
  });

  final List<int> losers;
  final bool isDraw;
}

DuelResolution resolveGestureDuel({
  required List<DuelGesture> picks,
  required bool minorityLoses,
}) {
  final counts = <DuelGesture, int>{};
  for (final g in picks) {
    counts[g] = (counts[g] ?? 0) + 1;
  }

  if (counts.length <= 1) {
    return const DuelResolution(losers: <int>[], isDraw: true);
  }

  final values = counts.values.toList()..sort();
  final target = minorityLoses ? values.first : values.last;
  final targetGestures =
      counts.entries.where((e) => e.value == target).map((e) => e.key).toSet();

  final losers = <int>[];
  for (int i = 0; i < picks.length; i++) {
    if (targetGestures.contains(picks[i])) {
      losers.add(i);
    }
  }

  final isDraw = losers.isEmpty || losers.length == picks.length;
  return DuelResolution(losers: losers, isDraw: isDraw);
}
