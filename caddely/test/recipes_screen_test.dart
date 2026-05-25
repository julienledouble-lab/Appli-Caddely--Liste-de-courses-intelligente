import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/recipe.dart';
import 'package:caddely/models/recipe_ingredient.dart';
import 'package:caddely/providers/recipes_provider.dart';
import 'package:caddely/screens/recipes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/fake_storage_service.dart';

Recipe buildSavedRecipe() {
  return Recipe(
    id: 'recipe-1',
    title: 'Pâtes au poulet crémeux',
    servings: 2,
    prepTimeMinutes: 10,
    cookTimeMinutes: 20,
    ingredients: const [
      RecipeIngredient(
        name: 'Pâtes',
        quantity: 200,
        unit: 'g',
        category: GroceryCategory.grocery,
      ),
    ],
    steps: const ['Cuire les pâtes'],
    source: 'test',
    createdAt: DateTime(2026, 5, 25, 10),
  );
}

Future<void> pumpRecipesScreen(
  WidgetTester tester, {
  required FakeStorageService storage,
}) async {
  final recipesProvider = RecipesProvider(storage);
  await recipesProvider.load();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: recipesProvider),
      ],
      child: const MaterialApp(home: RecipesScreen()),
    ),
  );
}

void main() {
  testWidgets('shows empty state when no recipe is saved', (tester) async {
    await pumpRecipesScreen(tester, storage: FakeStorageService());
    await tester.pumpAndSettle();

    expect(find.text('Aucune recette enregistrée'), findsOneWidget);
    expect(find.text('Importer une recette'), findsOneWidget);
  });

  testWidgets('shows saved recipes list', (tester) async {
    final storage = FakeStorageService()..recipes = [buildSavedRecipe()];

    await pumpRecipesScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    expect(find.text('Pâtes au poulet crémeux'), findsOneWidget);
    expect(find.textContaining('1 ingrédient'), findsOneWidget);
  });
}
