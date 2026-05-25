import 'package:caddely/providers/grocery_provider.dart';
import 'package:caddely/providers/recipes_provider.dart';
import 'package:caddely/screens/recipe_ocr_text_review_screen.dart';
import 'package:caddely/services/recipe_extraction_service.dart';
import 'package:caddely/utils/recipe_text_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/fake_storage_service.dart';

Future<void> pumpOcrTextReviewScreen(
  WidgetTester tester, {
  String? initialText,
  List<String>? imagePaths,
  RecipeExtractionService? extractionService,
}) async {
  final storage = FakeStorageService();
  final groceryProvider = GroceryProvider(storage);
  final recipesProvider = RecipesProvider(storage);
  await Future.wait([groceryProvider.load(), recipesProvider.load()]);

  final service = extractionService ??
      RecipeExtractionService(parser: RecipeTextParser());

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: groceryProvider),
        ChangeNotifierProvider.value(value: recipesProvider),
      ],
      child: MaterialApp(
        home: RecipeOcrTextReviewScreen(
          initialText: initialText,
          imagePaths: imagePaths,
          extractionService: service,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows "Texte détecté" title when OCR text is provided', (tester) async {
    await pumpOcrTextReviewScreen(
      tester,
      initialText: 'Pates au poulet\nIngredients\n200 g pates',
    );
    await tester.pumpAndSettle();

    expect(find.text('Texte détecté'), findsOneWidget);
    expect(find.byKey(const Key('ocr-text-field')), findsOneWidget);
    expect(find.byKey(const Key('transform-to-recipe-button')), findsOneWidget);
    expect(find.byKey(const Key('ocr-use-demo-recipe')), findsOneWidget);
  });

  testWidgets('shows "Saisir une recette" title in paste mode (no initial text)', (tester) async {
    await pumpOcrTextReviewScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Saisir une recette'), findsOneWidget);
  });

  testWidgets('OCR text is pre-filled in the editable field', (tester) async {
    const ocrText = 'Tarte aux pommes\nIngredients\n3 pommes\n200 g farine';
    await pumpOcrTextReviewScreen(tester, initialText: ocrText);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byKey(const Key('ocr-text-field')));
    expect(field.controller!.text, ocrText);
  });

  testWidgets('user can edit the text field', (tester) async {
    await pumpOcrTextReviewScreen(tester, initialText: 'Texte initial');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ocr-text-field')));
    await tester.enterText(find.byKey(const Key('ocr-text-field')), 'Texte corrige');
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byKey(const Key('ocr-text-field')));
    expect(field.controller!.text, 'Texte corrige');
  });

  testWidgets('empty text shows validation error', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpOcrTextReviewScreen(tester);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('transform-to-recipe-button')));
    await tester.tap(find.byKey(const Key('transform-to-recipe-button')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ocr-text-empty-error')), findsOneWidget);
    expect(find.text('Verifier la recette'), findsNothing);
  });

  testWidgets('valid text navigates to recipe review screen', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const text = '''
Pates au poulet cremeux
Pour 2 personnes
Preparation : 10 min
Cuisson : 20 min
Ingredients
200 g de pates
2 filets de poulet
Etapes
1. Faire cuire les pates.
2. Ajouter le poulet.
''';
    await pumpOcrTextReviewScreen(tester, initialText: text);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('transform-to-recipe-button')));
    await tester.tap(find.byKey(const Key('transform-to-recipe-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recipe-title-field')), findsOneWidget);
  });

  testWidgets('corrected text is used when transforming', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = RecipeExtractionService(parser: RecipeTextParser());

    await pumpOcrTextReviewScreen(
      tester,
      initialText: 'Texte OCR brut incorrect',
      extractionService: service,
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('ocr-text-field')),
      'Soupe de tomates\nIngredients\n4 tomates\nEtapes\n1. Mixer.',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('transform-to-recipe-button')));
    await tester.tap(find.byKey(const Key('transform-to-recipe-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recipe-title-field')), findsOneWidget);
    expect(find.text('Soupe de tomates'), findsOneWidget);
  });

  testWidgets('demo recipe button navigates to recipe review screen', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpOcrTextReviewScreen(tester);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('ocr-use-demo-recipe')));
    await tester.tap(find.byKey(const Key('ocr-use-demo-recipe')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recipe-title-field')), findsOneWidget);
    expect(find.text('Pates au poulet cremeux'), findsOneWidget);
  });

  testWidgets('paste mode with text transforms correctly', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpOcrTextReviewScreen(tester);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('ocr-text-field')),
      'Omelette rapide\nIngredients\n3 oeufs\nEtapes\n1. Battre les oeufs.',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('transform-to-recipe-button')));
    await tester.tap(find.byKey(const Key('transform-to-recipe-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recipe-title-field')), findsOneWidget);
    expect(find.text('Omelette rapide'), findsOneWidget);
  });

  testWidgets('validation error clears when user types', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpOcrTextReviewScreen(tester);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('transform-to-recipe-button')));
    await tester.tap(find.byKey(const Key('transform-to-recipe-button')));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ocr-text-empty-error')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('ocr-text-field')), 'Quelque chose');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ocr-text-empty-error')), findsNothing);
  });

  testWidgets('imagePaths are forwarded — multi-image hint shown in review', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpOcrTextReviewScreen(
      tester,
      initialText: 'Quiche\nIngredients\n3 oeufs\nEtapes\n1. Cuire.',
      imagePaths: const ['photo_a.jpg', 'photo_b.jpg'],
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('transform-to-recipe-button')));
    await tester.tap(find.byKey(const Key('transform-to-recipe-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recipe-multi-image-hint')), findsOneWidget);
  });
}
