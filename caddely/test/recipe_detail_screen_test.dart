import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/recipe.dart';
import 'package:caddely/models/recipe_ingredient.dart';
import 'package:caddely/providers/grocery_provider.dart';
import 'package:caddely/providers/recipes_provider.dart';
import 'package:caddely/screens/recipe_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/fake_storage_service.dart';

Future<void> pumpRecipeDetailScreen(WidgetTester tester) async {
  final storage = FakeStorageService();
  final groceryProvider = GroceryProvider(storage);
  final recipesProvider = RecipesProvider(storage);
  await Future.wait([
    groceryProvider.load(),
    recipesProvider.load(),
  ]);

  await recipesProvider.saveRecipe(
    Recipe(
      id: 'recipe-detail',
      title: 'Pâtes au poulet',
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
      steps: const ['Faire cuire les pâtes.'],
      source: 'gemini_vision',
      imagePath: 'mock_gallery/recipe_capture_1.png',
      imagePaths: const [
        'mock_gallery/recipe_capture_1.png',
        'mock_gallery/recipe_capture_2.png',
      ],
      createdAt: DateTime(2026, 5, 25, 10),
    ),
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: groceryProvider),
        ChangeNotifierProvider.value(value: recipesProvider),
      ],
      child: const MaterialApp(
        home: RecipeDetailScreen(recipeId: 'recipe-detail'),
      ),
    ),
  );
}

void main() {
  testWidgets('saved recipe detail does not display imported source photos', (tester) async {
    await pumpRecipeDetailScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Pâtes au poulet'), findsAtLeastNWidgets(1));
    expect(find.text('2 photos importees'), findsNothing);
    expect(find.text('mock_gallery/recipe_capture_1.png'), findsNothing);
    expect(find.byIcon(Icons.photo_outlined), findsNothing);
    expect(find.text('Ingrédients'), findsOneWidget);
    expect(find.text('Étapes'), findsOneWidget);
  });
}
