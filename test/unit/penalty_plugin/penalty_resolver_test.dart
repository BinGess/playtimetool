import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/penalty_plugin/domain/penalty_models.dart';
import 'package:playtimetool/features/penalty_plugin/domain/penalty_plugin.dart';
import 'package:playtimetool/features/penalty_plugin/domain/penalty_policy.dart';
import 'package:playtimetool/features/penalty_plugin/domain/penalty_registry.dart';
import 'package:playtimetool/features/penalty_plugin/application/penalty_resolver.dart';

void main() {
  test('resolver excludes alcohol items when alcohol gate is off', () {
    final resolver = PenaltyResolver(
      registry: PenaltyRegistry([
        InMemoryPenaltyPlugin(
          country: PenaltyCountry.cn,
          items: [
            _item(
              id: 'alcohol-1',
              kind: PenaltyKind.alcohol,
              difficulty: PenaltyDifficulty.normal,
              scale: PenaltyScale.medium,
            ),
            _item(
              id: 'clean-1',
              kind: PenaltyKind.clean,
              difficulty: PenaltyDifficulty.normal,
              scale: PenaltyScale.medium,
            ),
          ],
        ),
      ]),
    );

    final result = resolver.resolve(
      policy: const PenaltyPolicy(
        country: PenaltyCountry.cn,
        difficulty: PenaltyDifficulty.normal,
        scale: PenaltyScale.medium,
        selectionMode: PenaltySelectionMode.random,
        alcoholEnabled: false,
      ),
      context: const PenaltyContext(
        gameId: 'pass_bomb',
        loserCount: 1,
        round: 1,
      ),
      random: Random(1),
    );

    expect(result.selected.kind, isNot(PenaltyKind.alcohol));
    expect(
        result.candidates.every((it) => it.kind != PenaltyKind.alcohol), true);
  });

  test('resolver falls back when strict filter has no matches', () {
    final resolver = PenaltyResolver(
      registry: PenaltyRegistry([
        InMemoryPenaltyPlugin(
          country: PenaltyCountry.cn,
          items: [
            _item(
              id: 'clean-light',
              kind: PenaltyKind.clean,
              difficulty: PenaltyDifficulty.easy,
              scale: PenaltyScale.light,
            ),
          ],
        ),
      ]),
    );

    final result = resolver.resolve(
      policy: const PenaltyPolicy(
        country: PenaltyCountry.cn,
        difficulty: PenaltyDifficulty.hard,
        scale: PenaltyScale.wild,
        selectionMode: PenaltySelectionMode.random,
        alcoholEnabled: false,
      ),
      context: const PenaltyContext(
        gameId: 'word_bomb',
        loserCount: 2,
        round: 3,
      ),
      random: Random(2),
    );

    expect(result.candidates, isNotEmpty);
    expect(result.selected.id, 'clean-light');
  });
}

PenaltyItem _item({
  required String id,
  required PenaltyKind kind,
  required PenaltyDifficulty difficulty,
  required PenaltyScale scale,
}) {
  return PenaltyItem(
    id: id,
    country: PenaltyCountry.cn,
    difficulty: difficulty,
    scale: scale,
    kind: kind,
    textKey: id,
  );
}
