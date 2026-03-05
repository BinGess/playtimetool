import 'dart:math';

import '../domain/penalty_models.dart';
import '../domain/penalty_policy.dart';
import '../domain/penalty_registry.dart';

class PenaltyResolution {
  const PenaltyResolution({
    required this.candidates,
    required this.selected,
  });

  final List<PenaltyItem> candidates;
  final PenaltyItem selected;
}

class PenaltyResolver {
  const PenaltyResolver({
    required this.registry,
  });

  final PenaltyRegistry registry;

  PenaltyResolution resolve({
    required PenaltyPolicy policy,
    required PenaltyContext context,
    required Random random,
  }) {
    final plugin = registry.requireByCountry(policy.country);
    final allowed =
        plugin.items.where((item) => _kindAllowed(item, policy)).toList();

    final strict = allowed
        .where(
          (item) =>
              item.difficulty == policy.difficulty &&
              item.scale == policy.scale,
        )
        .toList();

    final candidates =
        strict.isNotEmpty ? strict : _fallbackPool(allowed, policy);

    if (candidates.isEmpty) {
      throw StateError(
        'No penalties available for country=${policy.country} game=${context.gameId}',
      );
    }

    final selected = candidates[random.nextInt(candidates.length)];
    return PenaltyResolution(candidates: candidates, selected: selected);
  }

  List<PenaltyItem> _fallbackPool(
    List<PenaltyItem> allowed,
    PenaltyPolicy policy,
  ) {
    final sameDifficulty =
        allowed.where((item) => item.difficulty == policy.difficulty).toList();
    if (sameDifficulty.isNotEmpty) return sameDifficulty;
    return allowed;
  }

  bool _kindAllowed(PenaltyItem item, PenaltyPolicy policy) {
    if (policy.alcoholEnabled) return true;
    return item.kind != PenaltyKind.alcohol;
  }
}
