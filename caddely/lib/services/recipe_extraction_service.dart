import 'package:uuid/uuid.dart';

import '../models/grocery_category.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../utils/recipe_text_parser.dart';
import 'ocr_text_reader.dart';

class RecipeExtractionException implements Exception {
  final String userMessage;

  const RecipeExtractionException(this.userMessage);
}

class RecipeExtractionService {
  final OcrTextReader _ocrTextReader;
  final RecipeTextParser _parser;
  final Uuid _uuid;

  RecipeExtractionService({
    OcrTextReader? ocrTextReader,
    RecipeTextParser? parser,
    Uuid? uuid,
  })  : _ocrTextReader = ocrTextReader ?? createOcrTextReader(),
        _parser = parser ?? RecipeTextParser(uuid: uuid),
        _uuid = uuid ?? const Uuid();

  Future<Recipe> extractRecipeFromImage(String imagePath) {
    return extractRecipeFromImages([imagePath]);
  }

  /// Runs OCR on each image and returns the merged raw text.
  /// Throws [RecipeExtractionException] if no usable text is found.
  Future<String> extractRawTextFromImages(List<String> imagePaths) async {
    final normalizedPaths =
        imagePaths.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (normalizedPaths.isEmpty) {
      throw const RecipeExtractionException(
        'Impossible de lire cette image pour l\'instant. Tu peux essayer une autre image.',
      );
    }

    final extractedTexts = <String>[];
    final errors = <String>[];
    for (final imagePath in normalizedPaths) {
      try {
        final text = await _ocrTextReader.readTextFromImage(imagePath);
        if (text != null && text.trim().isNotEmpty) {
          extractedTexts.add(text.trim());
        }
      } catch (e) {
        errors.add(e.toString());
      }
    }

    if (extractedTexts.isEmpty) {
      final detail = errors.isNotEmpty ? '\n\nDétail : ${errors.first}' : '';
      throw RecipeExtractionException(
        'Impossible de lire cette image pour l\'instant. Tu peux essayer une autre image.$detail',
      );
    }

    return extractedTexts.join('\n\n');
  }

  Future<Recipe> extractRecipeFromImages(List<String> imagePaths) async {
    final normalizedPaths =
        imagePaths.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final rawText = await extractRawTextFromImages(normalizedPaths);
    return _parser.parse(
      rawText,
      imagePath: normalizedPaths.first,
      imagePaths: normalizedPaths,
      createdAt: DateTime.now(),
    );
  }

  /// Parses [rawText] directly into a [Recipe] without OCR.
  Recipe extractRecipeFromText(
    String rawText, {
    String? imagePath,
    List<String>? imagePaths,
  }) {
    return _parser.parse(
      rawText.trim(),
      imagePath: imagePath,
      imagePaths: imagePaths,
      createdAt: DateTime.now(),
      source: 'import_text',
    );
  }

  Recipe buildDemoRecipe({
    String? imagePath,
    List<String>? imagePaths,
  }) {
    return Recipe(
      id: _uuid.v4(),
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
          name: 'Creme fraiche',
          quantity: 20,
          unit: 'cl',
          category: GroceryCategory.fresh,
        ),
        RecipeIngredient(
          name: 'Oignon',
          quantity: 1,
          category: GroceryCategory.fruitsAndVegetables,
        ),
        RecipeIngredient(
          name: 'Parmesan',
          quantity: 50,
          unit: 'g',
          category: GroceryCategory.fresh,
        ),
        RecipeIngredient(
          name: 'Sel',
          category: GroceryCategory.grocery,
        ),
        RecipeIngredient(
          name: 'Poivre',
          category: GroceryCategory.grocery,
        ),
      ],
      steps: const [
        'Faire cuire les pates.',
        'Faire revenir l\'oignon.',
        'Ajouter le poulet.',
        'Ajouter la creme.',
        'Melanger avec les pates.',
        'Servir avec du parmesan.',
      ],
      source: 'import_image_demo',
      imagePath: imagePath,
      imagePaths: imagePaths,
      createdAt: DateTime.now(),
    );
  }
}
