import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';

import '../config/recipe_ai_config.dart';
import '../models/grocery_category.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';

class RecipeAiExtractionException implements Exception {
  final String userMessage;

  const RecipeAiExtractionException(this.userMessage);
}

class RecipeAiImagePayload {
  final String fileName;
  final Uint8List bytes;
  final String? path;

  const RecipeAiImagePayload({
    required this.fileName,
    required this.bytes,
    this.path,
  });
}

class RecipeAiExtractionService {
  final http.Client _client;
  final Uuid _uuid;
  final String _endpoint;

  RecipeAiExtractionService({
    http.Client? client,
    Uuid? uuid,
    String? endpoint,
  })  : _client = client ?? http.Client(),
        _uuid = uuid ?? const Uuid(),
        _endpoint = endpoint ?? recipeAiEndpoint;

  bool get isConfigured => _endpoint.trim().isNotEmpty;

  Future<Recipe> extractRecipeFromImages(List<RecipeAiImagePayload> images) async {
    if (!isConfigured) {
      throw const RecipeAiExtractionException(
        'L’analyse IA n’est pas encore configurée.',
      );
    }

    if (images.isEmpty) {
      throw const RecipeAiExtractionException(
        'Ajoute au moins une photo avant de lancer l’analyse IA.',
      );
    }

    final uri = Uri.tryParse(_endpoint);
    if (uri == null) {
      throw const RecipeAiExtractionException(
        'L’analyse IA n’est pas encore configurée.',
      );
    }

    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json';

    for (final image in images) {
      final mimeType = _guessMimeType(image.path ?? image.fileName);
      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          image.bytes,
          filename: image.fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );
    }

    http.Response response;
    try {
      final streamed = await _client.send(request);
      response = await http.Response.fromStream(streamed);
    } catch (_) {
      throw const RecipeAiExtractionException(
        'Impossible de contacter le service IA pour le moment.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (kDebugMode) {
        debugPrint(
          'Recipe AI backend error: status=${response.statusCode} body=${response.body}',
        );
      }
      throw RecipeAiExtractionException(
        _errorMessageFromResponse(response.statusCode, response.body),
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const RecipeAiExtractionException(
        'L’analyse IA n’a pas pu aboutir. Tu peux réessayer ou utiliser l’analyse locale.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const RecipeAiExtractionException(
        'L’analyse IA n’a pas pu aboutir. Tu peux réessayer ou utiliser l’analyse locale.',
      );
    }

    final recipe = recipeFromJson(
      decoded,
      imagePaths: images
          .map((image) => image.path?.trim() ?? '')
          .where((path) => path.isNotEmpty)
          .toList(),
    );

    if (recipe.ingredients.isEmpty) {
      throw const RecipeAiExtractionException(
        'L’analyse IA n’a pas pu aboutir. Tu peux réessayer ou utiliser l’analyse locale.',
      );
    }

    return recipe;
  }

  Recipe recipeFromJson(
    Map<String, dynamic> json, {
    List<String>? imagePaths,
  }) {
    final ingredients = _parseIngredients(json['ingredients']);
    final steps = _parseSteps(json['steps']);

    return Recipe(
      id: _uuid.v4(),
      title: _stringOrFallback(json['title'], fallback: 'Recette importee'),
      servings: _parseInt(json['servings'], fallback: 1),
      prepTimeMinutes: _parseInt(json['prepTimeMinutes']),
      cookTimeMinutes: _parseInt(json['cookTimeMinutes']),
      ingredients: ingredients,
      steps: steps,
      source: _stringOrFallback(json['source'], fallback: 'gemini_vision'),
      imagePaths: imagePaths,
      createdAt: DateTime.now(),
    );
  }

  List<RecipeIngredient> _parseIngredients(dynamic rawIngredients) {
    if (rawIngredients is! List) {
      return const [];
    }

    final parsed = <RecipeIngredient>[];
    for (final entry in rawIngredients) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }

      final name = _stringOrFallback(entry['name']).trim();
      if (name.isEmpty) {
        continue;
      }

      parsed.add(
        RecipeIngredient(
          name: name,
          quantity: _parseDouble(entry['quantity']),
          unit: _stringOrFallback(entry['unit']),
          category: _categoryFromAi(entry['category']),
          isSelected: entry['isSelected'] is bool ? entry['isSelected'] as bool : true,
        ),
      );
    }

    return parsed;
  }

  List<String> _parseSteps(dynamic rawSteps) {
    if (rawSteps is! List) {
      return const [];
    }

    return rawSteps
        .map((entry) => _stringOrFallback(entry))
        .where((entry) => entry.trim().isNotEmpty)
        .toList();
  }

  GroceryCategory _categoryFromAi(dynamic value) {
    final normalized = _normalizeToken(_stringOrFallback(value));
    switch (normalized) {
      case 'fruitslegumes':
      case 'fruitsetlegumes':
      case 'fruitsandvegetables':
      case 'fruitsvegetables':
        return GroceryCategory.fruitsAndVegetables;
      case 'frais':
      case 'fresh':
        return GroceryCategory.fresh;
      case 'epicerie':
      case 'grocery':
        return GroceryCategory.grocery;
      case 'boissons':
      case 'boisson':
      case 'drinks':
        return GroceryCategory.drinks;
      case 'hygiene':
        return GroceryCategory.hygiene;
      case 'maison':
      case 'home':
        return GroceryCategory.home;
      case 'surgeles':
      case 'frozen':
        return GroceryCategory.frozen;
      default:
        return GroceryCategory.other;
    }
  }

  String _errorMessageFromResponse(int statusCode, String body) {
    final normalizedBody = _normalizeToken(body);
    if (_looksLikeHighDemand(statusCode, normalizedBody)) {
      return 'Le service IA est temporairement occupé. Réessaie dans quelques minutes.';
    }

    if (_looksLikeUnsupportedImageFormat(statusCode, normalizedBody)) {
      return 'Format d’image non supporté. Essaie avec une image PNG, JPG ou WEBP.';
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final combined = [
          _stringOrFallback(decoded['error']),
          _stringOrFallback(decoded['message']),
          _stringOrFallback(decoded['status']),
        ].where((entry) => entry.isNotEmpty).join(' ');
        final normalized = _normalizeToken(combined);

        if (_looksLikeHighDemand(statusCode, normalized)) {
          return 'Le service IA est temporairement occupé. Réessaie dans quelques minutes.';
        }

        if (_looksLikeUnsupportedImageFormat(statusCode, normalized)) {
          return 'Format d’image non supporté. Essaie avec une image PNG, JPG ou WEBP.';
        }
      }
    } catch (_) {
      // Ignore invalid payload and use fallback below.
    }

    if (statusCode >= 500) {
      return 'Le service IA est temporairement indisponible. Réessaie un peu plus tard ou utilise l’analyse locale.';
    }

    return 'L’analyse IA n’a pas pu aboutir. Tu peux réessayer ou utiliser l’analyse locale.';
  }

  bool _looksLikeHighDemand(int statusCode, String normalizedText) {
    return statusCode == 503 ||
        normalizedText.contains('unavailable') ||
        normalizedText.contains('highdemand') ||
        normalizedText.contains('currentlyexperiencinghighdemand');
  }

  bool _looksLikeUnsupportedImageFormat(int statusCode, String normalizedText) {
    if (statusCode != 400 && statusCode != 415) {
      return normalizedText.contains('unsupportedmimetype') ||
          normalizedText.contains('applicationoctetstream') ||
          normalizedText.contains('formatdimagenonsupporte');
    }

    return normalizedText.contains('unsupportedmimetype') ||
        normalizedText.contains('applicationoctetstream') ||
        normalizedText.contains('formatdimagenonsupporte');
  }

  String _stringOrFallback(dynamic value, {String fallback = ''}) {
    final text = '$value'.trim();
    if (text.isEmpty || text == 'null') {
      return fallback;
    }
    return text;
  }

  int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is num) {
      return value.round();
    }

    final parsed = int.tryParse(_stringOrFallback(value));
    return parsed ?? fallback;
  }

  double? _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    final normalized = _stringOrFallback(value).replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }

  String _guessMimeType(String source) {
    final normalized = source.trim().toLowerCase();
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'application/octet-stream';
  }

  String _normalizeToken(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', 'et')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('œ', 'oe')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}
