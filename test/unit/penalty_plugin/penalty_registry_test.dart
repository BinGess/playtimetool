import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/penalty_plugin/domain/penalty_models.dart';
import 'package:playtimetool/features/penalty_plugin/domain/penalty_plugin.dart';
import 'package:playtimetool/features/penalty_plugin/domain/penalty_registry.dart';

void main() {
  test('registry returns plugin by country', () {
    final registry = PenaltyRegistry([
      InMemoryPenaltyPlugin(country: PenaltyCountry.cn, items: const []),
      InMemoryPenaltyPlugin(country: PenaltyCountry.us, items: const []),
    ]);

    final plugin = registry.requireByCountry(PenaltyCountry.us);
    expect(plugin.country, PenaltyCountry.us);
  });
}
