import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/recipe_extraction_service.dart';
import '../theme/app_theme.dart';
import 'recipe_review_screen.dart';

class RecipeOcrTextReviewScreen extends StatefulWidget {
  final String? initialText;
  final List<String>? imagePaths;
  final RecipeExtractionService? extractionService;

  const RecipeOcrTextReviewScreen({
    super.key,
    this.initialText,
    this.imagePaths,
    this.extractionService,
  });

  @override
  State<RecipeOcrTextReviewScreen> createState() => _RecipeOcrTextReviewScreenState();
}

class _RecipeOcrTextReviewScreenState extends State<RecipeOcrTextReviewScreen> {
  late final RecipeExtractionService _extractionService;
  late final TextEditingController _textController;
  String? _validationError;

  bool get _isPasteMode {
    final text = widget.initialText;
    return text == null || text.trim().isEmpty;
  }

  @override
  void initState() {
    super.initState();
    _extractionService = widget.extractionService ?? RecipeExtractionService();
    _textController = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isPasteMode ? 'Saisir une recette' : 'Texte détecté'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Text(
            _isPasteMode ? 'Coller ou saisir le texte' : 'Texte OCR détecté',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.colorTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Corrige rapidement le texte détecté si besoin. Caddely l\'utilisera ensuite pour générer une recette propre.',
            style: TextStyle(fontSize: 13, color: AppTheme.colorTextSecondary),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.colorBorder),
            ),
            child: TextField(
              key: const Key('ocr-text-field'),
              controller: _textController,
              maxLines: null,
              minLines: 12,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.colorTextPrimary,
                height: 1.6,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
                hintText: 'Ingrédients, étapes, portions...',
                hintStyle: TextStyle(
                  color: AppTheme.colorTextSecondary,
                  fontSize: 14,
                ),
              ),
              onChanged: (_) {
                if (_validationError != null) {
                  setState(() => _validationError = null);
                }
              },
            ),
          ),
          if (_validationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _validationError!,
              key: const Key('ocr-text-empty-error'),
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF0284C7)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Astuce : colle la liste des ingrédients et les étapes. Caddely détecte automatiquement la structure.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              key: const Key('transform-to-recipe-button'),
              onPressed: _transformToRecipe,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Transformer en recette'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('ocr-use-demo-recipe'),
              onPressed: _useDemoRecipe,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Utiliser une recette de démonstration'),
            ),
          ],
        ),
      ),
    );
  }

  void _transformToRecipe() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _validationError =
            'Le texte est vide. Saisis ou colle une recette avant de continuer.';
      });
      return;
    }

    final paths = widget.imagePaths;
    final recipe = _extractionService.extractRecipeFromText(
      text,
      imagePath: (paths != null && paths.isNotEmpty) ? paths.first : null,
      imagePaths: paths,
    );
    _openReview(recipe);
  }

  void _useDemoRecipe() {
    final paths = widget.imagePaths;
    final recipe = _extractionService.buildDemoRecipe(
      imagePath: (paths != null && paths.isNotEmpty) ? paths.first : null,
      imagePaths: paths,
    );
    _openReview(recipe);
  }

  Future<void> _openReview(Recipe recipe) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeReviewScreen(initialRecipe: recipe),
      ),
    );
  }
}
