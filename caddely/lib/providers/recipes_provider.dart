import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../services/storage_service.dart';

class RecipesProvider extends ChangeNotifier {
  final StorageService _storage;

  List<Recipe> _recipes = [];
  bool _isLoading = true;

  RecipesProvider(this._storage);

  bool get isLoading => _isLoading;
  List<Recipe> get recipes => List.unmodifiable(_recipes);

  Future<void> load() async {
    _recipes = await _storage.loadRecipes()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveRecipe(Recipe recipe) async {
    final index = _recipes.indexWhere((entry) => entry.id == recipe.id);
    if (index == -1) {
      _recipes.insert(0, recipe);
    } else {
      _recipes[index] = recipe;
    }
    _recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _persist();
  }

  Recipe? recipeById(String id) {
    for (final recipe in _recipes) {
      if (recipe.id == id) {
        return recipe;
      }
    }
    return null;
  }

  Future<void> _persist() async {
    await _storage.saveRecipes(_recipes);
    notifyListeners();
  }
}
