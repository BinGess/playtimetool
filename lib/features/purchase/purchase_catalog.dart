class PurchaseCatalog {
  const PurchaseCatalog._();

  // Non-consumable product IDs (one-time purchase, permanently unlocked)
  static const String wordBombUnlock = 'keyword_bomb_unlock';
  static const String challengeAuctionUnlock = 'challenge_auction_unlock';
  static const String truthRaiseUnlock = 'truth_raise_unlock';

  static const Set<String> productIds = {
    wordBombUnlock,
    challengeAuctionUnlock,
    truthRaiseUnlock,
  };

  static const Map<String, String> routeToProductId = {
    '/games/word-bomb': wordBombUnlock,
    '/games/challenge-auction': challengeAuctionUnlock,
    '/games/truth-raise': truthRaiseUnlock,
  };
}
