import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/purchase/purchase_catalog.dart';

void main() {
  test('gravity balance routes are mapped to a permanent unlock product', () {
    expect(
      PurchaseCatalog.routeToProductId['/games/gravity-balance'],
      PurchaseCatalog.gravityBalanceUnlockProductId,
    );
    expect(
      PurchaseCatalog.routeToProductId['/games/gravity-balance/play'],
      PurchaseCatalog.gravityBalanceUnlockProductId,
    );
    expect(
      PurchaseCatalog.productIds,
      contains(PurchaseCatalog.gravityBalanceUnlockProductId),
    );
  });

  test('removed games are not in purchase catalog', () {
    expect(PurchaseCatalog.routeToProductId.containsKey('/games/word-bomb'),
        isFalse);
    expect(
        PurchaseCatalog.routeToProductId
            .containsKey('/games/challenge-auction'),
        isFalse);
  });
}
