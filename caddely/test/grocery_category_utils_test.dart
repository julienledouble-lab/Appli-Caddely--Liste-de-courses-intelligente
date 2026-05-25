import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/grocery_item.dart';
import 'package:caddely/utils/grocery_category_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groupItemsByOrderedCategory groups items and respects shopping order', () {
    final grouped = groupItemsByOrderedCategory([
      GroceryItem(
        id: '1',
        name: 'Shampooing',
        category: GroceryCategory.hygiene,
        addedAt: DateTime(2026, 5, 24, 10, 3),
      ),
      GroceryItem(
        id: '2',
        name: 'Lait',
        category: GroceryCategory.fresh,
        addedAt: DateTime(2026, 5, 24, 10, 2),
      ),
      GroceryItem(
        id: '3',
        name: 'Pommes',
        category: GroceryCategory.fruitsAndVegetables,
        addedAt: DateTime(2026, 5, 24, 10, 1),
      ),
    ]);

    expect(
      grouped.keys.toList(),
      [
        GroceryCategory.fruitsAndVegetables,
        GroceryCategory.fresh,
        GroceryCategory.hygiene,
      ],
    );
    expect(grouped[GroceryCategory.fresh]!.single.name, 'Lait');
  });
}
