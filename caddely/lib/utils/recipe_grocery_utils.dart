import '../models/recipe_ingredient.dart';
import '../providers/grocery_provider.dart';
import 'recipe_ingredient_format_utils.dart';

class RecipeListAddResult {
  final int addedCount;
  final int duplicateCount;

  const RecipeListAddResult({
    required this.addedCount,
    required this.duplicateCount,
  });
}

Future<RecipeListAddResult> addSelectedIngredientsToGrocery({
  required GroceryProvider grocery,
  required Iterable<RecipeIngredient> ingredients,
}) async {
  var addedCount = 0;
  var duplicateCount = 0;

  for (final ingredient in ingredients.where((entry) => entry.isSelected)) {
    final result = await grocery.addItem(
      formatRecipeIngredientNameForGrocery(
        name: ingredient.name,
        quantity: ingredient.quantity,
      ),
      quantity: ingredient.groceryQuantity,
      category: ingredient.category,
    );

    switch (result) {
      case AddItemResult.added:
        addedCount++;
        break;
      case AddItemResult.duplicate:
        duplicateCount++;
        break;
      case AddItemResult.empty:
        break;
    }
  }

  return RecipeListAddResult(
    addedCount: addedCount,
    duplicateCount: duplicateCount,
  );
}
