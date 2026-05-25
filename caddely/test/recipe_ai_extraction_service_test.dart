import 'dart:convert';
import 'dart:typed_data';

import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/services/recipe_ai_extraction_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FakeHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) onSend;

  FakeHttpClient(this.onSend);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => onSend(request);
}

RecipeAiImagePayload buildImagePayload(String path) {
  return RecipeAiImagePayload(
    fileName: path.split('/').last,
    path: path,
    bytes: Uint8List.fromList([1, 2, 3, 4]),
  );
}

void main() {
  test('valid Gemini JSON is transformed into a recipe', () async {
    final client = FakeHttpClient((request) async {
      final response = jsonEncode({
        'title': 'Pates au poulet',
        'servings': 2,
        'prepTimeMinutes': 10,
        'cookTimeMinutes': 20,
        'ingredients': [
          {
            'name': 'Pates',
            'quantity': '200',
            'unit': 'g',
            'category': 'epicerie',
            'isSelected': true,
          },
        ],
        'steps': ['Faire cuire les pates.'],
        'source': 'gemini_vision',
      });

      return http.StreamedResponse(
        Stream.value(utf8.encode(response)),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = RecipeAiExtractionService(
      client: client,
      endpoint: 'https://example.test/analyze-recipe',
    );

    final recipe = await service.extractRecipeFromImages([
      buildImagePayload('recipe.png'),
    ]);

    expect(recipe.title, 'Pates au poulet');
    expect(recipe.servings, 2);
    expect(recipe.ingredients.single.category, GroceryCategory.grocery);
    expect(recipe.imagePaths, ['recipe.png']);
  });

  test('incomplete JSON does not crash and uses defaults', () async {
    final client = FakeHttpClient((request) async {
      final response = jsonEncode({
        'ingredients': [
          {
            'name': 'Oignon',
          },
        ],
      });

      return http.StreamedResponse(
        Stream.value(utf8.encode(response)),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = RecipeAiExtractionService(
      client: client,
      endpoint: 'https://example.test/analyze-recipe',
    );

    final recipe = await service.extractRecipeFromImages([
      buildImagePayload('recipe.png'),
    ]);

    expect(recipe.title, 'Recette importee');
    expect(recipe.servings, 1);
    expect(recipe.ingredients.single.name, 'Oignon');
    expect(recipe.ingredients.single.category, GroceryCategory.other);
  });

  test('backend errors are surfaced with a clean message', () async {
    final client = FakeHttpClient((request) async {
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({'error': 'Service indisponible'}))),
        502,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = RecipeAiExtractionService(
      client: client,
      endpoint: 'https://example.test/analyze-recipe',
    );

    expect(
      () => service.extractRecipeFromImages([buildImagePayload('recipe.png')]),
      throwsA(
        isA<RecipeAiExtractionException>().having(
          (error) => error.userMessage,
          'userMessage',
          'Le service IA est temporairement indisponible. Réessaie un peu plus tard ou utilise l’analyse locale.',
        ),
      ),
    );
  });

  test('503 high demand is mapped to a friendly message', () async {
    final client = FakeHttpClient((request) async {
      return http.StreamedResponse(
        Stream.value(
          utf8.encode(
            jsonEncode({
              'status': 'UNAVAILABLE',
              'message': 'This model is currently experiencing high demand.',
            }),
          ),
        ),
        503,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = RecipeAiExtractionService(
      client: client,
      endpoint: 'https://example.test/analyze-recipe',
    );

    expect(
      () => service.extractRecipeFromImages([buildImagePayload('recipe.png')]),
      throwsA(
        isA<RecipeAiExtractionException>().having(
          (error) => error.userMessage,
          'userMessage',
          'Le service IA est temporairement occupé. Réessaie dans quelques minutes.',
        ),
      ),
    );
  });

  test('unsupported mime type is mapped to a friendly message', () async {
    final client = FakeHttpClient((request) async {
      return http.StreamedResponse(
        Stream.value(
          utf8.encode(
            jsonEncode({
              'error': 'Unsupported MIME type: application/octet-stream',
            }),
          ),
        ),
        400,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = RecipeAiExtractionService(
      client: client,
      endpoint: 'https://example.test/analyze-recipe',
    );

    expect(
      () => service.extractRecipeFromImages([buildImagePayload('recipe.png')]),
      throwsA(
        isA<RecipeAiExtractionException>().having(
          (error) => error.userMessage,
          'userMessage',
          'Format d’image non supporté. Essaie avec une image PNG, JPG ou WEBP.',
        ),
      ),
    );
  });

  test('missing endpoint shows a configuration error', () async {
    final service = RecipeAiExtractionService(endpoint: '');

    expect(
      () => service.extractRecipeFromImages([buildImagePayload('recipe.png')]),
      throwsA(
        isA<RecipeAiExtractionException>().having(
          (error) => error.userMessage,
          'userMessage',
          'L’analyse IA n’est pas encore configurée.',
        ),
      ),
    );
  });

  test('invalid response falls back to a friendly generic message', () async {
    final client = FakeHttpClient((request) async {
      return http.StreamedResponse(
        Stream.value(utf8.encode('not-json')),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = RecipeAiExtractionService(
      client: client,
      endpoint: 'https://example.test/analyze-recipe',
    );

    expect(
      () => service.extractRecipeFromImages([buildImagePayload('recipe.png')]),
      throwsA(
        isA<RecipeAiExtractionException>().having(
          (error) => error.userMessage,
          'userMessage',
          'L’analyse IA n’a pas pu aboutir. Tu peux réessayer ou utiliser l’analyse locale.',
        ),
      ),
    );
  });

  test('png images are sent as image/png', () async {
    late MediaType? contentType;
    final client = FakeHttpClient((request) async {
      final multipart = request as http.MultipartRequest;
      contentType = multipart.files.single.contentType;

      return http.StreamedResponse(
        Stream.value(
          utf8.encode(
            jsonEncode({
              'ingredients': [
                {'name': 'Lait'},
              ],
            }),
          ),
        ),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = RecipeAiExtractionService(
      client: client,
      endpoint: 'https://example.test/analyze-recipe',
    );

    await service.extractRecipeFromImages([buildImagePayload('recipe.png')]);
    expect(contentType?.mimeType, 'image/png');
  });

  test('jpg and jpeg images are sent as image/jpeg', () async {
    final seen = <String>[];
    final client = FakeHttpClient((request) async {
      final multipart = request as http.MultipartRequest;
      seen.addAll(
        multipart.files.map((file) => file.contentType.mimeType),
      );

      return http.StreamedResponse(
        Stream.value(
          utf8.encode(
            jsonEncode({
              'ingredients': [
                {'name': 'Lait'},
              ],
            }),
          ),
        ),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = RecipeAiExtractionService(
      client: client,
      endpoint: 'https://example.test/analyze-recipe',
    );

    await service.extractRecipeFromImages([
      buildImagePayload('recipe.jpg'),
      buildImagePayload('recipe.jpeg'),
    ]);

    expect(seen, ['image/jpeg', 'image/jpeg']);
  });

  test('webp images are sent as image/webp', () async {
    late MediaType? contentType;
    final client = FakeHttpClient((request) async {
      final multipart = request as http.MultipartRequest;
      contentType = multipart.files.single.contentType;

      return http.StreamedResponse(
        Stream.value(
          utf8.encode(
            jsonEncode({
              'ingredients': [
                {'name': 'Lait'},
              ],
            }),
          ),
        ),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = RecipeAiExtractionService(
      client: client,
      endpoint: 'https://example.test/analyze-recipe',
    );

    await service.extractRecipeFromImages([buildImagePayload('recipe.webp')]);
    expect(contentType?.mimeType, 'image/webp');
  });
}
