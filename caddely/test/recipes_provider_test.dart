import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/recipe.dart';
import 'package:caddely/models/recipe_ingredient.dart';
import 'package:caddely/providers/recipes_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_storage_service.dart';

Recipe buildRecipe({
  String id = 'recipe-1',
  String title = 'Pates au poulet cremeux',
}) {
  return Recipe(
    id: id,
    title: title,
    servings: 2,
    prepTimeMinutes: 10,
    cookTimeMinutes: 20,
    ingredients: const [
      RecipeIngredient(
        name: 'Pates',
        quantity: 200,
        unit: 'g',
        category: GroceryCategory.grocery,
      ),
      RecipeIngredient(
        name: 'Poulet',
        quantity: 2,
        unit: 'filets',
        category: GroceryCategory.fresh,
      ),
    ],
    steps: const ['Cuire les pates', 'Ajouter le poulet'],
    source: 'test',
    imagePath: 'recipe-a.png',
    imagePaths: const ['recipe-a.png', 'recipe-b.png'],
    createdAt: DateTime(2026, 5, 25, 10),
  );
}

void main() {
  test('loads saved recipes from storage', () async {
    final storage = FakeStorageService()..recipes = [buildRecipe()];
    final provider = RecipesProvider(storage);

    await provider.load();

    expect(provider.isLoading, isFalse);
    expect(provider.recipes, hasLength(1));
    expect(provider.recipes.single.title, 'Pates au poulet cremeux');
  });

  test('saveRecipe persists recipe locally', () async {
    final storage = FakeStorageService();
    final provider = RecipesProvider(storage);
    await provider.load();

    final recipe = buildRecipe();
    await provider.saveRecipe(recipe);

    expect(storage.recipes, hasLength(1));
    expect(storage.recipes.single.id, recipe.id);
    expect(provider.recipeById(recipe.id)?.title, recipe.title);
  });

  test('saved recipes keep multiple image paths', () async {
    final storage = FakeStorageService();
    final provider = RecipesProvider(storage);
    await provider.load();

    final recipe = buildRecipe();
    await provider.saveRecipe(recipe);

    final restored = storage.recipes.single;
    expect(restored.imagePath, 'recipe-a.png');
    expect(restored.imagePaths, ['recipe-a.png', 'recipe-b.png']);
  });
}
