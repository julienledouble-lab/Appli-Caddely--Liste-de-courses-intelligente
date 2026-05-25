import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/grocery_item.dart';
import 'package:caddely/utils/grocery_item_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mergeDuplicateGroceryItems merges duplicates and sums quantities', () {
    final merged = mergeDuplicateGroceryItems([
      GroceryItem(
        id: '1',
        name: ' lait ',
        quantity: 2,
        category: GroceryCategory.drinks,
        addedAt: DateTime(2026, 5, 20),
      ),
      GroceryItem(
        id: '2',
        name: 'Lait',
        quantity: 1,
        category: GroceryCategory.other,
        isPicked: true,
        addedAt: DateTime(2026, 5, 21),
      ),
    ]);

    expect(merged, hasLength(1));
    expect(merged.first.name, 'Lait');
    expect(merged.first.quantity, 3);
    expect(merged.first.category, GroceryCategory.drinks);
    expect(merged.first.isPicked, isFalse);
  });
}
