class PurchaseCatalog {
  const PurchaseCatalog._();

  static const String gravityBalanceUnlockProductId =
      'com.partygames.playtimetool.gravity_balance_unlock';

  static const Set<String> productIds = {
    gravityBalanceUnlockProductId,
  };

  static const Map<String, String> routeToProductId = {
    '/games/gravity-balance': gravityBalanceUnlockProductId,
    '/games/gravity-balance/play': gravityBalanceUnlockProductId,
  };
}
