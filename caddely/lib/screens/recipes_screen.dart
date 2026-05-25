import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/recipes_provider.dart';
import '../theme/app_theme.dart';
import 'recipe_detail_screen.dart';
import 'recipe_import_screen.dart';
import 'recipe_ocr_text_review_screen.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipesProvider = context.watch<RecipesProvider>();
    final recipes = recipesProvider.recipes;

    return Scaffold(
      appBar: AppBar(title: const Text('Recettes')),
      body: recipesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : recipes.isEmpty
              ? _RecipesEmptyState(
                  onImport: () => _openImport(context),
                  onPasteText: () => _openPasteText(context),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('paste-recipe-text'),
                          onPressed: () => _openPasteText(context),
                          icon: const Icon(Icons.content_paste_outlined),
                          label: const Text('Coller le texte'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: () => _openImport(context),
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Photo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (final recipe in recipes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RecipeListCard(
                          title: recipe.title,
                          subtitle:
                              '${recipe.servings} portions • ${recipe.ingredients.length} ingr\u00E9dients',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
      floatingActionButton: recipes.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openImport(context),
              icon: const Icon(Icons.add),
              label: const Text('Importer'),
            ),
    );
  }

  Future<void> _openImport(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const RecipeImportScreen(),
      ),
    );
  }

  Future<void> _openPasteText(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const RecipeOcrTextReviewScreen(),
      ),
    );
  }
}

class _RecipesEmptyState extends StatelessWidget {
  final VoidCallback onImport;
  final VoidCallback onPasteText;

  const _RecipesEmptyState({
    required this.onImport,
    required this.onPasteText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucune recette enregistr\u00E9e',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Importe une photo ou un screenshot de recette pour la transformer en fiche propre.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onImport,
              child: const Text('Importer une recette'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('paste-recipe-text-empty'),
              onPressed: onPasteText,
              icon: const Icon(Icons.content_paste_outlined),
              label: const Text('Coller le texte d\'une recette'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RecipeListCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.colorBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.restaurant_menu_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colorTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.colorTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.colorTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
