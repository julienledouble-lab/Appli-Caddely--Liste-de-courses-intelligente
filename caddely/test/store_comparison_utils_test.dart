import 'package:caddely/models/store.dart';
import 'package:caddely/models/store_basket.dart';
import 'package:caddely/utils/store_comparison_utils.dart';
import 'package:flutter_test/flutter_test.dart';

StoreBasket basket({
  required String id,
  required String name,
  required double total,
}) {
  return StoreBasket(
    storeId: id,
    storeName: name,
    storeEmoji: '🛒',
    totalPrice: total,
    itemPrices: const [],
  );
}

void main() {
  test('comparison is limited to selected stores', () {
    final result = buildStoreComparisonResult(
      allBaskets: [
        basket(id: 'carrefour', name: 'Carrefour', total: 20),
        basket(id: 'leclerc', name: 'Leclerc', total: 18),
        basket(id: 'auchan', name: 'Auchan', total: 17),
      ],
      selectedStores: const [
        Store(id: 'carrefour', name: 'Carrefour', isPrimary: true),
        Store(id: 'leclerc', name: 'Leclerc', isSelectedForComparison: true),
      ],
      primaryStore: const Store(id: 'carrefour', name: 'Carrefour', isPrimary: true),
    );

    expect(result.baskets.map((basket) => basket.storeId), ['leclerc', 'carrefour']);
  });

  test('calculates savings relative to primary store', () {
    final result = buildStoreComparisonResult(
      allBaskets: [
        basket(id: 'carrefour', name: 'Carrefour', total: 20),
        basket(id: 'leclerc', name: 'Leclerc', total: 14),
      ],
      selectedStores: const [
        Store(id: 'carrefour', name: 'Carrefour', isPrimary: true),
        Store(id: 'leclerc', name: 'Leclerc', isSelectedForComparison: true),
      ],
      primaryStore: const Store(id: 'carrefour', name: 'Carrefour', isPrimary: true),
    );

    expect(result.savingsVsPrimary, 6);
    expect(result.cheapest.storeId, 'leclerc');
  });

  test('useful savings threshold uses amount or percent', () {
    expect(isUsefulSavings(savings: 3.2, primaryBasketTotal: 40), isTrue);
    expect(isUsefulSavings(savings: 2.5, primaryBasketTotal: 20), isTrue);
    expect(isUsefulSavings(savings: 1.5, primaryBasketTotal: 20), isFalse);
  });
}
