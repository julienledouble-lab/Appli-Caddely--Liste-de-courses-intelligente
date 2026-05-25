import '../models/grocery_category.dart';
import '../models/grocery_item.dart';
import 'product_name_utils.dart';

List<GroceryItem> mergeDuplicateGroceryItems(List<GroceryItem> source) {
  final merged = <String, GroceryItem>{};

  for (final item in source) {
    final cleanedName = cleanProductName(item.name);
    if (cleanedName.isEmpty) {
      continue;
    }

    final normalizedItem = item.copyWith(
      name: cleanedName,
      quantity: item.quantity < 1 ? 1 : item.quantity,
      category: item.category,
    );
    final key = normalizeProductName(cleanedName);
    final existing = merged[key];

    if (existing == null) {
      merged[key] = normalizedItem;
      continue;
    }

    final mergedItem = GroceryItem(
      id: existing.id,
      name: normalizedItem.addedAt.isAfter(existing.addedAt)
          ? normalizedItem.name
          : existing.name,
      quantity: existing.quantity + normalizedItem.quantity,
      category: _mergeCategory(existing.category, normalizedItem.category),
      isPicked: existing.isPicked && normalizedItem.isPicked,
      addedAt: existing.addedAt.isAfter(normalizedItem.addedAt)
          ? existing.addedAt
          : normalizedItem.addedAt,
    );

    merged[key] = mergedItem;
  }

  return merged.values.toList()
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
}

GroceryCategory _mergeCategory(
  GroceryCategory first,
  GroceryCategory second,
) {
  if (first != GroceryCategory.other) {
    return first;
  }

  return second;
}

GroceryCategory bestCategoryFromItems(List<GroceryItem> items) {
  final counts = <GroceryCategory, int>{};

  for (final item in items) {
    counts.update(item.category, (value) => value + 1, ifAbsent: () => 1);
  }

  if (counts.isEmpty) {
    return GroceryCategory.other;
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final compare = b.value.compareTo(a.value);
      if (compare != 0) return compare;
      return a.key.index.compareTo(b.key.index);
    });
  return sorted.first.key;
}
