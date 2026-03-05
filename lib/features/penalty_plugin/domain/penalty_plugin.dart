import 'penalty_models.dart';

abstract class PenaltyPlugin {
  PenaltyCountry get country;
  List<PenaltyItem> get items;
}

class InMemoryPenaltyPlugin implements PenaltyPlugin {
  InMemoryPenaltyPlugin({
    required this.country,
    required this.items,
  });

  @override
  final PenaltyCountry country;

  @override
  final List<PenaltyItem> items;
}
