import 'penalty_models.dart';
import 'penalty_plugin.dart';

class PenaltyRegistry {
  PenaltyRegistry(this.plugins);

  final List<PenaltyPlugin> plugins;

  PenaltyPlugin requireByCountry(PenaltyCountry country) {
    return plugins.firstWhere((plugin) => plugin.country == country);
  }
}
