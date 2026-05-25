import 'dart:typed_data';

import 'package:caddely/models/recipe.dart';
import 'package:caddely/providers/grocery_provider.dart';
import 'package:caddely/providers/recipes_provider.dart';
import 'package:caddely/screens/recipe_import_screen.dart';
import 'package:caddely/services/ocr_text_reader.dart';
import 'package:caddely/services/recipe_ai_extraction_service.dart';
import 'package:caddely/services/recipe_extraction_service.dart';
import 'package:caddely/utils/recipe_text_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'support/fake_storage_service.dart';

class FakeOcrTextReader implements OcrTextReader {
  final Future<String?> Function(String imagePath) onRead;

  FakeOcrTextReader(this.onRead);

  @override
  Future<String?> readTextFromImage(String imagePath) => onRead(imagePath);
}

class FakeRecipeAiExtractionService extends RecipeAiExtractionService {
  final Future<void> Function(List<RecipeAiImagePayload> images)? onExtract;

  FakeRecipeAiExtractionService({
    this.onExtract,
  }) : super(endpoint: 'https://example.test/analyze-recipe');

  @override
  Future<Recipe> extractRecipeFromImages(List<RecipeAiImagePayload> images) async {
    await onExtract?.call(images);
    return recipeFromJson(
      {
        'title': 'Pates au citron',
        'servings': 2,
        'prepTimeMinutes': 10,
        'cookTimeMinutes': 12,
        'ingredients': [
          {
            'name': 'Pates',
            'quantity': '200',
            'unit': 'g',
            'category': 'epicerie',
            'isSelected': true,
          },
        ],
        'steps': [
          'Faire cuire les pates.',
        ],
        'source': 'gemini_vision',
      },
      imagePaths: images.map((image) => image.path ?? '').where((path) => path.isNotEmpty).toList(),
    );
  }
}

class FailingRecipeAiExtractionService extends RecipeAiExtractionService {
  final String message;

  FailingRecipeAiExtractionService(this.message)
      : super(endpoint: 'https://example.test/analyze-recipe');

  @override
  Future<Recipe> extractRecipeFromImages(List<RecipeAiImagePayload> images) {
    throw RecipeAiExtractionException(message);
  }
}

XFile buildMemoryImage(String name) {
  return XFile.fromData(
    Uint8List.fromList([1, 2, 3, 4]),
    name: name,
    mimeType: 'image/png',
  );
}

Future<void> pumpRecipeImportScreen(
  WidgetTester tester, {
  required FakeStorageService storage,
  required RecipeExtractionService extractionService,
  RecipeAiExtractionService? aiExtractionService,
  required Future<List<XFile>> Function() onPickImages,
  List<XFile>? initialImages,
}) async {
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
        home: RecipeImportScreen(
          extractionService: extractionService,
          aiExtractionService: aiExtractionService,
          onPickImages: onPickImages,
          initialImages: initialImages,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('state without photo shows placeholder and disabled actions', (tester) async {
    final extractionService = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader((_) async => null),
    );

    await pumpRecipeImportScreen(
      tester,
      storage: FakeStorageService(),
      extractionService: extractionService,
      aiExtractionService: RecipeAiExtractionService(endpoint: ''),
      onPickImages: () async => const [],
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucune photo selectionnee'), findsOneWidget);
    expect(find.byKey(const Key('recipe-image-placeholder')), findsOneWidget);

    final aiButton = tester.widget<FilledButton>(
      find.byKey(const Key('analyze-recipe-with-ai')),
    );
    expect(aiButton.onPressed, isNull);

    final localButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('analyze-recipe-locally')),
    );
    expect(localButton.onPressed, isNull);
  });

  testWidgets('AI button is visible and local fallback remains available', (tester) async {
    final extractionService = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader((_) async => 'Titre\nIngredients\n1 lait'),
      parser: RecipeTextParser(),
    );

    await pumpRecipeImportScreen(
      tester,
      storage: FakeStorageService(),
      extractionService: extractionService,
      aiExtractionService: FakeRecipeAiExtractionService(),
      onPickImages: () async => [XFile('test/fixtures/recipe_a.png')],
      initialImages: [XFile('test/fixtures/recipe_a.png')],
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('analyze-recipe-with-ai')), findsOneWidget);
    expect(find.byKey(const Key('analyze-recipe-locally')), findsOneWidget);
  });

  testWidgets('selected photos can be analyzed with AI and open review screen', (tester) async {
    List<RecipeAiImagePayload>? capturedImages;
    final extractionService = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader((_) async => 'unused'),
    );
    final memoryImage = buildMemoryImage('recipe_a.png');

    await pumpRecipeImportScreen(
      tester,
      storage: FakeStorageService(),
      extractionService: extractionService,
      aiExtractionService: FakeRecipeAiExtractionService(
        onExtract: (images) async {
          capturedImages = images;
        },
      ),
      onPickImages: () async => [memoryImage],
      initialImages: [memoryImage],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('analyze-recipe-with-ai')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(capturedImages, isNotNull);
    expect(capturedImages, hasLength(1));
    expect(find.byKey(const Key('recipe-title-field')), findsOneWidget);
    expect(find.text('Pates au citron'), findsOneWidget);
  });

  testWidgets('backend error is shown cleanly and offers fallback actions', (tester) async {
    final extractionService = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader((_) async => 'Texte OCR'),
      parser: RecipeTextParser(),
    );
    final memoryImage = buildMemoryImage('recipe_a.png');

    await pumpRecipeImportScreen(
      tester,
      storage: FakeStorageService(),
      extractionService: extractionService,
      aiExtractionService: FailingRecipeAiExtractionService(
        'L’analyse IA n’est pas encore configurée.',
      ),
      onPickImages: () async => [memoryImage],
      initialImages: [memoryImage],
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('analyze-recipe-with-ai')));
    await tester.tap(find.byKey(const Key('analyze-recipe-with-ai')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recipe-analysis-error')), findsOneWidget);
    expect(find.text('L’analyse IA n’est pas encore configurée.'), findsOneWidget);
    expect(find.byKey(const Key('retry-ai-analysis')), findsOneWidget);
    expect(find.byKey(const Key('fallback-local-analysis')), findsOneWidget);
    expect(find.byKey(const Key('enter-text-manually')), findsOneWidget);
    expect(find.byKey(const Key('use-demo-recipe')), findsOneWidget);
  });

  testWidgets('503 error shows a friendly IA busy message', (tester) async {
    final extractionService = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader((_) async => 'Texte OCR'),
      parser: RecipeTextParser(),
    );
    final memoryImage = buildMemoryImage('recipe_a.png');

    await pumpRecipeImportScreen(
      tester,
      storage: FakeStorageService(),
      extractionService: extractionService,
      aiExtractionService: FailingRecipeAiExtractionService(
        'Le service IA est temporairement occupé. Réessaie dans quelques minutes.',
      ),
      onPickImages: () async => [memoryImage],
      initialImages: [memoryImage],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('analyze-recipe-with-ai')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();

    expect(
      find.text('Le service IA est temporairement occupé. Réessaie dans quelques minutes.'),
      findsOneWidget,
    );
  });

  testWidgets('unsupported format shows a friendly image format message', (tester) async {
    final extractionService = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader((_) async => 'Texte OCR'),
      parser: RecipeTextParser(),
    );
    final memoryImage = buildMemoryImage('recipe_a.png');

    await pumpRecipeImportScreen(
      tester,
      storage: FakeStorageService(),
      extractionService: extractionService,
      aiExtractionService: FailingRecipeAiExtractionService(
        'Format d’image non supporté. Essaie avec une image PNG, JPG ou WEBP.',
      ),
      onPickImages: () async => [memoryImage],
      initialImages: [memoryImage],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('analyze-recipe-with-ai')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();

    expect(
      find.text('Format d’image non supporté. Essaie avec une image PNG, JPG ou WEBP.'),
      findsOneWidget,
    );
  });

  testWidgets('local analysis still opens OCR text review screen', (tester) async {
    const ocrText = '''
Pates au poulet cremeux
Pour 2 personnes
Ingredients
200 g de pates
2 filets de poulet
''';

    final extractionService = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader(
        (imagePath) async => imagePath.endsWith('recipe_a.png') ? ocrText : '20 cl creme',
      ),
      parser: RecipeTextParser(),
    );

    await pumpRecipeImportScreen(
      tester,
      storage: FakeStorageService(),
      extractionService: extractionService,
      aiExtractionService: FakeRecipeAiExtractionService(),
      onPickImages: () async => [
        XFile('test/fixtures/recipe_a.png'),
        XFile('test/fixtures/recipe_b.png'),
      ],
      initialImages: [
        XFile('test/fixtures/recipe_a.png'),
        XFile('test/fixtures/recipe_b.png'),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('analyze-recipe-locally')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ocr-text-field')), findsOneWidget);
    expect(find.byKey(const Key('transform-to-recipe-button')), findsOneWidget);
  });

  testWidgets('shows a clean fallback when preview cannot be displayed', (tester) async {
    final extractionService = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader((_) async => 'Titre\nIngredients\n1 lait'),
    );

    await pumpRecipeImportScreen(
      tester,
      storage: FakeStorageService(),
      extractionService: extractionService,
      aiExtractionService: FakeRecipeAiExtractionService(),
      onPickImages: () async => [XFile('test/fixtures/missing.png')],
      initialImages: [XFile('test/fixtures/missing.png')],
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recipe-image-error-fallback-0')), findsOneWidget);
  });
}
