import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/providers/history_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_storage_service.dart';

void main() {
  test('recordPurchase ignores repeated toggles inside duplicate window', () async {
    final storage = FakeStorageService();
    final provider = HistoryProvider(storage);

    await provider.recordPurchase(
      'Lait',
      quantity: 2,
      category: GroceryCategory.fresh,
      now: DateTime(2026, 5, 24, 10, 0),
    );
    await provider.recordPurchase(
      ' lait ',
      quantity: 2,
      category: GroceryCategory.fresh,
      now: DateTime(2026, 5, 24, 10, 1),
    );
    await provider.recordPurchase(
      'LAIT',
      quantity: 2,
      category: GroceryCategory.fresh,
      now: DateTime(2026, 5, 24, 10, 3),
    );

    expect(provider.records, hasLength(1));
    expect(provider.records.first.productName, 'Lait');
    expect(provider.records.first.purchaseCount, 2);
  });

  test('suggestions reuse preferred quantity and category from history', () async {
    final storage = FakeStorageService();
    final provider = HistoryProvider(storage);

    await provider.recordPurchase(
      'Lait',
      quantity: 2,
      category: GroceryCategory.fresh,
      now: DateTime(2026, 5, 24, 10, 0),
    );
    await provider.recordPurchase(
      'Lait',
      quantity: 2,
      category: GroceryCategory.fresh,
      now: DateTime(2026, 5, 24, 10, 3),
    );
    await provider.recordPurchase(
      'Lait',
      quantity: 1,
      category: GroceryCategory.drinks,
      now: DateTime(2026, 5, 24, 10, 6),
    );

    final suggestions = provider.suggestionsForQuery(
      query: 'la',
      excludedNames: <String>{},
    );

    expect(suggestions, hasLength(1));
    expect(suggestions.first.productName, 'Lait');
    expect(suggestions.first.quantity, 2);
    expect(suggestions.first.category, GroceryCategory.fresh);
  });
}
