import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/purchase/purchase_catalog.dart';

void main() {
  test('removed games are not in purchase catalog', () {
    expect(PurchaseCatalog.routeToProductId.containsKey('/games/word-bomb'),
        isFalse);
    expect(
        PurchaseCatalog.routeToProductId
            .containsKey('/games/challenge-auction'),
        isFalse);
  });
}
