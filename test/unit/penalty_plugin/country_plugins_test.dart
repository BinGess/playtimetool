import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/penalty_plugin/domain/penalty_models.dart';
import 'package:playtimetool/features/penalty_plugin/plugins/cn_penalty_plugin.dart';
import 'package:playtimetool/features/penalty_plugin/plugins/us_penalty_plugin.dart';

void main() {
  test('cn plugin exposes clean and alcohol items in all scale tiers', () {
    final plugin = CnPenaltyPlugin();
    final all = plugin.items;

    expect(plugin.country, PenaltyCountry.cn);
    expect(all.any((e) => e.kind == PenaltyKind.clean), true);
    expect(all.any((e) => e.kind == PenaltyKind.alcohol), true);
    expect(all.any((e) => e.scale == PenaltyScale.light), true);
    expect(all.any((e) => e.scale == PenaltyScale.medium), true);
    expect(all.any((e) => e.scale == PenaltyScale.wild), true);
  });

  test('us plugin exposes clean and alcohol items in all scale tiers', () {
    final plugin = UsPenaltyPlugin();
    final all = plugin.items;

    expect(plugin.country, PenaltyCountry.us);
    expect(all.any((e) => e.kind == PenaltyKind.clean), true);
    expect(all.any((e) => e.kind == PenaltyKind.alcohol), true);
    expect(all.any((e) => e.scale == PenaltyScale.light), true);
    expect(all.any((e) => e.scale == PenaltyScale.medium), true);
    expect(all.any((e) => e.scale == PenaltyScale.wild), true);
  });
}
