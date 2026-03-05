class PurchaseCatalog {
  const PurchaseCatalog._();

  // Non-consumable product IDs (one-time purchase, permanently unlocked)
  static const String truthRaiseUnlock = 'truth_raise_unlock';

  static const Set<String> productIds = {
    truthRaiseUnlock,
  };

  static const Map<String, String> routeToProductId = {
    '/games/truth-raise': truthRaiseUnlock,
  };
}
