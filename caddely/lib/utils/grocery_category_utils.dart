import '../models/grocery_category.dart';
import '../models/grocery_item.dart';

const orderedGroceryCategories = <GroceryCategory>[
  GroceryCategory.fruitsAndVegetables,
  GroceryCategory.fresh,
  GroceryCategory.frozen,
  GroceryCategory.grocery,
  GroceryCategory.drinks,
  GroceryCategory.hygiene,
  GroceryCategory.home,
  GroceryCategory.other,
];

Map<GroceryCategory, List<GroceryItem>> groupItemsByOrderedCategory(
  List<GroceryItem> items,
) {
  final grouped = <GroceryCategory, List<GroceryItem>>{};

  for (final category in orderedGroceryCategories) {
    final categoryItems = items.where((item) => item.category == category).toList()
      ..sort((a, b) => a.addedAt.compareTo(b.addedAt));
    if (categoryItems.isNotEmpty) {
      grouped[category] = categoryItems;
    }
  }

  return grouped;
}
