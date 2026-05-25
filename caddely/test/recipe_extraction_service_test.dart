import 'package:caddely/services/ocr_text_reader.dart';
import 'package:caddely/services/recipe_extraction_service.dart';
import 'package:caddely/utils/recipe_text_parser.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeOcrTextReader implements OcrTextReader {
  final Future<String?> Function(String imagePath) onRead;

  FakeOcrTextReader(this.onRead);

  @override
  Future<String?> readTextFromImage(String imagePath) => onRead(imagePath);
}

void main() {
  test('returns parsed recipe when OCR text is available', () async {
    final service = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader(
        (_) async => '''
Pates au poulet cremeux
Pour 2 personnes
Preparation : 10 min
Cuisson : 20 min
Ingredients
200 g de pates
2 filets de poulet
Etapes
1. Faire cuire les pates.
''',
      ),
      parser: RecipeTextParser(),
    );

    final recipe = await service.extractRecipeFromImage('sample.png');

    expect(recipe.title, 'Pates au poulet cremeux');
    expect(recipe.imagePath, 'sample.png');
    expect(recipe.imagePaths, ['sample.png']);
    expect(recipe.source, 'import_image_ocr');
  });

  test('extractRecipeFromImages merges OCR texts in order', () async {
    final service = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader(
        (imagePath) async {
          if (imagePath == 'ingredients.png') {
            return '''
Pates au poulet cremeux
Pour 2 personnes
Preparation : 10 min
Cuisson : 20 min
Ingredients
200 g de pates
2 filets de poulet
''';
          }

          return '''
20 cl de creme fraiche
1 oignon
Etapes
1. Faire revenir l'oignon.
2. Ajouter le poulet.
''';
        },
      ),
      parser: RecipeTextParser(),
    );

    final recipe = await service.extractRecipeFromImages([
      'ingredients.png',
      'steps.png',
    ]);

    expect(recipe.title, 'Pates au poulet cremeux');
    expect(recipe.imagePaths, ['ingredients.png', 'steps.png']);
    expect(recipe.ingredients.map((entry) => entry.name), containsAll(['Pates', 'Poulet', 'Creme fraiche', 'Oignon']));
    expect(recipe.steps, ['Faire revenir l\'oignon.', 'Ajouter le poulet.']);
  });

  test('continues extraction when one image fails and another succeeds', () async {
    final service = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader(
        (imagePath) async {
          if (imagePath == 'broken.png') {
            throw Exception('ocr error');
          }

          return '''
Recette rapide
Ingredients
1 oignon
Etapes
1. Emincer.
''';
        },
      ),
      parser: RecipeTextParser(),
    );

    final recipe = await service.extractRecipeFromImages([
      'broken.png',
      'usable.png',
    ]);

    expect(recipe.title, 'Recette rapide');
    expect(recipe.imagePaths, ['broken.png', 'usable.png']);
    expect(recipe.ingredients.single.name, 'Oignon');
  });

  test('throws a clean exception when all images fail', () async {
    final service = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader((_) async => null),
      parser: RecipeTextParser(),
    );

    expect(
      () => service.extractRecipeFromImages(['missing-a.png', 'missing-b.png']),
      throwsA(
        isA<RecipeExtractionException>().having(
          (error) => error.userMessage,
          'userMessage',
          contains('Impossible de lire cette image'),
        ),
      ),
    );
  });

  test('extractRawTextFromImages returns merged OCR text', () async {
    final service = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader(
        (imagePath) async => imagePath == 'a.png' ? 'Texte A' : 'Texte B',
      ),
    );

    final text = await service.extractRawTextFromImages(['a.png', 'b.png']);

    expect(text, contains('Texte A'));
    expect(text, contains('Texte B'));
  });

  test('extractRawTextFromImages throws when all images return null', () async {
    final service = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader((_) async => null),
    );

    expect(
      () => service.extractRawTextFromImages(['x.png']),
      throwsA(isA<RecipeExtractionException>()),
    );
  });

  test('extractRecipeFromText parses raw text into a recipe', () {
    final service = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader((_) async => null),
      parser: RecipeTextParser(),
    );

    final recipe = service.extractRecipeFromText(
      '''
Tarte aux pommes
Pour 4 personnes
Ingredients
3 pommes
200 g de farine
Etapes
1. Melanger.
2. Enfourner.
''',
      imagePath: 'photo.jpg',
      imagePaths: ['photo.jpg'],
    );

    expect(recipe.title, 'Tarte aux pommes');
    expect(recipe.servings, 4);
    expect(recipe.ingredients.map((e) => e.name), containsAll(['Pommes', 'Farine']));
    expect(recipe.steps, isNotEmpty);
    expect(recipe.source, 'import_text');
    expect(recipe.imagePath, 'photo.jpg');
  });

  test('extractRecipeFromText with empty text returns fallback recipe', () {
    final service = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader((_) async => null),
      parser: RecipeTextParser(),
    );

    final recipe = service.extractRecipeFromText('   ');

    expect(recipe.title, 'Recette importee');
    expect(recipe.source, 'import_text');
  });

  test('can build a demo recipe as fallback', () {
    final service = RecipeExtractionService(
      ocrTextReader: FakeOcrTextReader((_) async => null),
      parser: RecipeTextParser(),
    );

    final recipe = service.buildDemoRecipe(
      imagePath: 'demo-a.png',
      imagePaths: ['demo-a.png', 'demo-b.png'],
    );

    expect(recipe.title, 'Pates au poulet cremeux');
    expect(recipe.imagePath, 'demo-a.png');
    expect(recipe.imagePaths, ['demo-a.png', 'demo-b.png']);
    expect(recipe.ingredients, isNotEmpty);
  });
}
