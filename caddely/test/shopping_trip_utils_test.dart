import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/grocery_item.dart';
import 'package:caddely/utils/grocery_category_utils.dart';
import 'package:caddely/utils/shopping_trip_utils.dart';
import 'package:flutter_test/flutter_test.dart';

GroceryItem buildItem({
  required String id,
  required String name,
  required GroceryCategory category,
  required DateTime addedAt,
  bool isPicked = false,
  int quantity = 1,
}) {
  return GroceryItem(
    id: id,
    name: name,
    category: category,
    quantity: quantity,
    isPicked: isPicked,
    addedAt: addedAt,
  );
}

void main() {
  test('buildShoppingTripProgress computes picked, total and percent', () {
    final progress = buildShoppingTripProgress([
      buildItem(
        id: '1',
        name: 'Pommes',
        category: GroceryCategory.fruitsAndVegetables,
        addedAt: DateTime(2026, 5, 25),
      ),
      buildItem(
        id: '2',
        name: 'Lait',
        category: GroceryCategory.fresh,
        addedAt: DateTime(2026, 5, 25),
        isPicked: true,
      ),
      buildItem(
        id: '3',
        name: 'Pain',
        category: GroceryCategory.grocery,
        addedAt: DateTime(2026, 5, 25),
      ),
    ]);

    expect(progress.pickedCount, 1);
    expect(progress.totalCount, 3);
    expect(progress.pendingCount, 2);
    expect(progress.completionPercent, 33);
    expect(progress.summaryLabel, '1 sur 3 produits pris');
  });

  test('buildShoppingTripProgress handles empty list', () {
    final progress = buildShoppingTripProgress(const []);

    expect(progress.totalCount, 0);
    expect(progress.pickedCount, 0);
    expect(progress.completionRatio, 0);
  });

  test('findNextItemToPick returns first pending item in logical category order', () {
    final grouped = groupItemsByOrderedCategory([
      buildItem(
        id: '2',
        name: 'Lait',
        category: GroceryCategory.fresh,
        addedAt: DateTime(2026, 5, 25, 10),
      ),
      buildItem(
        id: '1',
        name: 'Pommes',
        category: GroceryCategory.fruitsAndVegetables,
        addedAt: DateTime(2026, 5, 25, 9),
      ),
    ]);

    final nextItem = findNextItemToPick(grouped);

    expect(nextItem?.name, 'Pommes');
  });

  test('findNextItemToPick returns null for empty grouped list', () {
    expect(findNextItemToPick(const {}), isNull);
  });
}
