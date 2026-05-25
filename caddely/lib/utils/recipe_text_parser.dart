import 'package:uuid/uuid.dart';

import '../models/grocery_category.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';

class RecipeTextParser {
  final Uuid _uuid;

  RecipeTextParser({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Recipe parse(
    String rawText, {
    String? imagePath,
    List<String>? imagePaths,
    DateTime? createdAt,
    String source = 'import_image_ocr',
  }) {
    final lines = rawText
        .replaceAll('\r', '')
        .split('\n')
        .map(_cleanLine)
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return _buildFallbackRecipe(
        imagePath: imagePath,
        imagePaths: imagePaths,
        createdAt: createdAt,
        source: source,
      );
    }

    final metadata = _extractMetadata(lines);
    final title = _extractTitle(lines);
    final normalizedTitle = _normalizeForMatch(title);
    final ingredients = <RecipeIngredient>[];
    final steps = <String>[];
    final ambiguous = <String>[];

    var currentSection = _RecipeSection.none;
    var skippedTitle = false;

    for (final line in lines) {
      if (_isMultiImageSeparator(line) || _isNoiseLine(line)) {
        continue;
      }

      if (!skippedTitle &&
          normalizedTitle != 'recette importee' &&
          _normalizeForMatch(line) == normalizedTitle) {
        skippedTitle = true;
        continue;
      }

      final heading = _detectHeading(line);
      if (heading != null) {
        currentSection = heading;
        continue;
      }

      if (_looksLikeMetadata(line)) {
        continue;
      }

      final ingredient = _parseIngredient(line);
      final looksLikeIngredient = ingredient != null;
      final looksLikeStep = _looksLikeStep(line);

      if (currentSection == _RecipeSection.ingredients) {
        if (looksLikeIngredient && !looksLikeStep) {
          ingredients.add(ingredient);
          continue;
        }

        if (looksLikeStep) {
          currentSection = _RecipeSection.steps;
          steps.add(_normalizeStep(line));
          continue;
        }

        ambiguous.add(line);
        continue;
      }

      if (currentSection == _RecipeSection.steps) {
        if (looksLikeIngredient && !looksLikeStep) {
          ingredients.add(ingredient);
        } else {
          steps.add(_normalizeStep(line));
        }
        continue;
      }

      if (looksLikeIngredient && !looksLikeStep) {
        ingredients.add(ingredient);
        continue;
      }

      if (looksLikeStep) {
        steps.add(_normalizeStep(line));
        continue;
      }

      ambiguous.add(line);
    }

    if (ingredients.isEmpty) {
      final rescuedIngredients = <RecipeIngredient>[];
      final remaining = <String>[];
      for (final line in ambiguous) {
        final ingredient = _parseIngredient(line);
        if (ingredient != null && !_looksLikeStep(line)) {
          rescuedIngredients.add(ingredient);
        } else {
          remaining.add(line);
        }
      }
      ingredients.addAll(rescuedIngredients);
      ambiguous
        ..clear()
        ..addAll(remaining);
    }

    final normalizedSteps = <String>[
      ...steps.where((entry) => entry.trim().isNotEmpty),
      ...ambiguous
          .where((entry) => !_isNoiseLine(entry))
          .map(_normalizeStep)
          .where((entry) => entry.isNotEmpty),
    ];

    if (ingredients.isEmpty && normalizedSteps.isEmpty) {
      return _buildFallbackRecipe(
        title: title,
        imagePath: imagePath,
        imagePaths: imagePaths,
        createdAt: createdAt,
        source: source,
      );
    }

    return Recipe(
      id: _uuid.v4(),
      title: title,
      servings: metadata.servings,
      prepTimeMinutes: metadata.prepTimeMinutes,
      cookTimeMinutes: metadata.cookTimeMinutes,
      ingredients: ingredients,
      steps: normalizedSteps.isEmpty
          ? const ['Recette a verifier dans l\'ecran de revue.']
          : normalizedSteps,
      source: source,
      imagePath: imagePath,
      imagePaths: imagePaths,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  Recipe _buildFallbackRecipe({
    String title = 'Recette importee',
    String? imagePath,
    List<String>? imagePaths,
    DateTime? createdAt,
    String source = 'import_image_ocr',
  }) {
    return Recipe(
      id: _uuid.v4(),
      title: title,
      servings: 1,
      prepTimeMinutes: 0,
      cookTimeMinutes: 0,
      ingredients: const [],
      steps: const ['Recette a verifier dans l\'ecran de revue.'],
      source: source,
      imagePath: imagePath,
      imagePaths: imagePaths,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  _RecipeMetadata _extractMetadata(List<String> lines) {
    final text = lines.join('\n');
    return _RecipeMetadata(
      servings: _extractServings(text) ?? 1,
      prepTimeMinutes: _extractDuration(text, const ['preparation', 'prepa', 'prep']) ?? 0,
      cookTimeMinutes: _extractDuration(text, const ['cuisson', 'cooking']) ?? 0,
    );
  }

  String _extractTitle(List<String> lines) {
    final firstHeadingIndex = lines.indexWhere((line) => _detectHeading(line) != null);
    final candidates = firstHeadingIndex == -1 ? lines : lines.take(firstHeadingIndex);

    for (final line in candidates) {
      if (_isNoiseLine(line) || _looksLikeMetadata(line) || _detectHeading(line) != null) {
        continue;
      }

      final normalized = _normalizeForMatch(line);
      final startsWithStepNumber =
          RegExp(r'^(etape\s*\d+|\d+[.)-])', caseSensitive: false).hasMatch(normalized);
      final startsWithQuantity =
          RegExp(r'^(\d+\s*/\s*\d+|\d+(?:[.,]\d+)?)(\s|$)').hasMatch(normalized);
      if (startsWithStepNumber || startsWithQuantity) {
        continue;
      }

      return line;
    }

    return 'Recette importee';
  }

  int? _extractServings(String text) {
    final patterns = [
      RegExp(r'pour\s+(\d+)\s*(personnes?|pers\.?|portions?)', caseSensitive: false),
      RegExp(r'(\d+)\s*(personnes?|pers\.?|portions?)', caseSensitive: false),
      RegExp(r'portions?\s*[:\-]?\s*(\d+)', caseSensitive: false),
      RegExp(r'serves?\s*[:\-]?\s*(\d+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      final value = int.tryParse(match?.group(1) ?? '');
      if (value != null && value > 0) {
        return value;
      }
    }

    return null;
  }

  int? _extractDuration(String text, List<String> keywords) {
    for (final keyword in keywords) {
      final pattern = RegExp(
        '$keyword\\s*[:\\-]?\\s*(\\d+)\\s*(min|mn|minutes?)',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(text);
      final value = int.tryParse(match?.group(1) ?? '');
      if (value != null && value >= 0) {
        return value;
      }
    }

    return null;
  }

  _RecipeSection? _detectHeading(String line) {
    final lower = _normalizeForMatch(line);

    const ingredientHeadings = [
      'ingredients',
      'il vous faut',
      'il te faut',
      'pour la recette',
      'liste des ingredients',
      'cote ingredients',
    ];

    const exactStepHeadings = [
      'preparation',
      'etapes',
      'recette',
      'instructions',
      'realisation',
      'methode',
      'la preparation',
      'preparation de la recette',
    ];

    const prefixStepHeadings = [
      'preparation',
      'etapes',
      'instructions',
      'realisation',
      'methode',
      'la preparation',
      'preparation de la recette',
    ];

    if (ingredientHeadings.any((entry) => lower == entry || lower.startsWith('$entry '))) {
      return _RecipeSection.ingredients;
    }

    if (exactStepHeadings.contains(lower) ||
        prefixStepHeadings.any((entry) => lower.startsWith('$entry '))) {
      return _RecipeSection.steps;
    }

    return null;
  }

  bool _looksLikeMetadata(String line) {
    final lower = _normalizeForMatch(line);

    final metadataPatterns = [
      RegExp(r'^pour\s+\d+\s*(personnes?|pers\.?|portions?)$'),
      RegExp(r'^\d+\s*(personnes?|pers\.?|portions?)$'),
      RegExp(r'^portions?\s*[:\-]?\s*\d+$'),
      RegExp(r'^preparation\s*[:\-]?\s*\d+\s*(min|mn|minutes?)$'),
      RegExp(r'^prepa\s*[:\-]?\s*\d+\s*(min|mn|minutes?)$'),
      RegExp(r'^cuisson\s*[:\-]?\s*\d+\s*(min|mn|minutes?)$'),
      RegExp(r'^temps total\s*[:\-]?\s*\d+\s*(min|mn|minutes?)$'),
    ];

    return metadataPatterns.any((pattern) => pattern.hasMatch(lower));
  }

  bool _isNoiseLine(String line) {
    final lower = _normalizeForMatch(line);

    const bannedFragments = [
      'abonnez-vous',
      'abonne toi',
      'partager',
      'imprimer',
      'voir aussi',
      'newsletter',
      'sponsorise',
      'sponsorisee',
      'ingredients sponsorises',
      'valeurs nutritionnelles',
      'calories',
      'avis',
      'note',
      'difficulte',
      'budget',
      'tres facile',
      'bon marche',
      'commentaire',
      'publicite',
    ];

    if (bannedFragments.any(lower.contains)) {
      return true;
    }

    return _looksLikeMetadata(line) && lower.startsWith('temps total');
  }

  bool _isMultiImageSeparator(String line) {
    final lower = _normalizeForMatch(line);
    return lower == '---' ||
        lower == '--' ||
        lower == 'image 1' ||
        lower == 'image 2' ||
        lower == 'image 3' ||
        lower.startsWith('photo ') ||
        lower.startsWith('page ');
  }

  RecipeIngredient? _parseIngredient(String line) {
    final normalized = _stripBullet(line);
    if (normalized.isEmpty || _detectHeading(normalized) == _RecipeSection.steps) {
      return null;
    }

    final quantityMatch = RegExp(
      r"^(?<quantity>\d+\s*/\s*\d+|\d+(?:[.,]\d+)?)\s*(?<unit>g|kg|ml|cl|l|filets?|tranches?|cuilleres?|c\.?\s*a\.?\s*soupe|c\.?\s*a\.?\s*cafe|pincees?|sachets?|boites?|pots?|verres?)?\s*(?:de\s+|d')?(?<name>.+)$",
      caseSensitive: false,
    ).firstMatch(normalized);

    if (quantityMatch != null) {
      final quantity = _parseQuantity(quantityMatch.namedGroup('quantity'));
      final rawUnit = (quantityMatch.namedGroup('unit') ?? '').trim();
      final unit = _normalizeUnit(rawUnit);
      final name = _normalizeIngredientName(quantityMatch.namedGroup('name') ?? '');
      if (name.isEmpty) {
        return null;
      }

      return RecipeIngredient(
        name: name,
        quantity: quantity,
        unit: unit,
        category: _guessCategory(name),
      );
    }

    if (!_looksLikeIngredient(normalized)) {
      return null;
    }

    final name = _normalizeIngredientName(normalized);
    if (name.isEmpty) {
      return null;
    }

    return RecipeIngredient(
      name: name,
      category: _guessCategory(name),
    );
  }

  bool _looksLikeIngredient(String line) {
    final lower = _normalizeForMatch(_stripBullet(line));
    if (lower.isEmpty || _isNoiseLine(lower)) {
      return false;
    }

    if (_looksLikeStep(lower)) {
      return false;
    }

    final hasQuantity =
        RegExp(r'(^|\s)(\d+\s*/\s*\d+|\d+(?:[.,]\d+)?)(\s|$)').hasMatch(lower);
    final hasUnit = RegExp(
      r'(^|\s)(g|kg|ml|cl|l|filets?|tranches?|cuilleres?|c\.?\s*a\.?\s*soupe|c\.?\s*a\.?\s*cafe|pincees?|sachets?|boites?|pots?|verres?)(\s|$)',
      caseSensitive: false,
    ).hasMatch(lower);

    const shortIngredients = [
      'sel',
      'poivre',
      'huile',
      'huile d olive',
      "huile d'olive",
      'beurre',
      'farine',
      'sucre',
      'oeufs',
      'oeuf',
      'lait',
      'riz',
      'pates',
    ];

    if ((hasQuantity || hasUnit) && !_containsActionVerb(lower)) {
      return true;
    }

    if (shortIngredients.contains(lower)) {
      return true;
    }

    const ingredientFragments = [
      'huile',
      'farine',
      'sucre',
      'beurre',
      'lait',
      'oeuf',
      'oeufs',
    ];
    if (ingredientFragments.any(lower.contains) && lower.split(' ').length <= 3) {
      return true;
    }

    return false;
  }

  bool _looksLikeStep(String line) {
    final normalized = _normalizeForMatch(_stripBullet(line));
    if (normalized.isEmpty || _isNoiseLine(normalized)) {
      return false;
    }

    final startsWithQuantity =
        RegExp(r'^(\d+\s*/\s*\d+|\d+(?:[.,]\d+)?)(\s|$)').hasMatch(normalized);
    if (startsWithQuantity && !_containsActionVerb(normalized)) {
      return false;
    }

    final startsWithStepNumber =
        RegExp(r'^(etape\s*\d+|\d+[.)-])', caseSensitive: false).hasMatch(normalized);
    if (startsWithStepNumber) {
      return true;
    }

    if (_containsActionVerb(normalized)) {
      return true;
    }

    return normalized.split(' ').length >= 6;
  }

  bool _containsActionVerb(String text) {
    const verbs = [
      'faire',
      'ajouter',
      'melanger',
      'cuire',
      'couper',
      'verser',
      'laisser',
      'servir',
      'prechauffer',
      'enfourner',
      'egoutter',
      'incorporer',
      'reserver',
      'fouetter',
      'emincer',
      'revenir',
      'chauffer',
      'mixer',
    ];

    return verbs.any(
      (verb) => RegExp('(^|\\s)$verb(\\s|${r'$'})', caseSensitive: false).hasMatch(text),
    );
  }

  double? _parseQuantity(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final value = raw.trim().replaceAll(',', '.');
    if (value == '1/4') {
      return 0.25;
    }
    if (value == '1/2') {
      return 0.5;
    }
    if (value == '3/4') {
      return 0.75;
    }
    if (value.contains('/')) {
      final parts = value.split('/');
      if (parts.length == 2) {
        final numerator = double.tryParse(parts.first.trim());
        final denominator = double.tryParse(parts.last.trim());
        if (numerator != null && denominator != null && denominator != 0) {
          return numerator / denominator;
        }
      }
    }

    return double.tryParse(value);
  }

  String _normalizeUnit(String value) {
    final normalized = _normalizeForMatch(value);
    switch (normalized) {
      case 'cuillere':
      case 'cuilleres':
      case 'c a soupe':
        return 'c. a soupe';
      case 'c a cafe':
        return 'c. a cafe';
      default:
        return value.trim();
    }
  }

  String _normalizeIngredientName(String value) {
    var cleaned = _stripBullet(value).trim();
    cleaned = cleaned.replaceFirst(
      RegExp(r"^(de|du|des|d')\s+", caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceFirst(
      RegExp(r'^(le|la|les)\s+', caseSensitive: false),
      '',
    );
    if (cleaned.isEmpty) {
      return '';
    }

    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  String _normalizeStep(String value) {
    return _stripBullet(value)
        .replaceFirst(
          RegExp(r'^(etape\s*\d+|\d+[.)-]?)\s*', caseSensitive: false),
          '',
        )
        .trim();
  }

  String _stripBullet(String line) {
    return line.replaceFirst(RegExp(r'^[-*•]\s*'), '').trim();
  }

  String _cleanLine(String line) {
    return line
        .replaceAll('\t', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeForMatch(String line) {
    return line
        .toLowerCase()
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('á', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('œ', 'oe')
        .replaceAll('’', '\'')
        .replaceAll(RegExp("[^a-z0-9./' -]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  GroceryCategory _guessCategory(String name) {
    final lower = _normalizeForMatch(name);

    const fruits = ['oignon', 'tomate', 'pomme', 'carotte', 'salade', 'citron'];
    const fresh = [
      'poulet',
      'creme',
      'parmesan',
      'yaourt',
      'beurre',
      'oeuf',
      'oeufs',
      'fromage',
    ];
    const grocery = [
      'pates',
      'riz',
      'farine',
      'sel',
      'poivre',
      'huile',
      'sucre',
      'sauce',
    ];
    const drinks = ['cafe', 'the', 'jus', 'lait'];

    if (fruits.any(lower.contains)) {
      return GroceryCategory.fruitsAndVegetables;
    }
    if (fresh.any(lower.contains)) {
      return GroceryCategory.fresh;
    }
    if (drinks.any(lower.contains)) {
      return GroceryCategory.drinks;
    }
    if (grocery.any(lower.contains)) {
      return GroceryCategory.grocery;
    }

    return GroceryCategory.other;
  }
}

enum _RecipeSection {
  none,
  ingredients,
  steps,
}

class _RecipeMetadata {
  final int servings;
  final int prepTimeMinutes;
  final int cookTimeMinutes;

  const _RecipeMetadata({
    required this.servings,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
  });
}
