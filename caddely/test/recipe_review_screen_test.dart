import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/recipe.dart';
import 'package:caddely/models/recipe_ingredient.dart';
import 'package:caddely/providers/grocery_provider.dart';
import 'package:caddely/providers/recipes_provider.dart';
import 'package:caddely/screens/recipe_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/fake_storage_service.dart';

Recipe buildRecipeForReview() {
  return Recipe(
    id: 'recipe-review',
    title: 'Pates au poulet cremeux',
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
      RecipeIngredient(
        name: 'Poivre',
        category: GroceryCategory.grocery,
        isSelected: false,
      ),
    ],
    steps: const [
      'Faire cuire les pates.',
      'Faire revenir le poulet.',
    ],
    source: 'mock',
    imagePath: 'mock_gallery/recipe_capture_1.png',
    imagePaths: const [
      'mock_gallery/recipe_capture_1.png',
      'mock_gallery/recipe_capture_2.png',
    ],
    createdAt: DateTime(2026, 5, 25, 10),
  );
}

Future<FakeStorageService> pumpRecipeReviewScreen(
  WidgetTester tester, {
  Recipe? recipe,
}) async {
  tester.view.physicalSize = const Size(430, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final storage = FakeStorageService();
  final groceryProvider = GroceryProvider(storage);
  final recipesProvider = RecipesProvider(storage);
  await Future.wait([
    groceryProvider.load(),
    recipesProvider.load(),
  ]);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: groceryProvider),
        ChangeNotifierProvider.value(value: recipesProvider),
      ],
      child: MaterialApp(
        home: RecipeReviewScreen(
          initialRecipe: recipe ?? buildRecipeForReview(),
        ),
      ),
    ),
  );

  return storage;
}

Future<void> openIngredientEditor(WidgetTester tester, int index) async {
  final finder = find.byKey(Key('edit-ingredient-$index'));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> saveIngredientEditor(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('save-ingredient-button')));
  await tester.tap(find.byKey(const Key('save-ingredient-button')));
  await tester.pumpAndSettle();
}

Future<void> selectCategory(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const Key('ingredient-category-field')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ocr recipe review is displayed correctly', (tester) async {
    await pumpRecipeReviewScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recipe-title-field')), findsOneWidget);
    expect(find.byKey(const Key('recipe-multi-image-hint')), findsOneWidget);
    expect(find.text('Poulet'), findsOneWidget);
    expect(find.byKey(const Key('save-recipe-button')), findsOneWidget);
    expect(find.byKey(const Key('add-ingredient-button')), findsOneWidget);
  });

  testWidgets('ingredient name can be edited', (tester) async {
    await pumpRecipeReviewScreen(tester);
    await tester.pumpAndSettle();

    await openIngredientEditor(tester, 0);
    await tester.enterText(find.byKey(const Key('ingredient-name-field')), 'Pates completes');
    await saveIngredientEditor(tester);

    expect(find.text('Pates completes'), findsOneWidget);
  });

  testWidgets('ingredient quantity unit and category can be edited', (tester) async {
    await pumpRecipeReviewScreen(tester);
    await tester.pumpAndSettle();

    await openIngredientEditor(tester, 1);
    await tester.enterText(find.byKey(const Key('ingredient-quantity-field')), '3');
    await tester.enterText(find.byKey(const Key('ingredient-unit-field')), 'pieces');
    await selectCategory(tester, 'Maison');
    await saveIngredientEditor(tester);

    expect(find.byKey(const Key('ingredient-subtitle-1')), findsOneWidget);
    expect(find.text('3 pieces - Maison'), findsOneWidget);
  });

  testWidgets('a missing ingredient can be added', (tester) async {
    await pumpRecipeReviewScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-ingredient-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('ingredient-name-field')), 'Creme');
    await tester.enterText(find.byKey(const Key('ingredient-quantity-field')), '1');
    await tester.enterText(find.byKey(const Key('ingredient-unit-field')), 'pot');
    await selectCategory(tester, 'Frais');
    await saveIngredientEditor(tester);

    expect(find.text('Creme'), findsOneWidget);
    expect(find.text('1 pot - Frais'), findsOneWidget);
  });

  testWidgets('an unwanted ingredient can be deleted', (tester) async {
    await pumpRecipeReviewScreen(tester);
    await tester.pumpAndSettle();

    await openIngredientEditor(tester, 2);
    await tester.tap(find.byKey(const Key('delete-ingredient-button')));
    await tester.pumpAndSettle();

    expect(find.text('Poivre'), findsNothing);
  });

  testWidgets('recipe from multiple photos can be saved locally', (tester) async {
    final storage = await pumpRecipeReviewScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-recipe-button')));
    await tester.pumpAndSettle();

    expect(storage.recipes, hasLength(1));
    expect(storage.recipes.single.title, 'Pates au poulet cremeux');
    expect(storage.recipes.single.imagePaths, hasLength(2));
  });

  testWidgets('corrected ingredients are the ones added to the grocery list', (tester) async {
    final storage = await pumpRecipeReviewScreen(tester);
    await tester.pumpAndSettle();

    await openIngredientEditor(tester, 0);
    await tester.enterText(find.byKey(const Key('ingredient-name-field')), 'Cafe');
    await tester.enterText(find.byKey(const Key('ingredient-quantity-field')), '3');
    await tester.enterText(find.byKey(const Key('ingredient-unit-field')), 'pieces');
    await selectCategory(tester, 'Boissons');
    await saveIngredientEditor(tester);

    await tester.tap(find.byKey(const Key('add-recipe-ingredients-button')));
    await tester.pumpAndSettle();

    final added = storage.groceryItems.firstWhere((item) => item.name == 'Café');
    expect(added.quantity, 3);
    expect(added.category, GroceryCategory.drinks);
    expect(storage.groceryItems.any((item) => item.name == 'Pates'), isFalse);
  });

  testWidgets('unchecked ingredients are still excluded from grocery list', (tester) async {
    final storage = await pumpRecipeReviewScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-recipe-ingredients-button')));
    await tester.pumpAndSettle();

    expect(storage.groceryItems.map((item) => item.name).toSet(), {
      'Pâtes',
      'Poulet',
    });
    expect(storage.groceryItems.any((item) => item.name == 'Poivre'), isFalse);
    expect(storage.history, isEmpty);
  });
}
