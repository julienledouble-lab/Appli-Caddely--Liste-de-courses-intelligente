import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/recipe_ingredient.dart';
import 'package:caddely/providers/grocery_provider.dart';
import 'package:caddely/utils/recipe_grocery_utils.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_storage_service.dart';

void main() {
  test('adds only checked ingredients to grocery list', () async {
    final storage = FakeStorageService();
    final grocery = GroceryProvider(storage);
    await grocery.load();

    final result = await addSelectedIngredientsToGrocery(
      grocery: grocery,
      ingredients: const [
        RecipeIngredient(
          name: 'Lait',
          quantity: 2,
          unit: 'pièces',
          category: GroceryCategory.fresh,
        ),
        RecipeIngredient(
          name: 'Poivre',
          category: GroceryCategory.grocery,
          isSelected: false,
        ),
      ],
    );

    expect(result.addedCount, 1);
    expect(result.duplicateCount, 0);
    expect(storage.groceryItems, hasLength(1));
    expect(storage.groceryItems.single.name, 'Lait');
    expect(storage.groceryItems.single.quantity, 2);
  });

  test('keeps duplicates out when ingredient already exists', () async {
    final storage = FakeStorageService();
    final grocery = GroceryProvider(storage);
    await grocery.load();
    await grocery.addItem(
      'Café',
      quantity: 1,
      category: GroceryCategory.drinks,
    );

    final result = await addSelectedIngredientsToGrocery(
      grocery: grocery,
      ingredients: const [
        RecipeIngredient(
          name: 'Café',
          quantity: 2,
          unit: 'pièces',
          category: GroceryCategory.drinks,
        ),
      ],
    );

    expect(result.addedCount, 0);
    expect(result.duplicateCount, 1);
    expect(storage.groceryItems, hasLength(1));
  });

  test('adds a cleaned ingredient name to grocery list', () async {
    final storage = FakeStorageService();
    final grocery = GroceryProvider(storage);
    await grocery.load();

    final result = await addSelectedIngredientsToGrocery(
      grocery: grocery,
      ingredients: const [
        RecipeIngredient(
          name: 'Oeuf(s)',
          quantity: 2,
          category: GroceryCategory.fresh,
        ),
      ],
    );

    expect(result.addedCount, 1);
    expect(storage.groceryItems.single.name, 'Œufs');
    expect(storage.groceryItems.single.quantity, 2);
  });
}
