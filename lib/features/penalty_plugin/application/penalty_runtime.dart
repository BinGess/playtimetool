import '../../settings/providers/settings_provider.dart';
import '../domain/penalty_policy.dart';
import '../domain/penalty_registry.dart';
import '../plugins/cn_penalty_plugin.dart';
import '../plugins/us_penalty_plugin.dart';
import 'penalty_resolver.dart';

final PenaltyResolver defaultPenaltyResolver = PenaltyResolver(
  registry: PenaltyRegistry([
    CnPenaltyPlugin(),
    UsPenaltyPlugin(),
  ]),
);

PenaltyPolicy penaltyPolicyFromSettings(AppSettings settings) {
  return PenaltyPolicy(
    country: settings.defaultPenaltyCountry,
    difficulty: settings.defaultPenaltyDifficulty,
    scale: settings.defaultPenaltyScale,
    selectionMode: settings.defaultPenaltySelectionMode,
    alcoholEnabled: settings.alcoholPenaltyEnabled,
  );
}
