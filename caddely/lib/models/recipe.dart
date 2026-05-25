import 'dart:convert';

import 'recipe_ingredient.dart';

class Recipe {
  final String id;
  final String title;
  final int servings;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final String source;
  final String? imagePath;
  final List<String> imagePaths;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.title,
    required this.servings,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.ingredients,
    required this.steps,
    required this.source,
    String? imagePath,
    List<String>? imagePaths,
    required this.createdAt,
  })  : imagePath = imagePath ?? _firstPath(imagePaths),
        imagePaths = _normalizeImagePaths(imagePath, imagePaths);

  String? get coverImagePath => imagePaths.isEmpty ? imagePath : imagePaths.first;
  int get imageCount => imagePaths.length;
  bool get hasMultipleImages => imagePaths.length > 1;

  Recipe copyWith({
    String? id,
    String? title,
    int? servings,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    List<RecipeIngredient>? ingredients,
    List<String>? steps,
    String? source,
    String? imagePath,
    List<String>? imagePaths,
    bool clearImagePath = false,
    bool clearImagePaths = false,
    DateTime? createdAt,
  }) {
    final resolvedImagePath = clearImagePath ? null : (imagePath ?? this.imagePath);
    final resolvedImagePaths = clearImagePaths ? const <String>[] : (imagePaths ?? this.imagePaths);

    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      servings: servings ?? this.servings,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      source: source ?? this.source,
      imagePath: resolvedImagePath,
      imagePaths: resolvedImagePaths,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'servings': servings,
        'prepTimeMinutes': prepTimeMinutes,
        'cookTimeMinutes': cookTimeMinutes,
        'ingredients': ingredients.map((entry) => entry.toJson()).toList(),
        'steps': steps,
        'source': source,
        'imagePath': imagePath,
        'imagePaths': imagePaths,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final legacyImagePath = json['imagePath'] as String?;
    final parsedImagePaths = ((json['imagePaths'] as List<dynamic>?) ?? const [])
        .map((entry) => '$entry'.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();

    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      servings: json['servings'] as int? ?? 1,
      prepTimeMinutes: json['prepTimeMinutes'] as int? ?? 0,
      cookTimeMinutes: json['cookTimeMinutes'] as int? ?? 0,
      ingredients: ((json['ingredients'] as List<dynamic>?) ?? const [])
          .map((entry) => RecipeIngredient.fromJson(entry as Map<String, dynamic>))
          .toList(),
      steps: ((json['steps'] as List<dynamic>?) ?? const []).map((entry) => '$entry').toList(),
      source: json['source'] as String? ?? 'import',
      imagePath: legacyImagePath,
      imagePaths: parsedImagePaths,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static List<Recipe> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((entry) => Recipe.fromJson(entry as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<Recipe> recipes) {
    return jsonEncode(recipes.map((entry) => entry.toJson()).toList());
  }

  static List<String> _normalizeImagePaths(
    String? imagePath,
    List<String>? imagePaths,
  ) {
    final values = <String>[
      if (imagePath != null && imagePath.trim().isNotEmpty) imagePath.trim(),
      ...?imagePaths?.map((entry) => entry.trim()).where((entry) => entry.isNotEmpty),
    ];
    return values.toSet().toList(growable: false);
  }

  static String? _firstPath(List<String>? imagePaths) {
    if (imagePaths == null) {
      return null;
    }

    for (final path in imagePaths) {
      final trimmed = path.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return null;
  }
}
