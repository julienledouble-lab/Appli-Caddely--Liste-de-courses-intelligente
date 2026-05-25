import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe_ingredient.dart';
import '../providers/grocery_provider.dart';
import '../providers/recipes_provider.dart';
import '../theme/app_theme.dart';
import '../utils/recipe_grocery_utils.dart';
import '../utils/recipe_ingredient_format_utils.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final recipe = context.watch<RecipesProvider>().recipeById(widget.recipeId);

    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recette')),
        body: const Center(
          child: Text('Recette introuvable.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(recipe.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(label: '${recipe.servings} portions'),
              _MetaPill(label: 'Pr\u00E9paration ${recipe.prepTimeMinutes} min'),
              _MetaPill(label: 'Cuisson ${recipe.cookTimeMinutes} min'),
            ],
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Ingr\u00E9dients',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: recipe.ingredients
                  .map(
                    (ingredient) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        formatRecipeIngredientLabel(
                          name: ingredient.name,
                          quantity: ingredient.quantity,
                          unit: ingredient.unit,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '\u00C9tapes',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: recipe.steps
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text('${entry.key + 1}. ${entry.value}'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: _isAdding
              ? null
              : () => _addIngredientsToList(context, recipe.ingredients),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: _isAdding
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ajouter les ingr\u00E9dients \u00E0 ma liste'),
        ),
      ),
    );
  }

  Future<void> _addIngredientsToList(
    BuildContext context,
    List<RecipeIngredient> ingredients,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final grocery = context.read<GroceryProvider>();

    setState(() => _isAdding = true);
    final result = await addSelectedIngredientsToGrocery(
      grocery: grocery,
      ingredients: ingredients,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isAdding = false);
    messenger.showSnackBar(
      SnackBar(content: Text(_resultLabel(result))),
    );
  }

  String _resultLabel(RecipeListAddResult result) {
    if (result.addedCount == 0 && result.duplicateCount > 0) {
      return 'Ces ingr\u00E9dients sont d\u00E9j\u00E0 dans ta liste.';
    }

    if (result.duplicateCount > 0) {
      return '${result.addedCount} ingr\u00E9dient${result.addedCount > 1 ? 's' : ''} ajout\u00E9${result.addedCount > 1 ? 's' : ''}, ${result.duplicateCount} d\u00E9j\u00E0 pr\u00E9sent${result.duplicateCount > 1 ? 's' : ''}.';
    }

    return '${result.addedCount} ingr\u00E9dient${result.addedCount > 1 ? 's' : ''} ajout\u00E9${result.addedCount > 1 ? 's' : ''} \u00E0 la liste.';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.colorTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;

  const _MetaPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.colorTextSecondary,
        ),
      ),
    );
  }
}
