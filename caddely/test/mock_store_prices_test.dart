import 'package:caddely/data/mock_store_prices.dart';
import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/grocery_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculateLineTotal multiplies unit price by quantity', () {
    expect(calculateLineTotal(unitPrice: 4, quantity: 2), 8);
  });

  test('getStoreBasketsForItems includes quantities in totals', () {
    final baskets = getStoreBasketsForItems([
      GroceryItem(
        id: '1',
        name: 'Café moulu',
        quantity: 2,
        category: GroceryCategory.drinks,
        addedAt: DateTime(2026, 5, 24),
      ),
    ]);

    final carrefour = baskets.firstWhere((basket) => basket.storeName == 'Carrefour');
    expect(carrefour.storeId, 'carrefour');
    expect(carrefour.itemPrices.first.quantity, 2);
    expect(carrefour.itemPrices.first.unitPrice, closeTo(3.49, 0.001));
    expect(carrefour.itemPrices.first.totalPrice, closeTo(6.98, 0.001));
    expect(carrefour.totalPrice, closeTo(6.98, 0.001));
  });
}
