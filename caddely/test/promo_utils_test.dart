import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/grocery_item.dart';
import 'package:caddely/models/promo.dart';
import 'package:caddely/models/promo_insight.dart';
import 'package:caddely/utils/promo_utils.dart';
import 'package:flutter_test/flutter_test.dart';

GroceryItem groceryItem({
  required String id,
  required String name,
  int quantity = 1,
}) {
  return GroceryItem(
    id: id,
    name: name,
    quantity: quantity,
    category: GroceryCategory.other,
    addedAt: DateTime(2026, 5, 25),
  );
}

Promo promo({
  required String id,
  required String productName,
  required String storeId,
  required String storeName,
  double originalPrice = 4,
  double promoPrice = 3,
}) {
  return Promo(
    id: id,
    productName: productName,
    storeId: storeId,
    storeName: storeName,
    originalPrice: originalPrice,
    promoPrice: promoPrice,
    validUntil: DateTime(2026, 5, 30),
  );
}

void main() {
  test('promo is shown when product is in current list', () {
    final insights = buildPromoInsights(
      promotions: [
        promo(
          id: 'p1',
          productName: 'Café moulu',
          storeId: 'carrefour',
          storeName: 'Carrefour',
        ),
      ],
      currentList: [
        groceryItem(id: '1', name: 'Café', quantity: 2),
      ],
      habitualProducts: const [],
      primaryStoreId: 'carrefour',
    );

    expect(insights, hasLength(1));
    expect(insights.single.reason, PromoReason.inCurrentList);
  });

  test('promo is shown when product is habitual', () {
    final insights = buildPromoInsights(
      promotions: [
        promo(
          id: 'p1',
          productName: 'Lessive liquide',
          storeId: 'intermarche',
          storeName: 'Intermarché',
        ),
      ],
      currentList: const [],
      habitualProducts: const ['Lessive'],
      primaryStoreId: 'carrefour',
    );

    expect(insights, hasLength(1));
    expect(insights.single.reason, PromoReason.habitualProduct);
  });

  test('promo is hidden when it has no link with user context', () {
    final insights = buildPromoInsights(
      promotions: [
        promo(
          id: 'p1',
          productName: 'Chips nature',
          storeId: 'carrefour',
          storeName: 'Carrefour',
        ),
      ],
      currentList: const [],
      habitualProducts: const ['Lait'],
      primaryStoreId: 'carrefour',
    );

    expect(insights, isEmpty);
  });

  test('unit savings is computed from promo prices', () {
    final insight = buildPromoInsights(
      promotions: [
        promo(
          id: 'p1',
          productName: 'Café moulu',
          storeId: 'carrefour',
          storeName: 'Carrefour',
          originalPrice: 4.29,
          promoPrice: 3.49,
        ),
      ],
      currentList: [
        groceryItem(id: '1', name: 'Café', quantity: 2),
      ],
      habitualProducts: const [],
      primaryStoreId: 'carrefour',
    ).single;

    expect(insight.unitSavings, closeTo(0.80, 0.001));
  });

  test('estimated savings uses quantity from current list', () {
    final insight = buildPromoInsights(
      promotions: [
        promo(
          id: 'p1',
          productName: 'Café moulu',
          storeId: 'carrefour',
          storeName: 'Carrefour',
          originalPrice: 4.29,
          promoPrice: 3.49,
        ),
      ],
      currentList: [
        groceryItem(id: '1', name: 'Café', quantity: 2),
      ],
      habitualProducts: const [],
      primaryStoreId: 'carrefour',
    ).single;

    expect(insight.estimatedSavings, closeTo(1.60, 0.001));
  });

  test('primary store promos are prioritized before secondary then others', () {
    final insights = buildPromoInsights(
      promotions: [
        promo(
          id: 'other',
          productName: 'Café moulu',
          storeId: 'auchan',
          storeName: 'Auchan',
        ),
        promo(
          id: 'secondary',
          productName: 'Café moulu',
          storeId: 'leclerc',
          storeName: 'Leclerc',
        ),
        promo(
          id: 'primary',
          productName: 'Café moulu',
          storeId: 'carrefour',
          storeName: 'Carrefour',
        ),
      ],
      currentList: [
        groceryItem(id: '1', name: 'Café'),
      ],
      habitualProducts: const [],
      primaryStoreId: 'carrefour',
      secondaryStoreIds: const {'leclerc'},
    );

    expect(insights.map((insight) => insight.promo.id).toList(), [
      'primary',
      'secondary',
      'other',
    ]);
  });

  test('comparedStores filter keeps only primary and secondary stores', () {
    final insights = buildPromoInsights(
      promotions: [
        promo(
          id: 'primary',
          productName: 'Café moulu',
          storeId: 'carrefour',
          storeName: 'Carrefour',
        ),
        promo(
          id: 'secondary',
          productName: 'Café moulu',
          storeId: 'leclerc',
          storeName: 'Leclerc',
        ),
        promo(
          id: 'other',
          productName: 'Café moulu',
          storeId: 'auchan',
          storeName: 'Auchan',
        ),
      ],
      currentList: [
        groceryItem(id: '1', name: 'Café'),
      ],
      habitualProducts: const [],
      primaryStoreId: 'carrefour',
      secondaryStoreIds: const {'leclerc'},
      filter: PromoFilter.comparedStores,
    );

    expect(insights.map((insight) => insight.promo.id).toList(), [
      'primary',
      'secondary',
    ]);
  });

  test('summary reports empty state cleanly', () {
    final summary = buildPromoSummary(
      const [],
      hasPrimaryStore: true,
    );

    expect(
      summary.summaryLabel(hasPrimaryStore: true),
      'Aucune promo utile pour le moment.',
    );
  });
}
