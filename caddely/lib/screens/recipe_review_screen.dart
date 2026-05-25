import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/grocery_category.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../providers/grocery_provider.dart';
import '../providers/recipes_provider.dart';
import '../theme/app_theme.dart';
import '../utils/recipe_grocery_utils.dart';
import '../utils/recipe_ingredient_format_utils.dart';
import 'recipe_detail_screen.dart';

class RecipeReviewScreen extends StatefulWidget {
  final Recipe initialRecipe;

  const RecipeReviewScreen({
    super.key,
    required this.initialRecipe,
  });

  @override
  State<RecipeReviewScreen> createState() => _RecipeReviewScreenState();
}

class _RecipeReviewScreenState extends State<RecipeReviewScreen> {
  late Recipe _recipe = widget.initialRecipe;
  bool _isSaving = false;
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final hasSelectedIngredients =
        _recipe.ingredients.any((ingredient) => ingredient.isSelected);

    return Scaffold(
      appBar: AppBar(title: const Text('Verifier la recette')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Verifie les informations detectees avant d\'ajouter les ingredients.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.colorTextPrimary,
              ),
            ),
          ),
          if (_recipe.imageCount > 1)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.colorBorder),
              ),
              child: Text(
                'Recette detectee a partir de ${_recipe.imageCount} photos.',
                key: const Key('recipe-multi-image-hint'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.colorTextSecondary,
                ),
              ),
            ),
          _RecipeMetaCard(
            recipe: _recipe,
            onTitleChanged: (value) {
              if (value.trim().isEmpty) {
                return;
              }
              setState(() {
                _recipe = _recipe.copyWith(title: value.trim());
              });
            },
            onServingsChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed == null || parsed < 1) {
                return;
              }
              setState(() {
                _recipe = _recipe.copyWith(servings: parsed);
              });
            },
            onPrepTimeChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed == null || parsed < 0) {
                return;
              }
              setState(() {
                _recipe = _recipe.copyWith(prepTimeMinutes: parsed);
              });
            },
            onCookTimeChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed == null || parsed < 0) {
                return;
              }
              setState(() {
                _recipe = _recipe.copyWith(cookTimeMinutes: parsed);
              });
            },
          ),
          const SizedBox(height: 16),
          _IngredientSelectionCard(
            ingredients: _recipe.ingredients,
            onToggle: _toggleIngredient,
            onEdit: _editIngredient,
            onAdd: _addIngredient,
          ),
          const SizedBox(height: 16),
          _RecipeStepsCard(steps: _recipe.steps),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              key: const Key('save-recipe-button'),
              onPressed: _isSaving ? null : _saveRecipe,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sauvegarder la recette'),
            ),
            const SizedBox(height: 10),
            FilledButton(
              key: const Key('add-recipe-ingredients-button'),
              onPressed: _isAdding || !hasSelectedIngredients
                  ? null
                  : _addIngredientsToList,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _isAdding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ajouter les ingredients a ma liste'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleIngredient(int index, bool value) {
    final updated = List<RecipeIngredient>.from(_recipe.ingredients);
    updated[index] = updated[index].copyWith(isSelected: value);
    setState(() {
      _recipe = _recipe.copyWith(ingredients: updated);
    });
  }

  Future<void> _addIngredient() async {
    final draft = await showModalBottomSheet<_IngredientEditorResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _IngredientEditorSheet(),
    );

    if (!mounted || draft == null || draft.action == _IngredientEditorAction.delete) {
      return;
    }

    setState(() {
      _recipe = _recipe.copyWith(
        ingredients: [
          ..._recipe.ingredients,
          draft.ingredient,
        ],
      );
    });
  }

  Future<void> _editIngredient(int index) async {
    final ingredient = _recipe.ingredients[index];
    final result = await showModalBottomSheet<_IngredientEditorResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _IngredientEditorSheet(
        initialIngredient: ingredient,
        allowDelete: true,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final updated = List<RecipeIngredient>.from(_recipe.ingredients);
    switch (result.action) {
      case _IngredientEditorAction.save:
        updated[index] = result.ingredient;
        break;
      case _IngredientEditorAction.delete:
        updated.removeAt(index);
        break;
    }

    setState(() {
      _recipe = _recipe.copyWith(ingredients: updated);
    });
  }

  Future<void> _saveRecipe() async {
    setState(() => _isSaving = true);
    await context.read<RecipesProvider>().saveRecipe(_recipe);

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RecipeDetailScreen(recipeId: _recipe.id),
      ),
    );
  }

  Future<void> _addIngredientsToList() async {
    setState(() => _isAdding = true);

    final result = await addSelectedIngredientsToGrocery(
      grocery: context.read<GroceryProvider>(),
      ingredients: _recipe.ingredients,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isAdding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_resultLabel(result))),
    );
  }

  String _resultLabel(RecipeListAddResult result) {
    if (result.addedCount == 0 && result.duplicateCount > 0) {
      return 'Ces ingredients sont deja dans ta liste.';
    }

    if (result.duplicateCount > 0) {
      return '${result.addedCount} ingredient${result.addedCount > 1 ? 's' : ''} ajoute${result.addedCount > 1 ? 's' : ''}, ${result.duplicateCount} deja present${result.duplicateCount > 1 ? 's' : ''}.';
    }

    return '${result.addedCount} ingredient${result.addedCount > 1 ? 's' : ''} ajoute${result.addedCount > 1 ? 's' : ''} a la liste.';
  }
}

class _RecipeMetaCard extends StatelessWidget {
  final Recipe recipe;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onServingsChanged;
  final ValueChanged<String> onPrepTimeChanged;
  final ValueChanged<String> onCookTimeChanged;

  const _RecipeMetaCard({
    required this.recipe,
    required this.onTitleChanged,
    required this.onServingsChanged,
    required this.onPrepTimeChanged,
    required this.onCookTimeChanged,
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
          TextField(
            key: const Key('recipe-title-field'),
            controller: TextEditingController(text: recipe.title),
            onChanged: onTitleChanged,
            decoration: const InputDecoration(labelText: 'Titre'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('recipe-servings-field'),
                  controller: TextEditingController(text: '${recipe.servings}'),
                  keyboardType: TextInputType.number,
                  onChanged: onServingsChanged,
                  decoration: const InputDecoration(labelText: 'Portions'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const Key('recipe-prep-field'),
                  controller: TextEditingController(text: '${recipe.prepTimeMinutes}'),
                  keyboardType: TextInputType.number,
                  onChanged: onPrepTimeChanged,
                  decoration: const InputDecoration(labelText: 'Prepa (min)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const Key('recipe-cook-field'),
                  controller: TextEditingController(text: '${recipe.cookTimeMinutes}'),
                  keyboardType: TextInputType.number,
                  onChanged: onCookTimeChanged,
                  decoration: const InputDecoration(labelText: 'Cuisson (min)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IngredientSelectionCard extends StatelessWidget {
  final List<RecipeIngredient> ingredients;
  final void Function(int index, bool value) onToggle;
  final ValueChanged<int> onEdit;
  final VoidCallback onAdd;

  const _IngredientSelectionCard({
    required this.ingredients,
    required this.onToggle,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.colorBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ingredients detectes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.colorTextPrimary,
                    ),
                  ),
                ),
                TextButton.icon(
                  key: const Key('add-ingredient-button'),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter un ingredient'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (ingredients.isEmpty)
              const Text(
                'Aucun ingredient detecte.',
                style: TextStyle(color: AppTheme.colorTextSecondary),
              )
            else
              for (final entry in ingredients.asMap().entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: entry.value.isSelected,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            formatRecipeIngredientName(
                              entry.value.name,
                              quantity: entry.value.quantity,
                            ),
                          ),
                          subtitle: Text(
                            _subtitleFor(entry.value),
                            key: Key('ingredient-subtitle-${entry.key}'),
                          ),
                          onChanged: (value) => onToggle(entry.key, value ?? false),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              key: Key('edit-ingredient-${entry.key}'),
                              onPressed: () => onEdit(entry.key),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Modifier'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _subtitleFor(RecipeIngredient ingredient) {
    final details = <String>[];
    if (ingredient.quantityLabel.isNotEmpty) {
      details.add(ingredient.quantityLabel);
    }
    details.add(ingredient.category.label);
    return details.join(' - ');
  }
}

class _RecipeStepsCard extends StatelessWidget {
  final List<String> steps;

  const _RecipeStepsCard({required this.steps});

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
          const Text(
            'Etapes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.colorTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (steps.isEmpty)
            const Text(
              'Aucune etape detectee.',
              style: TextStyle(color: AppTheme.colorTextSecondary),
            )
          else
            for (final entry in steps.asMap().entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('${entry.key + 1}. ${entry.value}'),
              ),
        ],
      ),
    );
  }
}

class _IngredientEditorSheet extends StatefulWidget {
  final RecipeIngredient? initialIngredient;
  final bool allowDelete;

  const _IngredientEditorSheet({
    this.initialIngredient,
    this.allowDelete = false,
  });

  @override
  State<_IngredientEditorSheet> createState() => _IngredientEditorSheetState();
}

class _IngredientEditorSheetState extends State<_IngredientEditorSheet> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialIngredient?.name ?? '');
  late final TextEditingController _quantityController = TextEditingController(
    text: _initialQuantityText(widget.initialIngredient?.quantity),
  );
  late final TextEditingController _unitController =
      TextEditingController(text: widget.initialIngredient?.unit ?? '');
  late GroceryCategory _selectedCategory =
      widget.initialIngredient?.category ?? GroceryCategory.other;
  late bool _isSelected = widget.initialIngredient?.isSelected ?? true;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialIngredient == null
                    ? 'Ajouter un ingredient'
                    : 'Modifier l\'ingredient',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colorTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('ingredient-name-field'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('ingredient-quantity-field'),
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantite'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      key: const Key('ingredient-unit-field'),
                      controller: _unitController,
                      decoration: const InputDecoration(labelText: 'Unite'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GroceryCategory>(
                key: const Key('ingredient-category-field'),
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Categorie'),
                items: GroceryCategory.values
                    .map(
                      (category) => DropdownMenuItem<GroceryCategory>(
                        value: category,
                        child: Text(category.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                key: const Key('ingredient-selected-switch'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Ajouter cet ingredient a la liste'),
                value: _isSelected,
                onChanged: (value) {
                  setState(() {
                    _isSelected = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.allowDelete)
                    TextButton(
                      key: const Key('delete-ingredient-button'),
                      onPressed: () {
                        Navigator.of(context).pop(
                          const _IngredientEditorResult.delete(),
                        );
                      },
                      child: const Text('Supprimer'),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  FilledButton(
                    key: const Key('save-ingredient-button'),
                    onPressed: _nameController.text.trim().isEmpty ? null : _save,
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final quantity = _parseQuantity(_quantityController.text);
    Navigator.of(context).pop(
      _IngredientEditorResult.save(
        RecipeIngredient(
          name: name,
          quantity: quantity,
          unit: _unitController.text.trim(),
          category: _selectedCategory,
          isSelected: _isSelected,
        ),
      ),
    );
  }

  double? _parseQuantity(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  static String _initialQuantityText(double? quantity) {
    if (quantity == null) {
      return '';
    }
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toString().replaceAll('.', ',');
  }
}

enum _IngredientEditorAction {
  save,
  delete,
}

class _IngredientEditorResult {
  final _IngredientEditorAction action;
  final RecipeIngredient ingredient;

  const _IngredientEditorResult.save(this.ingredient)
      : action = _IngredientEditorAction.save;

  const _IngredientEditorResult.delete()
      : action = _IngredientEditorAction.delete,
        ingredient = const RecipeIngredient(name: '');
}
